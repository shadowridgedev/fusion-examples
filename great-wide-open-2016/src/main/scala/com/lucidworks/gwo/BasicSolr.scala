package com.lucidworks.gwo

import org.apache.spark.sql.{Row, DataFrame, SQLContext}

//  :load /Users/grantingersoll/projects/lucid/fusion-examples/great-wide-open-2016/src/main/scala/com/lucidworks/gwo/BasicSolr.scala
object BasicSolr extends Serializable{

  def setup(sqlContext: SQLContext): DataFrame = {
    val opts = Map(
      "zkhost" -> "localhost:9983",
      "collection" -> "twitter",
      "query" -> "*:*")

    val tweets = sqlContext.read.format("solr").options(opts).load
    tweets
  }

  def first[T](row: Row, field: String): Option[T] = {
      val w = row.getAs[scala.collection.mutable.WrappedArray[T]](field)
      if (w == null) {
        None
      } else {
        val h = w.headOption
        if (h.get == null) {
          None
        } else {
          h
        }
      }
    }
    def get[T](row: Row, f: String): Option[T] = {
      val x = row.getAs[T](f)
      Option(x)
    }
    def all[T](row: Row, f: String): List[T] = {
      val w = row.getAs[scala.collection.mutable.WrappedArray[T]](f)
      if (w == null) {
        List.empty[T]
      } else {
        w.toList.filterNot(_ == null)
      }
    }

  def langCardinality(sqlContext: SQLContext): DataFrame = {
    val tweets: DataFrame = setup(sqlContext)
    println(tweets.collect())
    tweets.cache()
    tweets.registerTempTable("tweets")
    tweets.groupBy("lang_s").count().show(50)
    tweets
  }

  def example2(sqlContext: SQLContext): DataFrame = {
    val opts = Map(
      "zkhost" -> "localhost:9983",
      "collection" -> "twitter",
      "fields" -> "id,tweet_t,tagsText_ss",
      "query" -> "*:*")

    val tweets = sqlContext.read.format("solr").options(opts).load
    println(tweets.collect())
    tweets.cache()
    tweets.registerTempTable("logs")
    tweets
  }
}
