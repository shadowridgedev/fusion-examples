Basics
======================

Assuming you have some tweets in your twitter collection

A few basic commands to try out from the spark-shell:


1. :load /MY/PATH/fusion-examples/great-wide-open-2016/src/main/scala/BasicSolr.scala
1. :load /MY/PATH/fusion-examples/great-wide-open-2016/src/main/scala/CorpusUtils.scala
1. :load /MY/PATH/fusion-examples/great-wide-open-2016/src/main/scala/KMeansUtils.scala
1. val tweets = BasicSolr.loadTweets(sqlContext)
1. tweets.printSchema()
1. tweets.show(10)
1. tweets.select("id", "author").show(10)





Data Frames
=====================

http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.sql.DataFrame

1.  tweets.filter(tweets("tagsText_ss").isNotNull).select("id", "tweet_t", "tagsText_ss").show(10) 



Word 2 Vec
======================

http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.ml.feature.Word2Vec

1. val body = tweets.flatMap(t => BasicSolr.first[String](t, "tweet_t"))  // lets get the tweets
1. val tokenBody = body.map(b => b.toLowerCase().split(" ").toList)  // build the model
1. val w2vModel = Word2VecUtils.train(tokenBody)
1. import Word2VecUtils._
1. w2vModel.safelyFindSynonyms("lucene", 5)


k-Means
=======================

http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.mllib.clustering.KMeans

1. import BasicSolr._
1. val idBody = tweets.selectIdAndText("id", "tweet_t") // get id, text tuples
1. val corpus = KMeansUtils.generateClusters(idBody, 5, 5)  // do the clustering
1.    