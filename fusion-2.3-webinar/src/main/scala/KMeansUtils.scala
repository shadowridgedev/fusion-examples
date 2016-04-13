import org.apache.spark.mllib.linalg.{Vectors, Vector}
import org.apache.spark.mllib.clustering.{KMeans, KMeansModel}
import org.apache.spark.rdd.RDD

object KMeansUtils {
  /**
    *
    * @param stringCorpus RDD of (id: String, text: String) document rows
    * @param k number of clusters
    * @param maxIters to stop at before convergence (default 20)
    * @param tokenizer function to split the text (default to lower-casing and splitting on whitespace)
    * @return both a Corpus (input docs together with vectors) and a trained KMeans model
    */
  def generateClusters(stringCorpus: RDD[(String, String)],
                       k: Int,
                       maxIters: Int = 20,
                       tokenizer: (String => List[String]) = (s: String) => s.toLowerCase.split("\\s+").toList
                      ): Corpus[String, String] = {
    val corpus = CorpusUtils.vectorize(stringCorpus, tokenizer)
    val kMeansModel = KMeans.train(corpus.data.map(_.vector), k, maxIters)
    corpus.copy(kmeansModel = Some(kMeansModel))
  }
}
