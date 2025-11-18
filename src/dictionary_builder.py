"""
Data Dictionary Builder Module
Compiles comprehensive data dictionaries from schema information
"""

from typing import Dict, Any, List
from sqlalchemy import Engine
from .schema_fetcher import SchemaFetcher
import json
import logging

logger = logging.getLogger(__name__)


class DictionaryBuilder:
    """
    Builds comprehensive data dictionaries from database schemas.
    """

    def __init__(self, engine: Engine):
        """
        Initialize DictionaryBuilder with database engine.

        Args:
            engine (Engine): SQLAlchemy engine object
        """
        self.engine = engine
        self.schema_fetcher = SchemaFetcher(engine)

    def build_full_dictionary(self, include_row_counts: bool = True) -> Dict[str, Any]:
        """
        Build complete data dictionary for all tables in the database.

        Args:
            include_row_counts (bool): Whether to include row counts (slower for large DBs)

        Returns:
            Dict[str, Any]: Complete data dictionary
        """
        logger.info("Building full data dictionary...")

        tables = self.schema_fetcher.get_all_tables()
        dictionary = {
            'database_type': self.engine.dialect.name,
            'total_tables': len(tables),
            'tables': {}
        }

        for table_name in tables:
            dictionary['tables'][table_name] = self.build_table_dictionary(
                table_name, include_row_counts
            )

        logger.info(f"Data dictionary built successfully for {len(tables)} tables")
        return dictionary

    def build_table_dictionary(self, table_name: str, include_row_count: bool = True) -> Dict[str, Any]:
        """
        Build data dictionary for a specific table.

        Args:
            table_name (str): Name of the table
            include_row_count (bool): Whether to include row count

        Returns:
            Dict[str, Any]: Table data dictionary
        """
        logger.info(f"Building dictionary for table: {table_name}")

        table_dict = {
            'table_name': table_name,
            'comment': self.schema_fetcher.get_table_comment(table_name),
            'columns': self.schema_fetcher.get_table_columns(table_name),
            'primary_keys': self.schema_fetcher.get_primary_keys(table_name),
            'foreign_keys': self.schema_fetcher.get_foreign_keys(table_name),
            'indexes': self.schema_fetcher.get_indexes(table_name),
        }

        if include_row_count:
            table_dict['row_count'] = self.schema_fetcher.get_table_row_count(table_name)

        # Add column statistics
        table_dict['total_columns'] = len(table_dict['columns'])
        table_dict['nullable_columns'] = sum(
            1 for col in table_dict['columns'] if col['nullable']
        )

        return table_dict

    def export_to_json(self, dictionary: Dict[str, Any], file_path: str):
        """
        Export data dictionary to JSON file.

        Args:
            dictionary (Dict[str, Any]): Data dictionary
            file_path (str): Output file path
        """
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(dictionary, f, indent=2, default=str)
            logger.info(f"Data dictionary exported to {file_path}")
        except Exception as e:
            logger.error(f"Error exporting to JSON: {str(e)}")
            raise

    def export_to_markdown(self, dictionary: Dict[str, Any], file_path: str):
        """
        Export data dictionary to Markdown file.

        Args:
            dictionary (Dict[str, Any]): Data dictionary
            file_path (str): Output file path
        """
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(f"# Data Dictionary\n\n")
                f.write(f"**Database Type:** {dictionary.get('database_type', 'Unknown')}\n\n")
                f.write(f"**Total Tables:** {dictionary.get('total_tables', 0)}\n\n")
                f.write("---\n\n")

                for table_name, table_info in dictionary.get('tables', {}).items():
                    self._write_table_markdown(f, table_info)

            logger.info(f"Data dictionary exported to {file_path}")
        except Exception as e:
            logger.error(f"Error exporting to Markdown: {str(e)}")
            raise

    def _write_table_markdown(self, file, table_info: Dict[str, Any]):
        """
        Write table information in Markdown format.

        Args:
            file: File object
            table_info (Dict[str, Any]): Table information dictionary
        """
        table_name = table_info.get('table_name', 'Unknown')
        file.write(f"## Table: {table_name}\n\n")

        if table_info.get('comment'):
            file.write(f"**Description:** {table_info['comment']}\n\n")

        if 'row_count' in table_info:
            file.write(f"**Row Count:** {table_info['row_count']:,}\n\n")

        # Columns
        file.write("### Columns\n\n")
        file.write("| Column Name | Data Type | Nullable | Default | Comment |\n")
        file.write("|-------------|-----------|----------|---------|----------|\n")

        for col in table_info.get('columns', []):
            file.write(
                f"| {col['name']} | {col['type']} | "
                f"{'Yes' if col['nullable'] else 'No'} | "
                f"{col.get('default', 'NULL')} | "
                f"{col.get('comment', '')} |\n"
            )

        file.write("\n")

        # Primary Keys
        if table_info.get('primary_keys'):
            file.write("**Primary Keys:** " + ", ".join(table_info['primary_keys']) + "\n\n")

        # Foreign Keys
        if table_info.get('foreign_keys'):
            file.write("### Foreign Keys\n\n")
            for fk in table_info['foreign_keys']:
                file.write(
                    f"- **{fk.get('name', 'unnamed')}**: "
                    f"{', '.join(fk.get('constrained_columns', []))} -> "
                    f"{fk.get('referred_table')}"
                    f"({', '.join(fk.get('referred_columns', []))})\n"
                )
            file.write("\n")

        # Indexes
        if table_info.get('indexes'):
            file.write("### Indexes\n\n")
            for idx in table_info['indexes']:
                unique_str = " (UNIQUE)" if idx.get('unique') else ""
                file.write(
                    f"- **{idx.get('name', 'unnamed')}**{unique_str}: "
                    f"{', '.join(idx.get('columns', []))}\n"
                )
            file.write("\n")

        file.write("---\n\n")

    def generate_summary(self, dictionary: Dict[str, Any]) -> Dict[str, Any]:
        """
        Generate summary statistics from data dictionary.

        Args:
            dictionary (Dict[str, Any]): Data dictionary

        Returns:
            Dict[str, Any]: Summary statistics
        """
        summary = {
            'total_tables': dictionary.get('total_tables', 0),
            'total_columns': 0,
            'total_rows': 0,
            'tables_with_foreign_keys': 0,
            'total_indexes': 0
        }

        for table_info in dictionary.get('tables', {}).values():
            summary['total_columns'] += table_info.get('total_columns', 0)
            summary['total_rows'] += table_info.get('row_count', 0)
            if table_info.get('foreign_keys'):
                summary['tables_with_foreign_keys'] += 1
            summary['total_indexes'] += len(table_info.get('indexes', []))

        return summary
