import org.apache.spark.rdd.RDD
import org.apache.spark.sql.{ DataFrame, Row, SQLContext }

//  :load /path/to/fusion-examples/great-wide-open-2016/src/main/scala/com/lucidworks/gwo/BasicSolr.scala
object BasicSolr extends Serializable {

  def langCardinality(sqlContext: SQLContext): DataFrame = {
    val tweets: DataFrame = loadTweets(sqlContext)
    tweets.cache()
    tweets.registerTempTable("tweets")
    tweets.groupBy("lang_s").count().show(50)
    tweets
  }

  def loadTweets(
    sqlContext: SQLContext,
    zkHost: String = "localhost:9983",
    collection: String = "twitter",
    query: String = "*:*"): DataFrame = {
    val opts = Map(
      "zkhost" -> zkHost,
      "collection" -> collection,
      "query" -> query)

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

  implicit class DataFrameExtensions(df: DataFrame) extends Serializable {
    def selectIdAndText(id: String, textColumn: String): RDD[(String, String)] = {
      df.select(id, textColumn).flatMap {
        r => first[String](r, textColumn).map((r.getAs[String](id), _))
      }
    }
  }
}
