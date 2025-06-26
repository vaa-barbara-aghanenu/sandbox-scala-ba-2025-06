name := "spark-sandbox"
version := "0.1.0"
scalaVersion := "2.12.18"

libraryDependencies ++= Seq(
  "org.apache.spark" %% "spark-sql" % "3.5.0" % Provided,
  "org.scalatest" %% "scalatest" % "3.2.17" % Test
)

scalafmtOnCompile := false
