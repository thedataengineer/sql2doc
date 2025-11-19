"""
E2E Tests for AI-Enhanced Documentation Features with Real Ollama
Tests SchemaExplainer and NaturalLanguageQueryGenerator with actual Ollama service
"""

import pytest
import requests
from sqlalchemy import create_engine, Column, Integer, String, ForeignKey, MetaData, Table, text
import sys
from pathlib import Path

# Add src directory to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))

from src.schema_explainer import SchemaExplainer
from src.nl_query_generator import NaturalLanguageQueryGenerator
from src.dictionary_builder import DictionaryBuilder


def is_ollama_available(host: str = "http://localhost:11434") -> bool:
    """Check if Ollama service is available."""
    try:
        response = requests.get(f"{host}/api/tags", timeout=2)
        return response.status_code == 200
    except (requests.ConnectionError, requests.Timeout):
        return False


def is_model_available(model: str = "llama3.2", host: str = "http://localhost:11434") -> bool:
    """Check if specific model is available in Ollama."""
    try:
        response = requests.get(f"{host}/api/tags", timeout=2)
        if response.status_code != 200:
            return False
        data = response.json()
        models = data.get('models', [])
        return any(m.get('name', '').startswith(model) for m in models)
    except Exception:
        return False


# Fixture to skip tests if Ollama is not available
ollama_available = pytest.mark.skipif(
    not is_ollama_available(),
    reason="Ollama service not available at http://localhost:11434"
)

model_available = pytest.mark.skipif(
    not is_model_available("llama3.2"),
    reason="llama3.2 model not available in Ollama. Run: ollama pull llama3.2"
)


class TestSchemaExplainerWithRealOllama:
    """Test suite for AI-powered schema documentation with real Ollama."""

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
            Column('age', Integer),
        )
        
        orders_table = Table(
            'orders',
            metadata,
            Column('id', Integer, primary_key=True),
            Column('user_id', Integer, ForeignKey('users.id')),
            Column('total', Integer),
            Column('status', String(50)),
        )
        
        metadata.create_all(engine)
        
        # Insert test data
        with engine.connect() as conn:
            conn.execute(users_table.insert().values([
                {'id': 1, 'name': 'Alice Johnson', 'email': 'alice@example.com', 'age': 28},
                {'id': 2, 'name': 'Bob Smith', 'email': 'bob@example.com', 'age': 35},
                {'id': 3, 'name': 'Carol White', 'email': 'carol@example.com', 'age': 42},
            ]))
            conn.execute(orders_table.insert().values([
                {'id': 1, 'user_id': 1, 'total': 100, 'status': 'completed'},
                {'id': 2, 'user_id': 1, 'total': 250, 'status': 'completed'},
                {'id': 3, 'user_id': 2, 'total': 500, 'status': 'pending'},
                {'id': 4, 'user_id': 3, 'total': 75, 'status': 'completed'},
            ]))
            conn.commit()
        
        yield engine
        engine.dispose()

    @ollama_available
    @model_available
    def test_explain_table_real_ollama(self, test_engine):
        """Test table explanation with real Ollama."""
        explainer = SchemaExplainer(test_engine)
        
        assert explainer.is_available(), "Ollama should be available"
        
        columns = [
            {'name': 'id', 'type': 'INTEGER', 'nullable': False},
            {'name': 'name', 'type': 'VARCHAR', 'nullable': True},
            {'name': 'email', 'type': 'VARCHAR', 'nullable': True},
            {'name': 'age', 'type': 'INTEGER', 'nullable': True},
        ]
        
        result = explainer.explain_table('users', columns)
        
        assert 'table_description' in result
        assert 'purpose' in result
        assert 'usage_notes' in result
        assert len(result['table_description']) > 0
        assert len(result['purpose']) > 0

    @ollama_available
    @model_available
    def test_explain_column_real_ollama(self, test_engine):
        """Test column explanation with real Ollama."""
        explainer = SchemaExplainer(test_engine)
        
        assert explainer.is_available(), "Ollama should be available"
        
        result = explainer.explain_column('users', 'email', 'VARCHAR')
        
        assert isinstance(result, str)
        assert len(result) > 0
        # Should mention email or contact or similar
        assert any(word in result.lower() for word in ['email', 'contact', 'address', 'user'])

    @ollama_available
    @model_available
    def test_explain_table_with_context_real_ollama(self, test_engine):
        """Test contextual table explanation with real Ollama."""
        explainer = SchemaExplainer(test_engine)
        
        assert explainer.is_available(), "Ollama should be available"
        
        columns = [
            {'name': 'id', 'type': 'INTEGER', 'nullable': False},
            {'name': 'user_id', 'type': 'INTEGER', 'nullable': False},
            {'name': 'total', 'type': 'INTEGER', 'nullable': True},
            {'name': 'status', 'type': 'VARCHAR', 'nullable': True},
        ]
        
        foreign_keys = [
            {
                'constrained_columns': ['user_id'],
                'referred_table': 'users',
                'referred_columns': ['id']
            }
        ]
        
        result = explainer.explain_table_with_context(
            'orders', columns, row_count=4,
            primary_keys=['id'], foreign_keys=foreign_keys, indexes=[]
        )
        
        assert 'table_description' in result
        assert 'purpose' in result
        assert 'usage_notes' in result
        assert len(result['table_description']) > 0

    @ollama_available
    @model_available
    def test_generate_relationship_explanation_real_ollama(self, test_engine):
        """Test relationship explanation with real Ollama."""
        explainer = SchemaExplainer(test_engine)
        
        assert explainer.is_available(), "Ollama should be available"
        
        foreign_keys = [
            {
                'constrained_columns': ['user_id'],
                'referred_table': 'users',
                'referred_columns': ['id']
            }
        ]
        
        result = explainer.generate_relationship_explanation('orders', foreign_keys)
        
        assert isinstance(result, str)
        assert len(result) > 0
        # Should mention users or relationship
        assert any(word in result.lower() for word in ['user', 'relationship', 'refer', 'link', 'relation'])

    @ollama_available
    @model_available
    def test_generate_database_summary_real_ollama(self, test_engine):
        """Test database summary generation with real Ollama."""
        explainer = SchemaExplainer(test_engine)
        
        assert explainer.is_available(), "Ollama should be available"
        
        test_dict = {
            'tables': {
                'users': {
                    'total_columns': 4,
                    'row_count': 3,
                },
                'orders': {
                    'total_columns': 4,
                    'row_count': 4,
                }
            }
        }
        
        result = explainer.generate_database_summary(test_dict)
        
        assert isinstance(result, str)
        assert len(result) > 0

    @ollama_available
    @model_available
    def test_enhance_dictionary_real_ollama(self, test_engine):
        """Test dictionary enhancement with real Ollama."""
        # Generate base dictionary
        builder = DictionaryBuilder(test_engine)
        base_dict = builder.build_full_dictionary(include_row_counts=False)
        
        assert 'tables' in base_dict
        assert 'users' in base_dict['tables']
        assert 'orders' in base_dict['tables']
        
        # Enhance with AI
        explainer = SchemaExplainer(test_engine)
        assert explainer.is_available(), "Ollama should be available"
        
        enhanced_dict = explainer.enhance_dictionary(base_dict, include_column_descriptions=False)
        
        assert 'tables' in enhanced_dict
        assert 'users' in enhanced_dict['tables']
        
        # Check if AI fields were added
        users_table = enhanced_dict['tables']['users']
        assert 'ai_description' in users_table
        assert 'ai_purpose' in users_table
        assert 'ai_usage_notes' in users_table
        assert len(users_table['ai_description']) > 0

    @ollama_available
    @model_available
    def test_enhance_dictionary_with_column_descriptions_real_ollama(self, test_engine):
        """Test dictionary enhancement with column descriptions using real Ollama."""
        builder = DictionaryBuilder(test_engine)
        base_dict = builder.build_full_dictionary(include_row_counts=False)
        
        explainer = SchemaExplainer(test_engine)
        assert explainer.is_available(), "Ollama should be available"
        
        enhanced_dict = explainer.enhance_dictionary(base_dict, include_column_descriptions=True)
        
        assert 'tables' in enhanced_dict
        users_table = enhanced_dict['tables']['users']
        
        # Check if column descriptions were added
        has_column_descriptions = False
        for column in users_table.get('columns', []):
            if 'ai_description' in column:
                has_column_descriptions = True
                assert len(column['ai_description']) > 0
                break
        
        # At least some columns should have AI descriptions
        assert has_column_descriptions, "At least one column should have AI description"


class TestNaturalLanguageQueryGeneratorWithRealOllama:
    """Test suite for AI-powered NL query generation with real Ollama."""

    @pytest.fixture
    def test_engine(self, tmp_path):
        """Create in-memory SQLite test database with sample data."""
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
            conn.execute(users_table.insert().values([
                {'id': 1, 'name': 'Alice', 'email': 'alice@example.com'},
                {'id': 2, 'name': 'Bob', 'email': 'bob@example.com'},
                {'id': 3, 'name': 'Carol', 'email': 'carol@example.com'},
            ]))
            conn.execute(orders_table.insert().values([
                {'id': 1, 'user_id': 1, 'total': 100},
                {'id': 2, 'user_id': 1, 'total': 250},
                {'id': 3, 'user_id': 2, 'total': 500},
            ]))
            conn.commit()
        
        yield engine
        engine.dispose()

    @ollama_available
    @model_available
    def test_get_database_schema_real_ollama(self, test_engine):
        """Test database schema extraction."""
        generator = NaturalLanguageQueryGenerator(test_engine)
        assert generator.is_available(), "Ollama should be available"
        
        schema = generator.get_database_schema()
        
        assert 'users' in schema
        assert 'orders' in schema
        assert 'id' in schema
        assert 'name' in schema
        assert 'user_id' in schema

    @ollama_available
    @model_available
    def test_generate_sql_from_question_real_ollama(self, test_engine):
        """Test SQL generation from natural language question."""
        generator = NaturalLanguageQueryGenerator(test_engine)
        assert generator.is_available(), "Ollama should be available"
        
        result = generator.generate_sql("Show all users")
        
        assert 'sql' in result
        assert result['sql'] is not None
        assert len(result['sql']) > 0
        assert 'explanation' in result
        assert 'confidence' in result
        # Should be valid SQL-like
        assert 'select' in result['sql'].lower() or 'SELECT' in result['sql']

    @ollama_available
    @model_available
    def test_generate_join_query_real_ollama(self, test_engine):
        """Test SQL generation for join query."""
        generator = NaturalLanguageQueryGenerator(test_engine)
        assert generator.is_available(), "Ollama should be available"
        
        result = generator.generate_sql("Show users and their orders")
        
        assert result['sql'] is not None
        assert len(result['sql']) > 0
        sql_lower = result['sql'].lower()
        # Should either have JOIN or multiple tables
        assert 'join' in sql_lower or 'users' in sql_lower

    @ollama_available
    @model_available
    def test_execute_generated_sql_real_ollama(self, test_engine):
        """Test executing SQL generated from natural language."""
        generator = NaturalLanguageQueryGenerator(test_engine)
        assert generator.is_available(), "Ollama should be available"
        
        result = generator.generate_sql("Get all users with their email")
        
        if result['sql']:
            execution_result = generator.execute_query(result['sql'])
            
            assert execution_result['success'] is True
            assert execution_result['data'] is not None
            assert execution_result['row_count'] >= 0

    @ollama_available
    @model_available
    def test_ask_simple_question_real_ollama(self, test_engine):
        """Test complete workflow: ask -> generate -> execute."""
        generator = NaturalLanguageQueryGenerator(test_engine)
        assert generator.is_available(), "Ollama should be available"
        
        result = generator.ask("How many users do we have?", execute=True)
        
        assert result['sql'] is not None
        assert result['execution_success'] is True
        assert result['data'] is not None

    @ollama_available
    @model_available
    def test_ask_aggregation_question_real_ollama(self, test_engine):
        """Test aggregate query generation."""
        generator = NaturalLanguageQueryGenerator(test_engine)
        assert generator.is_available(), "Ollama should be available"
        
        result = generator.ask("What is the total value of all orders?", execute=True)
        
        assert result['sql'] is not None
        assert result['execution_success'] is True
        assert result['data'] is not None

    @ollama_available
    @model_available
    def test_ask_without_execution_real_ollama(self, test_engine):
        """Test SQL generation without execution."""
        generator = NaturalLanguageQueryGenerator(test_engine)
        assert generator.is_available(), "Ollama should be available"
        
        result = generator.ask("List users and their email addresses", execute=False)
        
        assert result['sql'] is not None
        assert result['execution_success'] is None
        assert result['data'] is None


class TestAIDocumentationIntegrationWithRealOllama:
    """Integration tests with real Ollama service."""

    @pytest.fixture
    def test_engine(self, tmp_path):
        """Create comprehensive test database."""
        db_file = tmp_path / "test.db"
        engine = create_engine(f"sqlite:///{db_file}")
        
        metadata = MetaData()
        
        Table(
            'users',
            metadata,
            Column('id', Integer, primary_key=True),
            Column('name', String(100)),
            Column('email', String(100)),
            Column('created_at', String(50)),
        )
        
        Table(
            'orders',
            metadata,
            Column('id', Integer, primary_key=True),
            Column('user_id', Integer, ForeignKey('users.id')),
            Column('amount', Integer),
            Column('status', String(50)),
        )
        
        Table(
            'products',
            metadata,
            Column('id', Integer, primary_key=True),
            Column('name', String(100)),
            Column('price', Integer),
        )
        
        metadata.create_all(engine)
        
        # Insert test data
        with engine.connect() as conn:
            conn.execute(text('''
                INSERT INTO users (id, name, email, created_at) VALUES 
                (1, 'John Doe', 'john@example.com', '2024-01-01'),
                (2, 'Jane Smith', 'jane@example.com', '2024-01-15')
            '''))
            conn.execute(text('''
                INSERT INTO orders (id, user_id, amount, status) VALUES 
                (1, 1, 100, 'completed'),
                (2, 1, 250, 'completed'),
                (3, 2, 500, 'pending')
            '''))
            conn.execute(text('''
                INSERT INTO products (id, name, price) VALUES 
                (1, 'Widget', 50),
                (2, 'Gadget', 75)
            '''))
            conn.commit()
        
        yield engine
        engine.dispose()

    @ollama_available
    @model_available
    def test_full_e2e_workflow_real_ollama(self, test_engine):
        """Test complete end-to-end workflow with real Ollama."""
        # Step 1: Generate data dictionary
        builder = DictionaryBuilder(test_engine)
        base_dict = builder.build_full_dictionary(include_row_counts=False)
        
        assert 'tables' in base_dict
        assert len(base_dict['tables']) >= 2
        
        # Step 2: Enhance with AI documentation
        explainer = SchemaExplainer(test_engine)
        assert explainer.is_available(), "Ollama should be available"
        
        enhanced_dict = explainer.enhance_dictionary(base_dict, include_column_descriptions=False)
        
        # Verify enhancements
        users_table = enhanced_dict['tables']['users']
        assert 'ai_description' in users_table
        assert 'ai_purpose' in users_table
        
        # Step 3: Generate and execute NL queries
        generator = NaturalLanguageQueryGenerator(test_engine)
        
        queries = [
            "Show all users",
            "How many orders are pending?",
            "List users with their orders"
        ]
        
        for question in queries:
            result = generator.ask(question, execute=True)
            assert result['sql'] is not None
            # Not all may execute successfully, but should be generated
            assert 'data' in result or 'execution_error' in result

    @ollama_available
    @model_available
    def test_schema_explanation_comprehensive_real_ollama(self, test_engine):
        """Test comprehensive schema explanation."""
        explainer = SchemaExplainer(test_engine)
        assert explainer.is_available(), "Ollama should be available"
        
        builder = DictionaryBuilder(test_engine)
        base_dict = builder.build_full_dictionary(include_row_counts=False)
        
        # Enhance all tables
        enhanced_dict = explainer.enhance_dictionary(base_dict, include_column_descriptions=False)
        
        # Verify all tables have AI documentation
        for table_name, table_info in enhanced_dict['tables'].items():
            assert 'ai_description' in table_info, f"{table_name} should have AI description"
            assert len(table_info['ai_description']) > 0
            assert 'ai_purpose' in table_info
            assert len(table_info['ai_purpose']) > 0

    @ollama_available
    @model_available
    def test_multiple_nlqueries_real_ollama(self, test_engine):
        """Test multiple NL queries in sequence."""
        generator = NaturalLanguageQueryGenerator(test_engine)
        assert generator.is_available(), "Ollama should be available"
        
        questions = [
            "Show users named John",
            "Count orders by status",
            "Get products under $60",
        ]
        
        results = []
        for question in questions:
            result = generator.ask(question, execute=False)
            results.append(result)
            assert result['sql'] is not None
            assert len(result['sql']) > 0
        
        # Verify we got diverse SQL queries
        sqls = [r['sql'].lower() for r in results]
        assert any('john' in s for s in sqls) or any('where' in s for s in sqls)
