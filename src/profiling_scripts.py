"""
Data Profiling Module
Runs various profiling scripts to assess data quality and characteristics
"""

from typing import Dict, Any, List, Optional
from sqlalchemy import Engine, text
from sqlalchemy.exc import SQLAlchemyError
import logging

logger = logging.getLogger(__name__)


class DataProfiler:
    """
    Executes data profiling scripts for quality assessment.
    """

    def __init__(self, engine: Engine):
        """
        Initialize DataProfiler with database engine.

        Args:
            engine (Engine): SQLAlchemy engine object
        """
        self.engine = engine

    def profile_table(self, table_name: str) -> Dict[str, Any]:
        """
        Run comprehensive profiling on a table.

        Args:
            table_name (str): Name of the table to profile

        Returns:
            Dict[str, Any]: Profiling results
        """
        logger.info(f"Starting profiling for table: {table_name}")

        profile = {
            'table_name': table_name,
            'row_count': self.get_row_count(table_name),
            'column_profiles': {},
            'data_quality': {}
        }

        # Get columns
        columns = self._get_columns(table_name)

        for column in columns:
            profile['column_profiles'][column] = self.profile_column(table_name, column)

        # Data quality checks
        profile['data_quality'] = {
            'null_check': self.check_null_values(table_name),
            'duplicate_check': self.check_duplicates(table_name),
            'completeness_score': self.calculate_completeness(table_name)
        }

        logger.info(f"Profiling completed for table: {table_name}")
        return profile

    def get_row_count(self, table_name: str) -> int:
        """
        Get total row count for a table.

        Args:
            table_name (str): Table name

        Returns:
            int: Row count
        """
        try:
            with self.engine.connect() as conn:
                result = conn.execute(text(f"SELECT COUNT(*) FROM {table_name}"))
                return result.scalar() or 0
        except SQLAlchemyError as e:
            logger.error(f"Error getting row count: {str(e)}")
            return 0

    def profile_column(self, table_name: str, column_name: str) -> Dict[str, Any]:
        """
        Profile a specific column.

        Args:
            table_name (str): Table name
            column_name (str): Column name

        Returns:
            Dict[str, Any]: Column profiling data
        """
        profile = {
            'column_name': column_name,
            'null_count': self.count_nulls(table_name, column_name),
            'distinct_count': self.count_distinct(table_name, column_name),
            'null_percentage': 0.0,
            'distinct_percentage': 0.0
        }

        total_rows = self.get_row_count(table_name)
        if total_rows > 0:
            profile['null_percentage'] = (profile['null_count'] / total_rows) * 100
            profile['distinct_percentage'] = (profile['distinct_count'] / total_rows) * 100

        # Try to get min/max for numeric/date columns
        try:
            stats = self.get_column_statistics(table_name, column_name)
            profile.update(stats)
        except Exception as e:
            logger.debug(f"Could not get statistics for {column_name}: {str(e)}")

        return profile

    def count_nulls(self, table_name: str, column_name: str) -> int:
        """
        Count NULL values in a column.

        Args:
            table_name (str): Table name
            column_name (str): Column name

        Returns:
            int: Number of NULL values
        """
        try:
            query = text(f"SELECT COUNT(*) FROM {table_name} WHERE {column_name} IS NULL")
            with self.engine.connect() as conn:
                result = conn.execute(query)
                return result.scalar() or 0
        except SQLAlchemyError as e:
            logger.error(f"Error counting nulls: {str(e)}")
            return 0

    def count_distinct(self, table_name: str, column_name: str) -> int:
        """
        Count distinct values in a column.

        Args:
            table_name (str): Table name
            column_name (str): Column name

        Returns:
            int: Number of distinct values
        """
        try:
            query = text(f"SELECT COUNT(DISTINCT {column_name}) FROM {table_name}")
            with self.engine.connect() as conn:
                result = conn.execute(query)
                return result.scalar() or 0
        except SQLAlchemyError as e:
            logger.error(f"Error counting distinct values: {str(e)}")
            return 0

    def get_column_statistics(self, table_name: str, column_name: str) -> Dict[str, Any]:
        """
        Get statistical information for a column (min, max, avg for numeric).

        Args:
            table_name (str): Table name
            column_name (str): Column name

        Returns:
            Dict[str, Any]: Statistics dictionary
        """
        stats = {}
        try:
            query = text(f"""
                SELECT
                    MIN({column_name}) as min_value,
                    MAX({column_name}) as max_value,
                    AVG({column_name}) as avg_value
                FROM {table_name}
            """)
            with self.engine.connect() as conn:
                result = conn.execute(query)
                row = result.fetchone()
                if row:
                    stats['min_value'] = str(row[0]) if row[0] is not None else None
                    stats['max_value'] = str(row[1]) if row[1] is not None else None
                    stats['avg_value'] = str(row[2]) if row[2] is not None else None
        except SQLAlchemyError:
            # Column might not be numeric, skip statistics
            pass

        return stats

    def check_null_values(self, table_name: str) -> Dict[str, Any]:
        """
        Check for NULL values across all columns.

        Args:
            table_name (str): Table name

        Returns:
            Dict[str, Any]: NULL check results
        """
        columns = self._get_columns(table_name)
        total_rows = self.get_row_count(table_name)

        null_report = {
            'columns_with_nulls': [],
            'null_free_columns': []
        }

        for column in columns:
            null_count = self.count_nulls(table_name, column)
            if null_count > 0:
                null_report['columns_with_nulls'].append({
                    'column': column,
                    'null_count': null_count,
                    'null_percentage': (null_count / total_rows * 100) if total_rows > 0 else 0
                })
            else:
                null_report['null_free_columns'].append(column)

        return null_report

    def check_duplicates(self, table_name: str, columns: Optional[List[str]] = None) -> Dict[str, Any]:
        """
        Check for duplicate rows.

        Args:
            table_name (str): Table name
            columns (Optional[List[str]]): Specific columns to check, or all if None

        Returns:
            Dict[str, Any]: Duplicate check results
        """
        try:
            if columns is None:
                # Check for completely duplicate rows
                query = text(f"""
                    SELECT COUNT(*) - COUNT(DISTINCT *) as duplicate_count
                    FROM {table_name}
                """)
            else:
                columns_str = ', '.join(columns)
                query = text(f"""
                    SELECT COUNT(*) - COUNT(DISTINCT {columns_str}) as duplicate_count
                    FROM {table_name}
                """)

            with self.engine.connect() as conn:
                result = conn.execute(query)
                duplicate_count = result.scalar() or 0

            total_rows = self.get_row_count(table_name)
            duplicate_percentage = (duplicate_count / total_rows * 100) if total_rows > 0 else 0

            return {
                'duplicate_rows': duplicate_count,
                'total_rows': total_rows,
                'duplicate_percentage': duplicate_percentage,
                'has_duplicates': duplicate_count > 0
            }

        except SQLAlchemyError as e:
            logger.error(f"Error checking duplicates: {str(e)}")
            return {
                'error': str(e),
                'has_duplicates': None
            }

    def calculate_completeness(self, table_name: str) -> float:
        """
        Calculate overall data completeness score for a table.

        Args:
            table_name (str): Table name

        Returns:
            float: Completeness score (0-100)
        """
        columns = self._get_columns(table_name)
        total_rows = self.get_row_count(table_name)

        if not columns or total_rows == 0:
            return 0.0

        total_cells = len(columns) * total_rows
        null_cells = sum(self.count_nulls(table_name, col) for col in columns)

        completeness = ((total_cells - null_cells) / total_cells * 100) if total_cells > 0 else 0
        return round(completeness, 2)

    def get_value_distribution(self, table_name: str, column_name: str, limit: int = 10) -> List[Dict[str, Any]]:
        """
        Get value distribution for a column.

        Args:
            table_name (str): Table name
            column_name (str): Column name
            limit (int): Maximum number of distinct values to return

        Returns:
            List[Dict[str, Any]]: Value distribution
        """
        try:
            query = text(f"""
                SELECT {column_name} as value, COUNT(*) as count
                FROM {table_name}
                GROUP BY {column_name}
                ORDER BY count DESC
                LIMIT {limit}
            """)

            with self.engine.connect() as conn:
                result = conn.execute(query)
                distribution = [
                    {'value': str(row[0]), 'count': row[1]}
                    for row in result
                ]

            return distribution

        except SQLAlchemyError as e:
            logger.error(f"Error getting value distribution: {str(e)}")
            return []

    def run_custom_query(self, query: str) -> List[Dict[str, Any]]:
        """
        Execute a custom SQL query for profiling.

        Args:
            query (str): SQL query to execute

        Returns:
            List[Dict[str, Any]]: Query results
        """
        try:
            with self.engine.connect() as conn:
                result = conn.execute(text(query))
                columns = result.keys()
                return [dict(zip(columns, row)) for row in result]

        except SQLAlchemyError as e:
            logger.error(f"Error executing custom query: {str(e)}")
            raise

    def _get_columns(self, table_name: str) -> List[str]:
        """
        Get list of column names for a table.

        Args:
            table_name (str): Table name

        Returns:
            List[str]: Column names
        """
        from sqlalchemy import inspect
        inspector = inspect(self.engine)
        columns = inspector.get_columns(table_name)
        return [col['name'] for col in columns]
