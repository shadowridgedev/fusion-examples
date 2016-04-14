import org.apache.spark.ml.clustering.{LDAModel, LDA, KMeans}
import org.apache.spark.ml.feature.Word2Vec
import org.apache.spark.sql.functions._
import org.apache.spark.sql.{DataFrame, SQLContext}
import org.apache.spark.mllib.linalg.{Vector => SparkVector, Vectors}


case class TfIdfVectorizer(tokenzier: String => List[String],
                           dictionary: Map[String, Int],
                           idfs: Map[String, Double]) extends (String => SparkVector) {
  override def apply(s: String): SparkVector = {
    val tokenTfs = tokenzier(s).groupBy(identity).mapValues(_.size).toList
    val tfIdfMap = tokenTfs.flatMap { case (token, tf) =>
      dictionary.get(token).map(idx => (idx, tf * idfs.getOrElse(token, 1.0))) }
    Vectors.sparse(dictionary.size, tfIdfMap)
  }
}

object BasicSolr extends Serializable {

  def langCardinality(sqlContext: SQLContext): DataFrame = {
    val tweets: DataFrame = loadTweets(sqlContext)
    tweets.cache()
    tweets.registerTempTable("tweets")
    tweets.groupBy("lang_s").count().show(50)
    tweets
  }

  def loadTweets(sqlContext: SQLContext,
                 zkHost: String = "localhost:9983",
                 collection: String = "twitter",
                 query: String = "*:*"): DataFrame = {
    val opts = Map(
      "zkhost" -> zkHost,
      "collection" -> collection,
      "query" -> query)
    sqlContext.read.format("solr").options(opts).load
  }


  def buildVectorizer(df: DataFrame,
                      tokenizer: String => List[String],
                      fieldName: String = "tweet",
                      minSupport: Int = 5,
                      maxSupportFraction: Double = 0.5) = {
    val tokenField = fieldName + "_token"
    val withWords = df.select(fieldName).explode(fieldName, tokenField)(tokenizer)
    val numDocs = df.count().toDouble
    val maxSupport = numDocs * maxSupportFraction
    val tokenCountsDF =
      withWords.groupBy(tokenField).count().filter(col("count") > minSupport && col("count") < maxSupport)
    val idfs = tokenCountsDF.map(r => (r.getString(0), math.log(1 + (numDocs / (1 + r.getLong(1)))))).collect().toMap
    val dictionary = idfs.keys.toArray.zipWithIndex.toMap
    TfIdfVectorizer(tokenizer, dictionary, idfs)
  }

  def vectorize(df: DataFrame, vectorizer: TfIdfVectorizer, fieldName: String = "tweet") = {
    val vectorizerUdf = udf(vectorizer)
    df.withColumn(fieldName + "_vect", vectorizerUdf(col(fieldName)))
  }

  def buildKmeansModel(df: DataFrame, k: Int = 5, maxIter: Int = 10, fieldName: String = "tweet") = {
    val kMeans = new KMeans()
      .setK(k)
      .setMaxIter(maxIter)
      .setFeaturesCol(fieldName + "_vect")
      .setPredictionCol("kmeans_cluster_i")
    kMeans.fit(df)
  }

  def buildLDAModel(df: DataFrame, k: Int = 5, fieldName: String = "tweet") = {
    val lda = new LDA()
      .setK(k)
      .setFeaturesCol(fieldName + "_vect")
    lda.fit(df)
  }

  def buildWord2VecModel(df: DataFrame, tokenzier: String => List[String], fieldName: String = "tweet") = {
    val tokenizerUdf = udf(tokenzier)
    val withTokens = df.withColumn(fieldName + "_tokens", tokenizerUdf(col(fieldName)))
    val word2Vec = new Word2Vec()
      .setInputCol(fieldName + "_tokens")
      .setOutputCol(fieldName + "_w2v")
    word2Vec.fit(withTokens)
  }

  def tokensForTopics(lda: LDAModel, vectorizer: TfIdfVectorizer): Map[Int, List[(String, Double)]] = {
    val reverseDictionary = vectorizer.dictionary.toList.map(_.swap).toMap
    val topicDist = lda.topicsMatrix
    val tokenWeights = for {
      k <- 0 until lda.getK
      i <- 0 until vectorizer.dictionary.size
    } yield {
      k -> (reverseDictionary(i), topicDist(i, k))
    }
    tokenWeights.groupBy(_._1).mapValues(_.map(_._2).toList.sortBy(-_._2))
  }
}
