Annotated Webinar Demo Script
======================

Assuming you have some tweets in your twitter collection, 
you can do the following (do not paste in the comments marked by //):

//Check out this file for details on implementation
:load /PATH_TO_CHECKOUT/fusion-examples/fusion-2.3-webinar/src/main/scala/BasicSolr2.scala
import BasicSolr._
//Load your data into Spark from Solr
val tweets = loadTweets(sqlContext)
//Cache the data in Spark so that we don't have to hit Solr again
tweets.cache()

//Load up the new Lucene Analyzer stuff: See https://lucidworks.com/blog/2016/04/13/spark-solr-lucenetextanalyzer/
import com.lucidworks.spark.analysis.LuceneTextAnalyzer
val analyzer = new LuceneTextAnalyzer(analyzerSchema)
val analyzerFn = (s: String) => s.toLowerCase().trim().split(" ").toList
// Create vectors out of the Tweets so that we can do k-means
val vectorizer = buildVectorizer(tweets, analyzerFn)
val tweetsWithVectors = vectorize(tweets, vectorizer)
tweetsWithVectors.select("id", "tweet_vect").show()
//Create a KMeans model with K = 10
val kmm = buildKmeansModel(tweetsWithVectors, k = 10, maxIter = 20)
// Get an RDD of the Tweets with the centroids on the tweet
val tweetsWithCentroids = kmm.transform(tweetsWithVectors)
// See, it worked!
tweetsWithCentroids.groupBy("kmeans_cluster_i").count().show()
//Save to Solr
tweetsWithCentroids.write.format("solr").options(Map("zkhost" -> "localhost:9983", "collection" -> "twitter", "batchSize" -> "1000")).mode(org.apache.spark.sql.SaveMode.Overwrite).save
//DON'T FORGET TO COMMIT!!!!!!!!!!!!!!!!!!!