Basics
======================

Assuming you have some tweets in your twitter collection

A few basic commands to try out from the spark-shell:


1. :load /MY/PATH/fusion-examples/great-wide-open-2016/src/main/scala/com/lucidworks/gwo/BasicSolr.scala
1. val tweets = BasicSolr.setup(sqlContext);
1. tweets.printSchema();
1. tweets.show(10);
1. tweets.select("id", "author").show(10);





Data Frames
=====================

http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.sql.DataFrame

1.  tweets.filter(tweets("tagsText_ss").isNotNull).select("id", "tweet_t", "tagsText_ss").show(10); 



Word 2 Vec
======================

http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.ml.feature.Word2Vec

1. val body = tweets.flatMap(t => BasicSolr.first[String](t, "tweet_t"));  // lets get the tweets
1. body.map(b => b.toLowerCase().split(" ").toList)   // Per tweet "dumb" tokenization
1. val tokenBody = body.map(b => b.toLowerCase().split(" ").toList)  // build the model
1. import Word2VecUtils._
1. w2vModel.safelyFindSynonyms("lucene", 5)


k-Means
=======================

http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.mllib.clustering.KMeans

1. 