import org.apache.spark.sql.SparkSession

object ExampleSparkJob {
  def main(args: Array[String]): Unit = {
    val spark = SparkSession.builder()
      .appName("ExampleSparkJob")
      .getOrCreate()

    import spark.implicits._

    val numbers = spark.range(1, 6).toDF("number")
    val count = numbers.count()
    println(s"Total count: $count")

    spark.stop()
  }
}
