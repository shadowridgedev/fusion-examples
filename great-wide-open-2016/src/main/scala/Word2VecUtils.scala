import org.apache.spark.mllib.clustering._
import org.apache.spark.mllib.feature.Word2VecModel
import org.apache.spark.mllib.feature.Word2Vec
import org.apache.spark.mllib.linalg.{Vectors, Vector}
import org.apache.spark.rdd.RDD

object Word2VecUtils {

  implicit class VectorExtensions(v: Vector) {
    def +(w: Vector): Vector = {
      val va = v.toDense.toArray
      val wa = w.toDense.toArray
      Vectors.dense(wa.zip(wa).map(x => x._1 + x._2))
    }
  }

  /**
    * usage: pass in a tokenized document, and the number of words you want,
    * and get back a weighted vector of "synonyms" of this document.
    * @param model trained via something like the following:
    *              val w2v = org.apache.spark.mllib.feature.Word2Vec()
    *              val tokenizedCorpus: RDD[ List[String] ]  = ...
    *              val model = w2v.fit(tokenizedCorpus)
    *              import Word2VecUtils._
    *              model.findDocSynonyms("the quick brown fox".split(" "), 2).foreach(println)
    */
  implicit class Word2VecExtensions(model: Word2VecModel) {
    private val vocab = model.getVectors.keySet

    def findDocSynonyms(doc: Iterable[String], num: Int): Array[(String, Double)] = {
      val docVector = doc.filter(vocab.contains).map(model.transform).reduce(_ + _)
      model.findSynonyms(docVector, num)
    }

    def safelyFindSynonyms(word: String, num: Int): Array[(String, Double)] = {
      if (vocab.contains(word)) {
        model.findSynonyms(word, num)
      } else {
        Array.empty
      }
    }
  }

  def train(corpus: RDD[List[String]]): Word2VecModel = {
    new Word2Vec().fit(corpus)
  }

}

case class Corpus[T](data: RDD[(Long, T, Vector)], dict: Map[String, Int]) {
  val reverseDict: Array[String] = dict.toList.sortBy(_._2).map(_._1).toArray
}

object CorpusUtils {
  def vectorize[T](rawInput: RDD[T],
                   id: (T => Long),
                   tokenize: (T => Iterable[String])): Corpus[T] = {
    val tokenized = rawInput.map(t => (id(t), tokenize(t)))
    // count number of unique documents containing each token
    val tokenCounts = tokenized.flatMap(_._2.toSet.map((tok: String) => (tok, 1))).reduceByKey(_ + _)
    val minSupport = 5
    val numDocs = tokenized.count()
    val maxSupport = 0.5 * numDocs
    val dictionary =
      tokenCounts.filter(p => p._2 >= minSupport && p._2 < maxSupport).keys.collect().sorted.zipWithIndex.toMap
    val dictionaryVectorizer = (t: T) => {
      val tokens = tokenize(t)
      val tokenIndexCounts = tokens.flatMap(dictionary.get).groupBy(identity).mapValues(_.sum.toDouble).toList
      Vectors.sparse(dictionary.size, tokenIndexCounts)
    }
    val corpus: Corpus[T] = Corpus(rawInput.map(x => (id(x), x, dictionaryVectorizer(x))), dictionary)
    corpus
  }
}

object ClusterUtils {
  val ALPHA = 0.05

  def vectorize(corpus: RDD[(Long, List[String])]): RDD[Vector] = {
    val id = (p: (Long, List[String])) => p._1
    val tokens = (p: (Long, List[String])) => p._2
    val vectorizedCorpus = CorpusUtils.vectorize[(Long, List[String])](corpus, id, tokens)
    vectorizedCorpus.data.map(_._3)
  }

  def generateClusters(corpus: RDD[(Long, List[String])], k: Int = 20, maxIters: Int = 50): KMeansModel = {
    val data = vectorize(corpus)
    val kmeans = KMeans.train(data, k, maxIters)
    kmeans
  }
}