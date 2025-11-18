"""
Schema Fetcher Module
Retrieves schema information from SQL databases
"""

from typing import List, Dict, Any
from sqlalchemy import Engine, text, inspect
from sqlalchemy.exc import SQLAlchemyError
import logging

logger = logging.getLogger(__name__)


class SchemaFetcher:
    """
    Fetches schema information from SQL databases.
    """

    def __init__(self, engine: Engine):
        """
        Initialize SchemaFetcher with database engine.

        Args:
            engine (Engine): SQLAlchemy engine object
        """
        self.engine = engine
        self.inspector = inspect(engine)

    def get_all_tables(self) -> List[str]:
        """
        Get list of all tables in the database.

        Returns:
            List[str]: List of table names
        """
        try:
            tables = self.inspector.get_table_names()
            logger.info(f"Found {len(tables)} tables in database")
            return tables
        except SQLAlchemyError as e:
            logger.error(f"Error fetching tables: {str(e)}")
            return []

    def get_table_columns(self, table_name: str) -> List[Dict[str, Any]]:
        """
        Get column information for a specific table.

        Args:
            table_name (str): Name of the table

        Returns:
            List[Dict[str, Any]]: List of column information dictionaries
        """
        try:
            columns = self.inspector.get_columns(table_name)
            column_info = []

            for col in columns:
                column_info.append({
                    'name': col['name'],
                    'type': str(col['type']),
                    'nullable': col['nullable'],
                    'default': col.get('default'),
                    'autoincrement': col.get('autoincrement', False),
                    'comment': col.get('comment', '')
                })

            logger.info(f"Fetched {len(column_info)} columns for table '{table_name}'")
            return column_info

        except SQLAlchemyError as e:
            logger.error(f"Error fetching columns for table '{table_name}': {str(e)}")
            return []

    def get_primary_keys(self, table_name: str) -> List[str]:
        """
        Get primary key columns for a table.

        Args:
            table_name (str): Name of the table

        Returns:
            List[str]: List of primary key column names
        """
        try:
            pk_constraint = self.inspector.get_pk_constraint(table_name)
            return pk_constraint.get('constrained_columns', [])
        except SQLAlchemyError as e:
            logger.error(f"Error fetching primary keys for '{table_name}': {str(e)}")
            return []

    def get_foreign_keys(self, table_name: str) -> List[Dict[str, Any]]:
        """
        Get foreign key information for a table.

        Args:
            table_name (str): Name of the table

        Returns:
            List[Dict[str, Any]]: List of foreign key information
        """
        try:
            fks = self.inspector.get_foreign_keys(table_name)
            fk_info = []

            for fk in fks:
                fk_info.append({
                    'name': fk.get('name'),
                    'constrained_columns': fk.get('constrained_columns', []),
                    'referred_table': fk.get('referred_table'),
                    'referred_columns': fk.get('referred_columns', [])
                })

            return fk_info

        except SQLAlchemyError as e:
            logger.error(f"Error fetching foreign keys for '{table_name}': {str(e)}")
            return []

    def get_indexes(self, table_name: str) -> List[Dict[str, Any]]:
        """
        Get index information for a table.

        Args:
            table_name (str): Name of the table

        Returns:
            List[Dict[str, Any]]: List of index information
        """
        try:
            indexes = self.inspector.get_indexes(table_name)
            index_info = []

            for idx in indexes:
                index_info.append({
                    'name': idx.get('name'),
                    'columns': idx.get('column_names', []),
                    'unique': idx.get('unique', False)
                })

            return index_info

        except SQLAlchemyError as e:
            logger.error(f"Error fetching indexes for '{table_name}': {str(e)}")
            return []

    def get_table_comment(self, table_name: str) -> str:
        """
        Get table comment/description.

        Args:
            table_name (str): Name of the table

        Returns:
            str: Table comment
        """
        try:
            table_info = self.inspector.get_table_comment(table_name)
            return table_info.get('text', '')
        except (SQLAlchemyError, NotImplementedError) as e:
            logger.debug(f"Table comments not supported or error for '{table_name}': {str(e)}")
            return ''

    def get_table_row_count(self, table_name: str) -> int:
        """
        Get approximate row count for a table.

        Args:
            table_name (str): Name of the table

        Returns:
            int: Row count
        """
        try:
            with self.engine.connect() as conn:
                result = conn.execute(text(f"SELECT COUNT(*) FROM {table_name}"))
                count = result.scalar()
                return count or 0
        except SQLAlchemyError as e:
            logger.error(f"Error counting rows for '{table_name}': {str(e)}")
            return 0
