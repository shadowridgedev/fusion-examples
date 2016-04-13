import org.apache.spark.rdd.RDD
import org.apache.spark.sql.{DataFrame, Row, SQLContext}

object BasicSolr extends Serializable {

  def langCardinality(sqlContext: SQLContext): DataFrame = {
    val tweets: DataFrame = loadTweets(sqlContext)
    tweets.cache()
    tweets.registerTempTable("tweets")
    tweets.groupBy("userLang").count().show(50)
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

    val tweets = sqlContext.read.format("solr").options(opts).load
    tweets
  }

  implicit class RowExt(row: Row) {
    def allStrings(field: String): List[String] = {
      row.get(row.fieldIndex(field)) match {
        case null => List.empty[String]
        case w: scala.collection.mutable.WrappedArray[String] =>
          w.toList.filterNot(_ == null)
        case t => List[String](t.toString)
      }
    }
  }

  implicit class Ext(df: DataFrame) extends Serializable {
    def selectIdAndText(id: String, textColumn: String): RDD[(String, String)] = {
      df.select(id, textColumn).flatMap {
        r => r.allStrings(textColumn).map((r.getAs[String](id), _))
      }
    }
  }
}
