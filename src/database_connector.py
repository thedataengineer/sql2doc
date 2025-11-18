"""
Database Connection Module
Handles connections to various SQL databases (PostgreSQL, MySQL, SQL Server)
"""

from typing import Optional
from sqlalchemy import create_engine, Engine, text
from sqlalchemy.exc import SQLAlchemyError
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class DatabaseConnector:
    """
    Manages database connections for multiple SQL database types.
    """

    SUPPORTED_DATABASES = ['postgresql', 'mysql', 'sqlite', 'mssql']

    def __init__(self):
        self.engine: Optional[Engine] = None
        self.connection_string: Optional[str] = None

    def connect(self, connection_string: str) -> Engine:
        """
        Establish a connection to the database.

        Args:
            connection_string (str): Database connection string
                Examples:
                - PostgreSQL: postgresql://user:password@localhost:5432/dbname
                - MySQL: mysql+pymysql://user:password@localhost:3306/dbname
                - SQLite: sqlite:///path/to/database.db

        Returns:
            Engine: SQLAlchemy engine object

        Raises:
            SQLAlchemyError: If connection fails
        """
        try:
            logger.info("Attempting to connect to database...")
            self.engine = create_engine(connection_string, pool_pre_ping=True)

            # Test the connection
            with self.engine.connect() as conn:
                conn.execute(text("SELECT 1"))

            self.connection_string = connection_string
            logger.info("Successfully connected to database")
            return self.engine

        except SQLAlchemyError as e:
            logger.error(f"Failed to connect to database: {str(e)}")
            raise

    def disconnect(self):
        """
        Close the database connection.
        """
        if self.engine:
            self.engine.dispose()
            self.engine = None
            self.connection_string = None
            logger.info("Database connection closed")

    def get_engine(self) -> Optional[Engine]:
        """
        Get the current database engine.

        Returns:
            Optional[Engine]: Current SQLAlchemy engine or None
        """
        return self.engine

    def is_connected(self) -> bool:
        """
        Check if database connection is active.

        Returns:
            bool: True if connected, False otherwise
        """
        if not self.engine:
            return False

        try:
            with self.engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            return True
        except SQLAlchemyError:
            return False

    def get_database_type(self) -> Optional[str]:
        """
        Get the type of database currently connected.

        Returns:
            Optional[str]: Database type (postgresql, mysql, sqlite, etc.)
        """
        if self.engine:
            return self.engine.dialect.name
        return None
