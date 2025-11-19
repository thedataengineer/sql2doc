"""
E2E Tests for AI-Enhanced Documentation Features
Tests SchemaExplainer and NaturalLanguageQueryGenerator
"""

import pytest
from unittest.mock import MagicMock, patch
from sqlalchemy import create_engine, Column, Integer, String, ForeignKey, MetaData, Table
import json
import sys
from pathlib import Path

# Add src directory to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))

from src.schema_explainer import SchemaExplainer
from src.nl_query_generator import NaturalLanguageQueryGenerator
from src.database_connector import DatabaseConnector
from src.schema_fetcher import SchemaFetcher
from src.dictionary_builder import DictionaryBuilder


class TestSchemaExplainer:
    """Test suite for AI-powered schema documentation."""

    @pytest.fixture
    def test_engine(self, tmp_path):
        """Create in-memory SQLite test database."""
        db_file = tmp_path / "test.db"
        engine = create_engine(f"sqlite:///{db_file}")
        
        # Create test schema
        metadata = MetaData()
        
        users_table = Table(
            'users',
            metadata,
            Column('id', Integer, primary_key=True),
            Column('name', String(100)),
            Column('email', String(100)),
        )
        
        orders_table = Table(
            'orders',
            metadata,
            Column('id', Integer, primary_key=True),
            Column('user_id', Integer, ForeignKey('users.id')),
            Column('total', Integer),
        )
        
        metadata.create_all(engine)
        
        # Insert test data
        with engine.connect() as conn:
            conn.execute(users_table.insert().values(
                id=1, name='Alice', email='alice@example.com'
            ))
            conn.execute(orders_table.insert().values(
                id=1, user_id=1, total=100
            ))
            conn.commit()
        
        yield engine
        engine.dispose()

    def test_init(self, test_engine):
        """Test SchemaExplainer initialization."""
        explainer = SchemaExplainer(test_engine)
        assert explainer.engine == test_engine
        assert explainer.ollama_host == "http://localhost:11434"
        assert explainer.model == "llama3.2"
        assert explainer.temperature == 0.3

    def test_explain_table_without_ollama(self, test_engine):
        """Test table explanation when Ollama is not available."""
        explainer = SchemaExplainer(test_engine)
        explainer.ollama_client = None
        
        columns = [
            {'name': 'id', 'type': 'INTEGER', 'nullable': False},
            {'name': 'name', 'type': 'VARCHAR', 'nullable': True},
        ]
        
        result = explainer.explain_table('users', columns)
        
        assert 'table_description' in result
        assert 'purpose' in result
        assert 'usage_notes' in result
        assert result['table_description'] == 'Table: users'
        assert 'Ollama not available' in result['purpose']

    def test_explain_table_with_ollama_mock(self, test_engine):
        """Test table explanation with mocked Ollama response."""
        mock_client = MagicMock()
        mock_response = {
            'message': {
                'content': json.dumps({
                    'table_description': 'Stores user information',
                    'purpose': 'User management',
                    'usage_notes': 'Primary user table'
                })
            }
        }
        mock_client.chat.return_value = mock_response
        
        explainer = SchemaExplainer(test_engine)
        explainer.ollama_client = mock_client
        
        columns = [
            {'name': 'id', 'type': 'INTEGER', 'nullable': False},
            {'name': 'name', 'type': 'VARCHAR', 'nullable': True},
        ]
        
        result = explainer.explain_table('users', columns)
        
        assert result['table_description'] == 'Stores user information'
        assert result['purpose'] == 'User management'
        assert result['usage_notes'] == 'Primary user table'
        mock_client.chat.assert_called_once()

    def test_explain_column_without_ollama(self, test_engine):
        """Test column explanation when Ollama is not available."""
        explainer = SchemaExplainer(test_engine)
        explainer.ollama_client = None
        
        result = explainer.explain_column('users', 'email', 'VARCHAR')
        
        assert result == 'email: VARCHAR'

    def test_explain_column_with_ollama_mock(self, test_engine):
        """Test column explanation with mocked Ollama response."""
        mock_client = MagicMock()
        mock_response = {
            'message': {
                'content': 'Email address of the user for contact and identification purposes.'
            }
        }
        mock_client.chat.return_value = mock_response
        
        explainer = SchemaExplainer(test_engine)
        explainer.ollama_client = mock_client
        
        result = explainer.explain_column('users', 'email', 'VARCHAR')
        
        assert 'email' in result.lower() or 'contact' in result.lower()
        mock_client.chat.assert_called_once()

    def test_generate_relationship_explanation_without_ollama(self, test_engine):
        """Test relationship explanation without Ollama."""
        explainer = SchemaExplainer(test_engine)
        explainer.ollama_client = None
        
        foreign_keys = [
            {
                'constrained_columns': ['user_id'],
                'referred_table': 'users',
                'referred_columns': ['id']
            }
        ]
        
        result = explainer.generate_relationship_explanation('orders', foreign_keys)
        
        assert result == 'No foreign key relationships'

    def test_generate_relationship_explanation_with_ollama_mock(self, test_engine):
        """Test relationship explanation with mocked Ollama response."""
        mock_client = MagicMock()
        mock_response = {
            'message': {
                'content': 'Orders table references the users table through the user_id foreign key. This establishes a one-to-many relationship where each user can have multiple orders.'
            }
        }
        mock_client.chat.return_value = mock_response
        
        explainer = SchemaExplainer(test_engine)
        explainer.ollama_client = mock_client
        
        foreign_keys = [
            {
                'constrained_columns': ['user_id'],
                'referred_table': 'users',
                'referred_columns': ['id']
            }
        ]
        
        result = explainer.generate_relationship_explanation('orders', foreign_keys)
        
        assert 'user' in result.lower() or 'relationship' in result.lower()
        mock_client.chat.assert_called_once()

    def test_explain_table_with_context_without_ollama(self, test_engine):
        """Test contextual table explanation without Ollama."""
        explainer = SchemaExplainer(test_engine)
        explainer.ollama_client = None
        
        columns = [
            {'name': 'id', 'type': 'INTEGER', 'nullable': False},
            {'name': 'name', 'type': 'VARCHAR', 'nullable': True},
        ]
        
        result = explainer.explain_table_with_context(
            'users', columns, row_count=100,
            primary_keys=['id'], foreign_keys=[], indexes=[]
        )
        
        assert 'table_description' in result
        assert 'purpose' in result
        assert 'usage_notes' in result

    def test_explain_table_with_context_with_ollama_mock(self, test_engine):
        """Test contextual table explanation with mocked Ollama response."""
        mock_client = MagicMock()
        mock_response = {
            'message': {
                'content': json.dumps({
                    'table_description': 'Core user data table storing 100 active users',
                    'purpose': 'Central user management and authentication',
                    'usage_notes': 'Indexed on id (primary key), contains encrypted sensitive data'
                })
            }
        }
        mock_client.chat.return_value = mock_response
        
        explainer = SchemaExplainer(test_engine)
        explainer.ollama_client = mock_client
        
        columns = [
            {'name': 'id', 'type': 'INTEGER', 'nullable': False},
            {'name': 'name', 'type': 'VARCHAR', 'nullable': True},
        ]
        
        result = explainer.explain_table_with_context(
            'users', columns, row_count=100,
            primary_keys=['id'], foreign_keys=[], indexes=[]
        )
        
        assert 'user' in result['table_description'].lower()
        assert '100' in str(mock_client.chat.call_args)

    def test_enhance_dictionary_without_ollama(self, test_engine):
        """Test dictionary enhancement without Ollama."""
        explainer = SchemaExplainer(test_engine)
        explainer.ollama_client = None
        
        test_dict = {
            'tables': {
                'users': {
                    'columns': [
                        {'name': 'id', 'type': 'INTEGER'},
                        {'name': 'name', 'type': 'VARCHAR'}
                    ],
                    'row_count': 10,
                    'primary_keys': ['id'],
                    'foreign_keys': [],
                    'indexes': []
                }
            }
        }
        
        result = explainer.enhance_dictionary(test_dict)
        
        assert 'tables' in result
        assert 'users' in result['tables']

    def test_enhance_dictionary_with_ollama_mock(self, test_engine):
        """Test dictionary enhancement with mocked Ollama response."""
        mock_client = MagicMock()
        
        # Mock responses for different calls
        mock_responses = [
            # Database summary
            {'message': {'content': 'This is a user management system'}},
            # Table explanation
            {'message': {'content': json.dumps({
                'table_description': 'Stores user information',
                'purpose': 'User management',
                'usage_notes': 'Primary user table'
            })}}
        ]
        
        mock_client.chat.side_effect = mock_responses
        
        explainer = SchemaExplainer(test_engine)
        explainer.ollama_client = mock_client
        
        test_dict = {
            'tables': {
                'users': {
                    'columns': [
                        {'name': 'id', 'type': 'INTEGER'},
                        {'name': 'name', 'type': 'VARCHAR'}
                    ],
                    'row_count': 10,
                    'primary_keys': ['id'],
                    'foreign_keys': [],
                    'indexes': []
                }
            }
        }
        
        result = explainer.enhance_dictionary(test_dict, include_column_descriptions=False)
        
        assert 'tables' in result
        assert 'users' in result['tables']

    def test_is_available_with_ollama(self, test_engine):
        """Test availability check when Ollama is available."""
        mock_client = MagicMock()
        mock_client.list.return_value = {'models': []}
        
        explainer = SchemaExplainer(test_engine)
        explainer.ollama_client = mock_client
        
        assert explainer.is_available() is True

    def test_is_available_without_ollama(self, test_engine):
        """Test availability check when Ollama is not available."""
        explainer = SchemaExplainer(test_engine)
        explainer.ollama_client = None
        
        assert explainer.is_available() is False

    def test_is_available_with_connection_error(self, test_engine):
        """Test availability check when Ollama connection fails."""
        mock_client = MagicMock()
        mock_client.list.side_effect = Exception("Connection refused")
        
        explainer = SchemaExplainer(test_engine)
        explainer.ollama_client = mock_client
        
        assert explainer.is_available() is False

    def test_generate_database_summary_without_ollama(self, test_engine):
        """Test database summary generation without Ollama."""
        explainer = SchemaExplainer(test_engine)
        explainer.ollama_client = None
        
        test_dict = {
            'tables': {
                'users': {'total_columns': 3},
                'orders': {'total_columns': 3}
            }
        }
        
        result = explainer.generate_database_summary(test_dict)
        
        assert 'Ollama not available' in result or 'documentation' in result.lower()

    def test_generate_database_summary_with_ollama_mock(self, test_engine):
        """Test database summary generation with mocked Ollama response."""
        mock_client = MagicMock()
        mock_response = {
            'message': {
                'content': 'This database manages user accounts and their orders.'
            }
        }
        mock_client.chat.return_value = mock_response
        
        explainer = SchemaExplainer(test_engine)
        explainer.ollama_client = mock_client
        
        test_dict = {
            'tables': {
                'users': {'total_columns': 3},
                'orders': {'total_columns': 3}
            }
        }
        
        result = explainer.generate_database_summary(test_dict)
        
        assert len(result) > 0
        mock_client.chat.assert_called_once()


class TestNaturalLanguageQueryGenerator:
    """Test suite for AI-powered natural language query generation."""

    @pytest.fixture
    def test_engine(self, tmp_path):
        """Create in-memory SQLite test database."""
        db_file = tmp_path / "test.db"
        engine = create_engine(f"sqlite:///{db_file}")
        
        metadata = MetaData()
        
        users_table = Table(
            'users',
            metadata,
            Column('id', Integer, primary_key=True),
            Column('name', String(100)),
            Column('email', String(100)),
        )
        
        orders_table = Table(
            'orders',
            metadata,
            Column('id', Integer, primary_key=True),
            Column('user_id', Integer, ForeignKey('users.id')),
            Column('total', Integer),
        )
        
        metadata.create_all(engine)
        
        with engine.connect() as conn:
            conn.execute(users_table.insert().values(
                id=1, name='Alice', email='alice@example.com'
            ))
            conn.execute(users_table.insert().values(
                id=2, name='Bob', email='bob@example.com'
            ))
            conn.execute(orders_table.insert().values(
                id=1, user_id=1, total=100
            ))
            conn.execute(orders_table.insert().values(
                id=2, user_id=2, total=200
            ))
            conn.commit()
        
        yield engine
        engine.dispose()

    def test_init(self, test_engine):
        """Test NaturalLanguageQueryGenerator initialization."""
        generator = NaturalLanguageQueryGenerator(test_engine)
        assert generator.engine == test_engine
        assert generator.ollama_host == "http://localhost:11434"
        assert generator.model == "llama3.2"
        assert generator.temperature == 0.1

    def test_get_database_schema(self, test_engine):
        """Test database schema extraction."""
        generator = NaturalLanguageQueryGenerator(test_engine)
        schema = generator.get_database_schema()
        
        assert 'users' in schema
        assert 'orders' in schema
        assert 'id' in schema
        assert 'name' in schema

    def test_get_database_schema_caching(self, test_engine):
        """Test schema caching mechanism."""
        generator = NaturalLanguageQueryGenerator(test_engine)
        
        schema1 = generator.get_database_schema()
        schema2 = generator.get_database_schema()
        
        assert schema1 == schema2
        assert generator._schema_cache is not None

    def test_generate_sql_without_ollama(self, test_engine):
        """Test SQL generation when Ollama is not available."""
        generator = NaturalLanguageQueryGenerator(test_engine)
        generator.ollama_client = None
        
        result = generator.generate_sql("Show all users")
        
        assert result['sql'] is None
        assert result['confidence'] == 0.0
        assert 'Ollama client not available' in result['explanation']

    def test_generate_sql_with_ollama_mock(self, test_engine):
        """Test SQL generation with mocked Ollama response."""
        mock_client = MagicMock()
        mock_response = {
            'message': {
                'content': json.dumps({
                    'sql': 'SELECT * FROM users LIMIT 100',
                    'explanation': 'Fetches all user records',
                    'confidence': 0.95
                })
            }
        }
        mock_client.chat.return_value = mock_response
        
        generator = NaturalLanguageQueryGenerator(test_engine)
        generator.ollama_client = mock_client
        
        result = generator.generate_sql("Show all users")
        
        assert result['sql'] == 'SELECT * FROM users LIMIT 100'
        assert result['explanation'] == 'Fetches all user records'
        assert result['confidence'] == 0.95
        mock_client.chat.assert_called_once()

    def test_execute_query_success(self, test_engine):
        """Test successful query execution."""
        generator = NaturalLanguageQueryGenerator(test_engine)
        
        result = generator.execute_query('SELECT * FROM users')
        
        assert result['success'] is True
        assert len(result['data']) == 2
        assert 'id' in result['columns']
        assert result['row_count'] == 2

    def test_execute_query_with_limit(self, test_engine):
        """Test query execution with limit clause."""
        generator = NaturalLanguageQueryGenerator(test_engine)
        
        result = generator.execute_query('SELECT * FROM users', limit=1)
        
        assert result['success'] is True
        assert result['row_count'] <= 1

    def test_execute_query_with_existing_limit(self, test_engine):
        """Test query execution when limit already exists."""
        generator = NaturalLanguageQueryGenerator(test_engine)
        
        result = generator.execute_query('SELECT * FROM users LIMIT 1')
        
        assert result['success'] is True
        assert result['row_count'] == 1

    def test_execute_query_failure(self, test_engine):
        """Test query execution with invalid SQL."""
        generator = NaturalLanguageQueryGenerator(test_engine)
        
        result = generator.execute_query('SELECT * FROM nonexistent_table')
        
        assert result['success'] is False
        assert result['data'] is None
        assert result['error'] is not None

    def test_ask_with_execution(self, test_engine):
        """Test complete workflow with SQL execution."""
        mock_client = MagicMock()
        mock_response = {
            'message': {
                'content': json.dumps({
                    'sql': 'SELECT * FROM users WHERE id = 1',
                    'explanation': 'Get user with id 1',
                    'confidence': 0.9
                })
            }
        }
        mock_client.chat.return_value = mock_response
        
        generator = NaturalLanguageQueryGenerator(test_engine)
        generator.ollama_client = mock_client
        
        result = generator.ask("Get user with id 1", execute=True)
        
        assert result['sql'] == 'SELECT * FROM users WHERE id = 1'
        assert result['execution_success'] is True
        assert result['row_count'] == 1
        assert result['data'] is not None

    def test_ask_without_execution(self, test_engine):
        """Test workflow without SQL execution."""
        mock_client = MagicMock()
        mock_response = {
            'message': {
                'content': json.dumps({
                    'sql': 'SELECT * FROM users',
                    'explanation': 'Get all users',
                    'confidence': 0.9
                })
            }
        }
        mock_client.chat.return_value = mock_response
        
        generator = NaturalLanguageQueryGenerator(test_engine)
        generator.ollama_client = mock_client
        
        result = generator.ask("Show all users", execute=False)
        
        assert result['sql'] == 'SELECT * FROM users'
        assert result['execution_success'] is None
        assert result['data'] is None

    def test_ask_with_invalid_sql(self, test_engine):
        """Test workflow with invalid SQL generation."""
        mock_client = MagicMock()
        mock_response = {
            'message': {
                'content': json.dumps({
                    'sql': 'SELECT * FROM nonexistent_table',
                    'explanation': 'This query will fail',
                    'confidence': 0.2
                })
            }
        }
        mock_client.chat.return_value = mock_response
        
        generator = NaturalLanguageQueryGenerator(test_engine)
        generator.ollama_client = mock_client
        
        result = generator.ask("Show nonexistent data", execute=True)
        
        assert result['sql'] == 'SELECT * FROM nonexistent_table'
        assert result['execution_success'] is False
        assert result['data'] is None

    def test_is_available_with_ollama(self, test_engine):
        """Test availability check when Ollama is available."""
        mock_client = MagicMock()
        mock_client.list.return_value = {'models': []}
        
        generator = NaturalLanguageQueryGenerator(test_engine)
        generator.ollama_client = mock_client
        
        assert generator.is_available() is True

    def test_is_available_without_ollama(self, test_engine):
        """Test availability check when Ollama is not available."""
        generator = NaturalLanguageQueryGenerator(test_engine)
        generator.ollama_client = None
        
        assert generator.is_available() is False

    def test_is_available_with_connection_error(self, test_engine):
        """Test availability check when Ollama connection fails."""
        mock_client = MagicMock()
        mock_client.list.side_effect = Exception("Connection refused")
        
        generator = NaturalLanguageQueryGenerator(test_engine)
        generator.ollama_client = mock_client
        
        assert generator.is_available() is False


class TestAIDocumentationIntegration:
    """Integration tests for AI documentation features."""

    @pytest.fixture
    def test_engine(self, tmp_path):
        """Create in-memory SQLite test database."""
        db_file = tmp_path / "test.db"
        engine = create_engine(f"sqlite:///{db_file}")
        
        metadata = MetaData()
        
        Table(
            'users',
            metadata,
            Column('id', Integer, primary_key=True),
            Column('name', String(100)),
            Column('email', String(100)),
        )
        
        Table(
            'orders',
            metadata,
            Column('id', Integer, primary_key=True),
            Column('user_id', Integer, ForeignKey('users.id')),
            Column('total', Integer),
        )
        
        metadata.create_all(engine)
        
        yield engine
        engine.dispose()

    def test_full_documentation_workflow(self, test_engine):
        """Test complete documentation enhancement workflow."""
        # Generate base dictionary
        builder = DictionaryBuilder(test_engine)
        base_dict = builder.build_full_dictionary(include_row_counts=False)
        
        assert 'tables' in base_dict
        assert 'users' in base_dict['tables']
        assert 'orders' in base_dict['tables']
        
        # Mock AI enhancement
        mock_client = MagicMock()
        mock_responses = [
            {'message': {'content': 'E-commerce database'}},  # DB summary
            {'message': {'content': json.dumps({
                'table_description': 'User data',
                'purpose': 'User management',
                'usage_notes': 'Primary table'
            })}},
            {'message': {'content': json.dumps({
                'table_description': 'Order data',
                'purpose': 'Order tracking',
                'usage_notes': 'Secondary table'
            })}}
        ]
        mock_client.chat.side_effect = mock_responses
        
        # Enhance dictionary with AI
        explainer = SchemaExplainer(test_engine)
        explainer.ollama_client = mock_client
        enhanced_dict = explainer.enhance_dictionary(base_dict, include_column_descriptions=False)
        
        assert 'tables' in enhanced_dict
        # Check if AI fields were added (if ollama was available in mock)
        assert enhanced_dict is not None

    def test_sql_generation_and_execution(self, test_engine):
        """Test SQL generation and execution workflow."""
        # Insert test data
        with test_engine.connect() as conn:
            from sqlalchemy import text
            conn.execute(text('INSERT INTO users (id, name, email) VALUES (1, "John", "john@example.com")'))
            conn.execute(text('INSERT INTO orders (id, user_id, total) VALUES (1, 1, 100)'))
            conn.commit()
        
        # Mock SQL generation
        mock_client = MagicMock()
        mock_response = {
            'message': {
                'content': json.dumps({
                    'sql': 'SELECT u.name, COUNT(o.id) as order_count FROM users u LEFT JOIN orders o ON u.id = o.user_id GROUP BY u.id',
                    'explanation': 'Count orders per user',
                    'confidence': 0.9
                })
            }
        }
        mock_client.chat.return_value = mock_response
        
        # Generate and execute
        generator = NaturalLanguageQueryGenerator(test_engine)
        generator.ollama_client = mock_client
        
        result = generator.ask("How many orders does each user have?", execute=True)
        
        assert result['sql'] is not None
        assert result['execution_success'] is True
        assert result['row_count'] >= 0
