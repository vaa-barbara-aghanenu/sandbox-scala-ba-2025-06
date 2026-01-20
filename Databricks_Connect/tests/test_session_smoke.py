"""Spark smoke tests used by the portable runtime workflow (see README)."""

import pytest


@pytest.mark.spark_local
def test_range_count(spark):
    df = spark.range(10)
    assert df.count() == 10
