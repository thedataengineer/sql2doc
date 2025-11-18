"""
Unit tests for DatabaseConnector module
"""

import pytest
from sqlalchemy.exc import SQLAlchemyError
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))

from src.database_connector import DatabaseConnector


class TestDatabaseConnector:
    """Test cases for DatabaseConnector class."""

    def test_init(self):
        """Test DatabaseConnector initialization."""
        connector = DatabaseConnector()
        assert connector.engine is None
        assert connector.connection_string is None

    def test_sqlite_connection(self, tmp_path):
        """Test connection to SQLite database."""
        db_file = tmp_path / "test.db"
        connection_string = f"sqlite:///{db_file}"

        connector = DatabaseConnector()
        engine = connector.connect(connection_string)

        assert engine is not None
        assert connector.is_connected()
        assert connector.get_database_type() == "sqlite"

        connector.disconnect()

    def test_invalid_connection_string(self):
        """Test connection with invalid connection string."""
        connector = DatabaseConnector()

        with pytest.raises(SQLAlchemyError):
            connector.connect("invalid://connection/string")

    def test_is_connected_when_not_connected(self):
        """Test is_connected returns False when not connected."""
        connector = DatabaseConnector()
        assert not connector.is_connected()

    def test_get_engine_when_not_connected(self):
        """Test get_engine returns None when not connected."""
        connector = DatabaseConnector()
        assert connector.get_engine() is None

    def test_get_database_type_when_not_connected(self):
        """Test get_database_type returns None when not connected."""
        connector = DatabaseConnector()
        assert connector.get_database_type() is None

    def test_disconnect(self, tmp_path):
        """Test database disconnection."""
        db_file = tmp_path / "test.db"
        connection_string = f"sqlite:///{db_file}"

        connector = DatabaseConnector()
        connector.connect(connection_string)
        assert connector.is_connected()

        connector.disconnect()
        # After disconnect, engine should be disposed
        assert not connector.is_connected()

    def test_reconnect(self, tmp_path):
        """Test reconnecting to database."""
        db_file = tmp_path / "test.db"
        connection_string = f"sqlite:///{db_file}"

        connector = DatabaseConnector()

        # First connection
        connector.connect(connection_string)
        assert connector.is_connected()

        # Disconnect
        connector.disconnect()

        # Reconnect
        connector.connect(connection_string)
        assert connector.is_connected()

        connector.disconnect()


@pytest.fixture
def test_db_connector(tmp_path):
    """Fixture providing a connected DatabaseConnector."""
    db_file = tmp_path / "test.db"
    connection_string = f"sqlite:///{db_file}"

    connector = DatabaseConnector()
    connector.connect(connection_string)

    yield connector

    connector.disconnect()
