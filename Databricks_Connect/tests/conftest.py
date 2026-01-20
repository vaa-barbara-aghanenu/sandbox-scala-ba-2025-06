from __future__ import annotations

import pytest
from pyspark.sql import SparkSession


@pytest.fixture(scope="session")
def spark():
    """Provide a local Spark session backed by the pyspark package."""
    session = (
        SparkSession.builder.master("local[2]")
        .appName("pytest-local-spark")
        .config("spark.ui.enabled", "false")
        .getOrCreate()
    )
    try:
        yield session
    finally:
        session.stop()
