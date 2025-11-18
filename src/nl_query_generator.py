"""
Natural Language Query Generator
Converts natural language questions to SQL queries using local LLM (Ollama)
"""

from typing import Optional, Dict, Any
from sqlalchemy import Engine, inspect, text
import json
import logging

logger = logging.getLogger(__name__)


class NaturalLanguageQueryGenerator:
    """
    Generates SQL queries from natural language using Ollama.
    Designed for on-premises deployment with local LLMs.
    """

    def __init__(
        self,
        engine: Engine,
        ollama_host: str = "http://localhost:11434",
        model: str = "llama3.2",
        temperature: float = 0.1
    ):
        """
        Initialize the natural language query generator.

        Args:
            engine: SQLAlchemy engine connected to database
            ollama_host: Ollama server URL (default: http://localhost:11434)
            model: Ollama model name (default: llama3.2)
            temperature: LLM temperature for generation (default: 0.1 for deterministic SQL)
        """
        self.engine = engine
        self.ollama_host = ollama_host
        self.model = model
        self.temperature = temperature
        self._schema_cache: Optional[str] = None

        try:
            import ollama
            self.ollama_client = ollama.Client(host=ollama_host)
        except ImportError:
            logger.warning("Ollama package not installed. Install with: pip install ollama")
            self.ollama_client = None

    def get_database_schema(self) -> str:
        """
        Extract database schema information for context.

        Returns:
            str: Formatted schema information
        """
        if self._schema_cache:
            return self._schema_cache

        inspector = inspect(self.engine)
        schema_info = []

        for table_name in inspector.get_table_names():
            table_info = [f"\nTable: {table_name}"]

            # Get columns
            columns = inspector.get_columns(table_name)
            table_info.append("Columns:")
            for col in columns:
                col_type = str(col['type'])
                nullable = "NULL" if col['nullable'] else "NOT NULL"
                table_info.append(f"  - {col['name']} ({col_type}) {nullable}")

            # Get primary keys
            pk = inspector.get_pk_constraint(table_name)
            if pk and pk.get('constrained_columns'):
                table_info.append(f"Primary Key: {', '.join(pk['constrained_columns'])}")

            # Get foreign keys
            fks = inspector.get_foreign_keys(table_name)
            if fks:
                table_info.append("Foreign Keys:")
                for fk in fks:
                    cols = ', '.join(fk['constrained_columns'])
                    ref_table = fk['referred_table']
                    ref_cols = ', '.join(fk['referred_columns'])
                    table_info.append(f"  - {cols} -> {ref_table}({ref_cols})")

            schema_info.append('\n'.join(table_info))

        self._schema_cache = '\n'.join(schema_info)
        return self._schema_cache

    def generate_sql(self, question: str) -> Dict[str, Any]:
        """
        Generate SQL query from natural language question.

        Args:
            question: Natural language question

        Returns:
            dict: Contains 'sql', 'explanation', and 'confidence' keys
        """
        if not self.ollama_client:
            return {
                'sql': None,
                'explanation': 'Ollama client not available. Please install: pip install ollama',
                'confidence': 0.0,
                'error': 'Missing dependency'
            }

        try:
            schema = self.get_database_schema()

            system_prompt = """You are an expert SQL query generator. Given a database schema and a natural language question, generate a valid SQL query.

Rules:
1. Generate ONLY valid SQL queries - no explanations in the SQL itself
2. Use proper SQL syntax for the database type
3. Include appropriate JOINs when multiple tables are involved
4. Use meaningful aliases for readability
5. Add LIMIT clauses for safety (default 100 rows)
6. Respond in JSON format with keys: sql, explanation, confidence

Database Schema:
{schema}

Respond ONLY with valid JSON in this exact format:
{{
  "sql": "SELECT ... FROM ... WHERE ...",
  "explanation": "This query does X by joining Y...",
  "confidence": 0.85
}}"""

            prompt = f"Question: {question}\n\nGenerate the SQL query as JSON:"

            response = self.ollama_client.chat(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt.format(schema=schema)},
                    {"role": "user", "content": prompt}
                ],
                options={
                    "temperature": self.temperature,
                    "num_ctx": 8192
                }
            )

            content = response['message']['content']

            # Try to parse JSON response
            try:
                # Extract JSON if wrapped in markdown code blocks
                if '```json' in content:
                    content = content.split('```json')[1].split('```')[0].strip()
                elif '```' in content:
                    content = content.split('```')[1].split('```')[0].strip()

                result = json.loads(content)

                # Validate response structure
                if 'sql' not in result:
                    return {
                        'sql': None,
                        'explanation': 'Invalid response format from LLM',
                        'confidence': 0.0,
                        'error': 'Missing SQL in response'
                    }

                return {
                    'sql': result.get('sql'),
                    'explanation': result.get('explanation', 'No explanation provided'),
                    'confidence': result.get('confidence', 0.7),
                    'error': None
                }

            except json.JSONDecodeError:
                # Fallback: try to extract SQL from response
                logger.warning("Failed to parse JSON response, attempting to extract SQL")
                return {
                    'sql': content.strip(),
                    'explanation': 'SQL extracted from response (JSON parsing failed)',
                    'confidence': 0.5,
                    'error': 'JSON parsing failed'
                }

        except Exception as e:
            logger.error(f"Error generating SQL: {str(e)}")
            return {
                'sql': None,
                'explanation': f'Error: {str(e)}',
                'confidence': 0.0,
                'error': str(e)
            }

    def execute_query(self, sql: str, limit: Optional[int] = 100) -> Dict[str, Any]:
        """
        Execute generated SQL query safely.

        Args:
            sql: SQL query to execute
            limit: Maximum number of rows to return

        Returns:
            dict: Contains 'success', 'data', 'columns', and 'error' keys
        """
        try:
            # Add LIMIT if not present and limit is specified
            sql_lower = sql.lower().strip()
            if limit and 'limit' not in sql_lower:
                sql = f"{sql.rstrip(';')} LIMIT {limit}"

            with self.engine.connect() as conn:
                result = conn.execute(text(sql))

                # Fetch results
                rows = result.fetchall()
                columns = list(result.keys())

                # Convert to list of dicts
                data = [dict(zip(columns, row)) for row in rows]

                return {
                    'success': True,
                    'data': data,
                    'columns': columns,
                    'row_count': len(data),
                    'error': None
                }

        except Exception as e:
            logger.error(f"Error executing query: {str(e)}")
            return {
                'success': False,
                'data': None,
                'columns': None,
                'row_count': 0,
                'error': str(e)
            }

    def ask(self, question: str, execute: bool = True) -> Dict[str, Any]:
        """
        Complete workflow: generate SQL from question and optionally execute it.

        Args:
            question: Natural language question
            execute: Whether to execute the generated SQL (default: True)

        Returns:
            dict: Complete result with SQL, explanation, and data (if executed)
        """
        # Generate SQL
        sql_result = self.generate_sql(question)

        result = {
            'question': question,
            'sql': sql_result.get('sql'),
            'explanation': sql_result.get('explanation'),
            'confidence': sql_result.get('confidence', 0.0),
            'generation_error': sql_result.get('error')
        }

        # Execute if requested and SQL was generated
        if execute and sql_result.get('sql'):
            execution_result = self.execute_query(sql_result['sql'])
            result.update({
                'execution_success': execution_result['success'],
                'data': execution_result.get('data'),
                'columns': execution_result.get('columns'),
                'row_count': execution_result.get('row_count', 0),
                'execution_error': execution_result.get('error')
            })
        else:
            result.update({
                'execution_success': None,
                'data': None,
                'columns': None,
                'row_count': 0,
                'execution_error': None
            })

        return result

    def is_available(self) -> bool:
        """
        Check if Ollama service is available.

        Returns:
            bool: True if Ollama is available and responsive
        """
        if not self.ollama_client:
            return False

        try:
            # Try to list models as health check
            self.ollama_client.list()
            return True
        except Exception:
            return False