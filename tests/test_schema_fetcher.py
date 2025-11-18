"""
Unit tests for SchemaFetcher module
"""

import pytest
from sqlalchemy import create_engine, text
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))

from src.schema_fetcher import SchemaFetcher


@pytest.fixture
def test_engine(tmp_path):
    """Create a test SQLite database with sample schema."""
    db_file = tmp_path / "test.db"
    engine = create_engine(f"sqlite:///{db_file}")

    # Create test schema
    with engine.connect() as conn:
        conn.execute(text("""
            CREATE TABLE users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username VARCHAR(50) NOT NULL UNIQUE,
                email VARCHAR(100),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))

        conn.execute(text("""
            CREATE TABLE posts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                title VARCHAR(200) NOT NULL,
                content TEXT,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        """))

        conn.execute(text("""
            CREATE INDEX idx_posts_user_id ON posts(user_id)
        """))

        conn.commit()

    yield engine

    engine.dispose()


class TestSchemaFetcher:
    """Test cases for SchemaFetcher class."""

    def test_init(self, test_engine):
        """Test SchemaFetcher initialization."""
        fetcher = SchemaFetcher(test_engine)
        assert fetcher.engine is not None
        assert fetcher.inspector is not None

    def test_get_all_tables(self, test_engine):
        """Test retrieving all tables."""
        fetcher = SchemaFetcher(test_engine)
        tables = fetcher.get_all_tables()

        assert len(tables) == 2
        assert 'users' in tables
        assert 'posts' in tables

    def test_get_table_columns(self, test_engine):
        """Test retrieving table columns."""
        fetcher = SchemaFetcher(test_engine)
        columns = fetcher.get_table_columns('users')

        assert len(columns) > 0

        column_names = [col['name'] for col in columns]
        assert 'id' in column_names
        assert 'username' in column_names
        assert 'email' in column_names

        # Check column properties
        username_col = next(col for col in columns if col['name'] == 'username')
        assert username_col['nullable'] is False

    def test_get_primary_keys(self, test_engine):
        """Test retrieving primary keys."""
        fetcher = SchemaFetcher(test_engine)
        pks = fetcher.get_primary_keys('users')

        assert len(pks) == 1
        assert 'id' in pks

    def test_get_foreign_keys(self, test_engine):
        """Test retrieving foreign keys."""
        fetcher = SchemaFetcher(test_engine)
        fks = fetcher.get_foreign_keys('posts')

        assert len(fks) >= 1

        # Check foreign key properties
        fk = fks[0]
        assert 'user_id' in fk.get('constrained_columns', [])
        assert fk.get('referred_table') == 'users'

    def test_get_indexes(self, test_engine):
        """Test retrieving indexes."""
        fetcher = SchemaFetcher(test_engine)
        indexes = fetcher.get_indexes('posts')

        # Should have at least the index we created
        assert len(indexes) >= 1

        # Find our created index
        user_id_indexes = [idx for idx in indexes if 'user_id' in idx.get('columns', [])]
        assert len(user_id_indexes) > 0

    def test_get_table_row_count(self, test_engine):
        """Test getting row count."""
        # Insert some test data
        with test_engine.connect() as conn:
            conn.execute(text("INSERT INTO users (username, email) VALUES ('test1', 'test1@example.com')"))
            conn.execute(text("INSERT INTO users (username, email) VALUES ('test2', 'test2@example.com')"))
            conn.commit()

        fetcher = SchemaFetcher(test_engine)
        count = fetcher.get_table_row_count('users')

        assert count == 2

    def test_get_nonexistent_table(self, test_engine):
        """Test fetching data for non-existent table."""
        fetcher = SchemaFetcher(test_engine)
        columns = fetcher.get_table_columns('nonexistent_table')

        # Should return empty list for non-existent table
        assert columns == []

    def test_get_table_comment(self, test_engine):
        """Test getting table comment."""
        fetcher = SchemaFetcher(test_engine)
        comment = fetcher.get_table_comment('users')

        # SQLite doesn't support table comments by default
        assert isinstance(comment, str)
