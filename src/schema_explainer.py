"""
AI-Powered Schema Explainer
Generates human-readable explanations and documentation for database schemas using local LLM
"""

from typing import Dict, List, Optional, Any
from sqlalchemy import Engine, inspect
import json
import logging

logger = logging.getLogger(__name__)


class SchemaExplainer:
    """
    Enhances database schema documentation with AI-generated explanations.
    Uses local LLM (Ollama) for on-premises deployments.
    """

    def __init__(
        self,
        engine: Engine,
        ollama_host: str = "http://localhost:11434",
        model: str = "llama3.2",
        temperature: float = 0.3
    ):
        """
        Initialize the schema explainer.

        Args:
            engine: SQLAlchemy engine connected to database
            ollama_host: Ollama server URL (default: http://localhost:11434)
            model: Ollama model name (default: llama3.2)
            temperature: LLM temperature for generation (default: 0.3 for consistent docs)
        """
        self.engine = engine
        self.ollama_host = ollama_host
        self.model = model
        self.temperature = temperature

        try:
            import ollama
            self.ollama_client = ollama.Client(host=ollama_host)
        except ImportError:
            logger.warning("Ollama package not installed. Install with: pip install ollama")
            self.ollama_client = None

    def explain_table(self, table_name: str, columns: List[Dict[str, Any]]) -> Dict[str, str]:
        """
        Generate AI-powered explanation for a database table.

        Args:
            table_name: Name of the table
            columns: List of column dictionaries with name, type, nullable info

        Returns:
            dict: Contains 'table_description', 'purpose', and 'usage_notes'
        """
        if not self.ollama_client:
            return {
                'table_description': f'Table: {table_name}',
                'purpose': 'Ollama not available for AI explanations',
                'usage_notes': 'Install Ollama for enhanced documentation'
            }

        try:
            # Build column information
            col_info = []
            for col in columns:
                col_type = col.get('type', 'unknown')
                nullable = 'nullable' if col.get('nullable', True) else 'required'
                col_info.append(f"  - {col['name']} ({col_type}, {nullable})")

            columns_text = '\n'.join(col_info)

            prompt = f"""Analyze this database table and provide clear, concise documentation.

Table Name: {table_name}

Columns:
{columns_text}

Please provide:
1. A brief description of what this table stores (1-2 sentences)
2. The primary purpose of this table in the database
3. Any important usage notes or relationships

Respond in JSON format:
{{
  "table_description": "Brief description",
  "purpose": "Primary purpose",
  "usage_notes": "Important notes"
}}"""

            response = self.ollama_client.chat(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": "You are a database documentation expert. Provide clear, technical documentation for database schemas."
                    },
                    {"role": "user", "content": prompt}
                ],
                options={
                    "temperature": self.temperature,
                    "num_ctx": 4096
                }
            )

            content = response['message']['content']

            # Parse JSON response
            try:
                if '```json' in content:
                    content = content.split('```json')[1].split('```')[0].strip()
                elif '```' in content:
                    content = content.split('```')[1].split('```')[0].strip()

                result = json.loads(content)
                return {
                    'table_description': result.get('table_description', f'Table: {table_name}'),
                    'purpose': result.get('purpose', 'Data storage'),
                    'usage_notes': result.get('usage_notes', 'No additional notes')
                }

            except json.JSONDecodeError:
                logger.warning(f"Failed to parse JSON for table {table_name}")
                return {
                    'table_description': content.strip()[:200],
                    'purpose': 'See description',
                    'usage_notes': 'N/A'
                }

        except Exception as e:
            logger.error(f"Error explaining table {table_name}: {str(e)}")
            return {
                'table_description': f'Table: {table_name}',
                'purpose': f'Error generating explanation: {str(e)}',
                'usage_notes': 'N/A'
            }

    def explain_column(self, table_name: str, column_name: str, column_type: str) -> str:
        """
        Generate AI-powered explanation for a specific column.

        Args:
            table_name: Name of the table
            column_name: Name of the column
            column_type: Data type of the column

        Returns:
            str: Human-readable explanation of the column
        """
        if not self.ollama_client:
            return f"{column_name}: {column_type}"

        try:
            prompt = f"""Explain what this database column likely stores based on its name and type.
Be concise (1 sentence).

Table: {table_name}
Column: {column_name}
Type: {column_type}

Provide a brief, technical explanation of what data this column stores:"""

            response = self.ollama_client.chat(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": "You are a database expert. Provide brief, technical explanations for database columns."
                    },
                    {"role": "user", "content": prompt}
                ],
                options={
                    "temperature": self.temperature,
                    "num_ctx": 2048
                }
            )

            explanation = response['message']['content'].strip()
            # Keep it concise
            if len(explanation) > 150:
                explanation = explanation[:147] + "..."

            return explanation

        except Exception as e:
            logger.error(f"Error explaining column {table_name}.{column_name}: {str(e)}")
            return f"{column_name} ({column_type})"

    def generate_relationship_explanation(
        self,
        table_name: str,
        foreign_keys: List[Dict[str, Any]]
    ) -> str:
        """
        Generate explanation for table relationships.

        Args:
            table_name: Name of the table
            foreign_keys: List of foreign key relationships

        Returns:
            str: Human-readable explanation of relationships
        """
        if not foreign_keys or not self.ollama_client:
            return "No foreign key relationships"

        try:
            fk_descriptions = []
            for fk in foreign_keys:
                cols = ', '.join(fk.get('constrained_columns', []))
                ref_table = fk.get('referred_table', 'unknown')
                ref_cols = ', '.join(fk.get('referred_columns', []))
                fk_descriptions.append(f"{cols} -> {ref_table}({ref_cols})")

            fk_text = '\n'.join(fk_descriptions)

            prompt = f"""Explain the relationships for this database table in plain English.

Table: {table_name}

Foreign Keys:
{fk_text}

Provide a brief explanation (2-3 sentences) of how this table relates to other tables:"""

            response = self.ollama_client.chat(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": "You are a database expert. Explain table relationships clearly."
                    },
                    {"role": "user", "content": prompt}
                ],
                options={
                    "temperature": self.temperature,
                    "num_ctx": 2048
                }
            )

            return response['message']['content'].strip()

        except Exception as e:
            logger.error(f"Error explaining relationships for {table_name}: {str(e)}")
            return "Error generating relationship explanation"

    def explain_table_with_context(
        self,
        table_name: str,
        columns: List[Dict[str, Any]],
        row_count: int,
        primary_keys: List[str],
        foreign_keys: List[Dict[str, Any]],
        indexes: List[Dict[str, Any]]
    ) -> Dict[str, str]:
        """
        Generate AI-powered explanation for a database table using rich context.
        Uses row counts, constraints, relationships, and indexes for better understanding.

        Args:
            table_name: Name of the table
            columns: List of column dictionaries with name, type, nullable info
            row_count: Number of rows in the table
            primary_keys: List of primary key columns
            foreign_keys: List of foreign key relationships
            indexes: List of indexes on the table

        Returns:
            dict: Contains 'table_description', 'purpose', and 'usage_notes'
        """
        if not self.ollama_client:
            return {
                'table_description': f'Table: {table_name}',
                'purpose': 'Data storage',
                'usage_notes': 'Ollama not available'
            }

        try:
            # Build rich context prompt
            column_list = '\n'.join([
                f"  - {col['name']} ({col['type']}){'  [PK]' if col['name'] in primary_keys else ''}{'  [NULL]' if col.get('nullable') else ''}"
                for col in columns
            ])

            # Build foreign key context
            fk_context = ""
            if foreign_keys:
                fk_list = []
                for fk in foreign_keys:
                    cols = ', '.join(fk.get('constrained_columns', []))
                    ref_table = fk.get('referred_table', 'unknown')
                    ref_cols = ', '.join(fk.get('referred_columns', []))
                    fk_list.append(f"  - {cols} -> {ref_table}({ref_cols})")
                fk_context = "\n\nForeign Keys:\n" + '\n'.join(fk_list)

            # Build index context
            index_context = ""
            if indexes:
                index_list = []
                for idx in indexes:
                    idx_cols = ', '.join(idx.get('columns', []))
                    unique = ' [UNIQUE]' if idx.get('unique') else ''
                    index_list.append(f"  - {idx.get('name', 'unnamed')} on ({idx_cols}){unique}")
                index_context = "\n\nIndexes:\n" + '\n'.join(index_list)

            prompt = f"""Analyze this database table and provide comprehensive documentation.

Table: {table_name}
Row Count: {row_count:,}
Primary Keys: {', '.join(primary_keys) if primary_keys else 'None'}

Columns:
{column_list}{fk_context}{index_context}

Based on the table name, columns, relationships, and constraints, provide:
1. A clear description of what this table stores
2. Its primary purpose in the database
3. Important usage notes (data patterns, business rules, performance considerations)

Respond in JSON format:
{{
  "table_description": "Detailed description of what this table stores and represents",
  "purpose": "Primary business purpose and use cases",
  "usage_notes": "Important notes about constraints, data quality, performance, or business rules"
}}"""

            response = self.ollama_client.chat(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": "You are a database documentation expert. Provide clear, technical documentation based on schema analysis."
                    },
                    {"role": "user", "content": prompt}
                ],
                options={
                    "temperature": self.temperature,
                    "num_ctx": 8192  # Larger context for richer input
                }
            )

            content = response['message']['content']

            # Parse JSON response
            try:
                if '```json' in content:
                    content = content.split('```json')[1].split('```')[0].strip()
                elif '```' in content:
                    content = content.split('```')[1].split('```')[0].strip()

                result = json.loads(content)
                return {
                    'table_description': result.get('table_description', f'Table: {table_name} ({row_count:,} rows)'),
                    'purpose': result.get('purpose', 'Data storage and management'),
                    'usage_notes': result.get('usage_notes', 'No additional notes available')
                }

            except json.JSONDecodeError:
                logger.warning(f"Failed to parse JSON for table {table_name}, using fallback")
                return {
                    'table_description': content.strip()[:300],
                    'purpose': 'See description',
                    'usage_notes': 'N/A'
                }

        except Exception as e:
            logger.error(f"Error explaining table {table_name} with context: {str(e)}")
            return {
                'table_description': f'Table: {table_name} ({row_count:,} rows)',
                'purpose': f'Error generating explanation: {str(e)}',
                'usage_notes': 'N/A'
            }

    def enhance_dictionary(self, dictionary: Dict[str, Any], include_column_descriptions: bool = True) -> Dict[str, Any]:
        """
        Enhance an existing data dictionary with AI-generated explanations.
        Uses profiling data, constraints, relationships, and row counts for rich context.

        Args:
            dictionary: Data dictionary from DictionaryBuilder
            include_column_descriptions: Generate AI descriptions for each column (slower)

        Returns:
            dict: Enhanced dictionary with AI explanations
        """
        if not self.ollama_client:
            logger.warning("Ollama not available, returning original dictionary")
            return dictionary

        enhanced = dictionary.copy()

        if 'tables' not in enhanced:
            return enhanced

        logger.info("Enhancing dictionary with AI explanations...")

        # First, generate database-level summary
        try:
            db_summary = self.generate_database_summary(enhanced)
            enhanced['ai_database_summary'] = db_summary
        except Exception as e:
            logger.error(f"Error generating database summary: {str(e)}")

        for table_name, table_info in enhanced['tables'].items():
            try:
                # Build rich context for table explanation
                columns = table_info.get('columns', [])
                row_count = table_info.get('row_count', 0)
                primary_keys = table_info.get('primary_keys', [])
                foreign_keys = table_info.get('foreign_keys', [])
                indexes = table_info.get('indexes', [])

                # Generate enhanced table explanation with context
                explanation = self.explain_table_with_context(
                    table_name, columns, row_count, primary_keys, foreign_keys, indexes
                )

                # Add to table info
                table_info['ai_description'] = explanation['table_description']
                table_info['ai_purpose'] = explanation['purpose']
                table_info['ai_usage_notes'] = explanation['usage_notes']

                # Generate relationship explanation if foreign keys exist
                if foreign_keys:
                    rel_explanation = self.generate_relationship_explanation(
                        table_name,
                        foreign_keys
                    )
                    table_info['ai_relationships'] = rel_explanation

                # Generate AI descriptions for each column if requested
                if include_column_descriptions:
                    for column in table_info.get('columns', []):
                        try:
                            col_desc = self.explain_column(
                                table_name,
                                column.get('name', ''),
                                column.get('type', '')
                            )
                            column['ai_description'] = col_desc
                        except Exception as e:
                            logger.error(f"Error explaining column {column.get('name')}: {str(e)}")
                            continue

                logger.info(f"Enhanced documentation for table: {table_name}")

            except Exception as e:
                logger.error(f"Error enhancing table {table_name}: {str(e)}")
                continue

        return enhanced

    def is_available(self) -> bool:
        """
        Check if Ollama service is available.

        Returns:
            bool: True if Ollama is available and responsive
        """
        if not self.ollama_client:
            return False

        try:
            self.ollama_client.list()
            return True
        except Exception:
            return False

    def generate_database_summary(self, dictionary: Dict[str, Any]) -> str:
        """
        Generate an overall summary of the database.

        Args:
            dictionary: Complete data dictionary

        Returns:
            str: High-level summary of the database
        """
        if not self.ollama_client:
            return "Database documentation (Ollama not available for AI summary)"

        try:
            tables = dictionary.get('tables', {})
            table_list = list(tables.keys())
            total_tables = len(table_list)

            # Build summary of database
            summary_text = f"Database contains {total_tables} tables:\n"
            for table_name in table_list[:10]:  # Limit to first 10 for context
                table_info = tables[table_name]
                col_count = table_info.get('total_columns', 0)
                summary_text += f"  - {table_name} ({col_count} columns)\n"

            if total_tables > 10:
                summary_text += f"  ... and {total_tables - 10} more tables\n"

            prompt = f"""Provide a high-level summary of this database based on its structure.

{summary_text}

Write a 2-3 sentence summary describing what this database likely manages and its primary purpose:"""

            response = self.ollama_client.chat(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": "You are a database architect. Provide concise, technical summaries."
                    },
                    {"role": "user", "content": prompt}
                ],
                options={
                    "temperature": self.temperature,
                    "num_ctx": 4096
                }
            )

            return response['message']['content'].strip()

        except Exception as e:
            logger.error(f"Error generating database summary: {str(e)}")
            return f"Database with {len(dictionary.get('tables', {}))} tables"