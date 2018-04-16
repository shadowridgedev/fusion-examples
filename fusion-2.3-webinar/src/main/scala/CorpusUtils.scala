import org.apache.spark.mllib.clustering.KMeansModel
import org.apache.spark.mllib.feature.Word2VecModel
import org.apache.spark.mllib.linalg.{ Vectors, Vector }
import org.apache.spark.rdd.RDD

import scala.collection.mutable

case class DocWithVector[ID, T](id: ID, doc: T, vector: Vector)

case class Corpus[ID, T](
  data: RDD[DocWithVector[ID, T]],
  dict: Map[String, Int],
  tokenizer: T => Vector,
  kmeansModel: Option[KMeansModel] = None,
  word2VecModel: Option[Word2VecModel] = None) {
  val reverseDict: Array[String] = dict.toList.sortBy(_._2).map(_._1).toArray

  def findNearestCluster(doc: T): Option[Int] = {
    val vector = tokenizer(doc)
    kmeansModel.map(_.predict(vector))
  }

  def topTerms(clusterId: Int, num: Int): List[(String, Double)] = {
    val cmp = (p: (String, Double)) => -math.abs(p._2)
    implicit val ord = Ordering.by(cmp)
    val termWeights = new mutable.PriorityQueue[(String, Double)]()
    kmeansModel.foreach(_.clusterCenters(clusterId).foreachActive {
      case (idx, wt) =>
        if (termWeights.size < num) {
          val w = (reverseDict(idx), wt)
          termWeights += w
        } else if (math.abs(wt) > math.abs(termWeights.head._2)) {
          termWeights.dequeue()
          val w = (reverseDict(idx), wt)
          termWeights += w
        }
    })
    termWeights.toList
  }

}

object CorpusUtils {
  def vectorize[ID, T](
    rawInput: RDD[(ID, T)],
    tokenize: (T => Iterable[String])): Corpus[ID, T] = {
    val tokenized = rawInput.map(t => (t._1, tokenize(t._2)))
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
    val corpus: Corpus[ID, T] =
      Corpus(rawInput.map(x => DocWithVector(x._1, x._2, dictionaryVectorizer(x._2))), dictionary, dictionaryVectorizer)
    corpus
  }
}
