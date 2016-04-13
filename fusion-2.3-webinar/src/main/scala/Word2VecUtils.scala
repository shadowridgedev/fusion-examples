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

  def trainCorpus(corpus: Corpus[String, String],
                  tokenizer: (String => List[String]) = (s: String) => s.toLowerCase.split("\\s+").toList) = {
    val w2vModel = Word2VecUtils.train(corpus.data.map(dv => tokenizer(dv.doc)))
    corpus.copy(word2VecModel = Some(w2vModel))
  }

}