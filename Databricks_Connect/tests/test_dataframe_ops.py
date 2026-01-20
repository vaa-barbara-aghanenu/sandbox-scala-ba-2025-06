"""Additional Spark transformations to exercise the portable runtime."""

import pytest


@pytest.mark.spark_local
def test_even_numbers_only(spark):
    df = spark.range(0, 10)
    evens = df.filter(df.id % 2 == 0)
    assert evens.count() == 5
    assert [row.id for row in evens.orderBy("id").collect()] == [0, 2, 4, 6, 8]


@pytest.mark.spark_local
def test_grouped_sum(spark):
    data = spark.createDataFrame(
        [
            ("alpha", 1),
            ("alpha", 2),
            ("beta", 3),
            ("beta", 4),
        ],
        schema=["key", "value"],
    )
    result = data.groupBy("key").sum("value")
    aggregated = {row["key"]: row["sum(value)"] for row in result.collect()}
    assert aggregated == {"alpha": 3, "beta": 7}
