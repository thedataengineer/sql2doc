"""
Unit tests for DataProfiler module
"""

import pytest
from sqlalchemy import create_engine, text
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))

from src.profiling_scripts import DataProfiler


@pytest.fixture
def test_engine_with_data(tmp_path):
    """Create a test SQLite database with sample data."""
    db_file = tmp_path / "test.db"
    engine = create_engine(f"sqlite:///{db_file}")

    with engine.connect() as conn:
        # Create table
        conn.execute(text("""
            CREATE TABLE customers (
                id INTEGER PRIMARY KEY,
                name VARCHAR(100),
                email VARCHAR(100),
                age INTEGER,
                city VARCHAR(50)
            )
        """))

        # Insert test data
        conn.execute(text("""
            INSERT INTO customers (id, name, email, age, city) VALUES
            (1, 'John Doe', 'john@example.com', 30, 'New York'),
            (2, 'Jane Smith', 'jane@example.com', 25, 'Los Angeles'),
            (3, 'Bob Johnson', NULL, 35, 'Chicago'),
            (4, 'Alice Brown', 'alice@example.com', NULL, 'New York'),
            (5, 'Charlie Wilson', 'charlie@example.com', 40, 'New York')
        """))

        conn.commit()

    yield engine

    engine.dispose()


class TestDataProfiler:
    """Test cases for DataProfiler class."""

    def test_init(self, test_engine_with_data):
        """Test DataProfiler initialization."""
        profiler = DataProfiler(test_engine_with_data)
        assert profiler.engine is not None

    def test_get_row_count(self, test_engine_with_data):
        """Test getting row count."""
        profiler = DataProfiler(test_engine_with_data)
        count = profiler.get_row_count('customers')

        assert count == 5

    def test_count_nulls(self, test_engine_with_data):
        """Test counting NULL values."""
        profiler = DataProfiler(test_engine_with_data)

        # email column has 1 NULL
        null_count = profiler.count_nulls('customers', 'email')
        assert null_count == 1

        # age column has 1 NULL
        null_count = profiler.count_nulls('customers', 'age')
        assert null_count == 1

        # id column has no NULLs
        null_count = profiler.count_nulls('customers', 'id')
        assert null_count == 0

    def test_count_distinct(self, test_engine_with_data):
        """Test counting distinct values."""
        profiler = DataProfiler(test_engine_with_data)

        # id should have 5 distinct values
        distinct = profiler.count_distinct('customers', 'id')
        assert distinct == 5

        # city has 3 distinct values (New York appears 3 times)
        distinct = profiler.count_distinct('customers', 'city')
        assert distinct == 3

    def test_profile_column(self, test_engine_with_data):
        """Test column profiling."""
        profiler = DataProfiler(test_engine_with_data)
        profile = profiler.profile_column('customers', 'email')

        assert profile['column_name'] == 'email'
        assert profile['null_count'] == 1
        assert profile['null_percentage'] == 20.0  # 1 out of 5
        assert profile['distinct_count'] == 4  # 4 unique emails (1 NULL)

    def test_check_null_values(self, test_engine_with_data):
        """Test NULL value checking across table."""
        profiler = DataProfiler(test_engine_with_data)
        null_check = profiler.check_null_values('customers')

        assert 'columns_with_nulls' in null_check
        assert 'null_free_columns' in null_check

        # Should have 2 columns with nulls (email and age)
        assert len(null_check['columns_with_nulls']) == 2

        # Check column names
        null_cols = [col['column'] for col in null_check['columns_with_nulls']]
        assert 'email' in null_cols
        assert 'age' in null_cols

    def test_calculate_completeness(self, test_engine_with_data):
        """Test completeness calculation."""
        profiler = DataProfiler(test_engine_with_data)
        completeness = profiler.calculate_completeness('customers')

        # 5 rows * 5 columns = 25 cells
        # 2 NULL values = 23 filled cells
        # 23/25 = 92%
        assert completeness == 92.0

    def test_get_value_distribution(self, test_engine_with_data):
        """Test value distribution retrieval."""
        profiler = DataProfiler(test_engine_with_data)
        distribution = profiler.get_value_distribution('customers', 'city', limit=5)

        assert len(distribution) > 0

        # New York should be the most common with 3 occurrences
        top_city = distribution[0]
        assert top_city['value'] == 'New York'
        assert top_city['count'] == 3

    def test_profile_table(self, test_engine_with_data):
        """Test complete table profiling."""
        profiler = DataProfiler(test_engine_with_data)
        profile = profiler.profile_table('customers')

        assert profile['table_name'] == 'customers'
        assert profile['row_count'] == 5
        assert 'column_profiles' in profile
        assert 'data_quality' in profile

        # Check column profiles exist
        assert 'id' in profile['column_profiles']
        assert 'name' in profile['column_profiles']
        assert 'email' in profile['column_profiles']

        # Check data quality
        assert 'null_check' in profile['data_quality']
        assert 'duplicate_check' in profile['data_quality']
        assert 'completeness_score' in profile['data_quality']

    def test_run_custom_query(self, test_engine_with_data):
        """Test running custom SQL query."""
        profiler = DataProfiler(test_engine_with_data)

        # Run a simple query
        results = profiler.run_custom_query("SELECT * FROM customers WHERE age > 30")

        assert len(results) == 2  # Bob (35) and Charlie (40)

        # Check result structure
        assert isinstance(results, list)
        assert all(isinstance(row, dict) for row in results)

    def test_run_custom_query_with_aggregation(self, test_engine_with_data):
        """Test running custom query with aggregation."""
        profiler = DataProfiler(test_engine_with_data)

        results = profiler.run_custom_query(
            "SELECT city, COUNT(*) as count FROM customers GROUP BY city ORDER BY count DESC"
        )

        assert len(results) == 3
        assert results[0]['city'] == 'New York'
        assert results[0]['count'] == 3

    def test_invalid_custom_query(self, test_engine_with_data):
        """Test handling of invalid SQL query."""
        profiler = DataProfiler(test_engine_with_data)

        with pytest.raises(Exception):
            profiler.run_custom_query("SELECT * FROM nonexistent_table")

    def test_get_column_statistics(self, test_engine_with_data):
        """Test getting column statistics."""
        profiler = DataProfiler(test_engine_with_data)
        stats = profiler.get_column_statistics('customers', 'age')

        # Should have min, max, avg for numeric column
        assert 'min_value' in stats
        assert 'max_value' in stats
        assert 'avg_value' in stats

        # Check values (with NULLs excluded)
        assert stats['min_value'] == '25'
        assert stats['max_value'] == '40'
