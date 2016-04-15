import org.apache.spark.ml.clustering.{LDAModel, LDA, KMeans}
import org.apache.spark.ml.feature.Word2Vec
import org.apache.spark.sql.functions._
import org.apache.spark.sql.{DataFrame, SQLContext}
import org.apache.spark.mllib.linalg.{Vector => SparkVector, Vectors}

import com.lucidworks.spark.analysis.LuceneTextAnalyzer


case class TfIdfVectorizer(tokenizer: String => List[String],
                           dictionary: Map[String, Int],
                           idfs: Map[String, Double]) extends (String => SparkVector) {
  override def apply(s: String): SparkVector = {
    val tokenTfs = tokenizer(s).groupBy(identity).mapValues(_.size).toList
    val tfIdfMap = tokenTfs.flatMap { case (token, tf) =>
      dictionary.get(token).map(idx => (idx, tf * idfs.getOrElse(token, 1.0))) }
    Vectors.sparse(dictionary.size, tfIdfMap)
  }
}

/**
  * Usage:

:load $FUSION_EXAMPLES_CHECKOUT/fusion-2.3-webinar/src/main/scala/BasicSolr2.scala

import BasicSolr._

// load them tweets!
val tweets = loadTweets(sqlContext)

// create a serialization-safe wrapper around the Lucene analyzer
val analyzer = new LuceneTextAnalyzer(analyzerSchema)
val analyzerFn = (s: String) => analyzer.analyze("ignored", s).toList

// build a dictionary vectorizer with tf-idf weighting
val vectorizer = buildVectorizer(tweets, analyzerFn)

// append a "tweet_vect" field with the vectors from the "tweet" field
val tweetsWithVectors = vectorize(tweets, vectorizer)

tweetsWithVectors.select("id", "tweet_vect").show()

// build a kmeans model:
val kmm = buildKmeansModel(tweetsWithVectors, k = 10, maxIter = 20)

// append the cluster ids to the tweets:
val tweetsWithCentroids = kmm.transform(tweetsWithVectors)

tweetsWithCentroids.groupBy("kmeans_cluster_i").count().show()

// build an LDA model:

val lda = buildLDAModel(tweetsWithVectors, k = 20)

// get human-understandable topics from the model:

val termTopicDistributions = tokensForTopics(lda, vectorizer)
val topTerms = termTopicDistributions.mapValues(_.take(10))
topTerms.foreach { case (topicId, tokens) => println(s"topic_$topicId: ${tokens.map(_._1).mkString(", ")}") }

// infer topic distributions on the tweets, and append these distributions back onto them in a new field:

val tweetsWithTopicIds = lda.transform(tweetsWithCentroids)

tweetsWithCentroids.select("id","tweet_vect","kmeans_cluster_i","topicDistribution").show()

// word2vec!

val w2vModel = buildWord2VecModel(tweets, analyzerFn)
w2vModel.findSynonyms("solr", 5)

  */
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

  val analyzerSchema = """{ "analyzers": [
                 |                { "name": "StdTokLowerStop",
                 |                  "tokenizer": { "type": "standard" },
                 |                  "filters": [{ "type": "lowercase" },
                 |                              { "type": "stop" }] }],
                 |        "fields": [{ "regex": ".+", "analyzer": "StdTokLowerStop" } ]}
               """.stripMargin

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
