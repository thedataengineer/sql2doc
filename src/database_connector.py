"""
Database Connection Module
Handles connections to various SQL databases (PostgreSQL, MySQL, SQL Server, SQLite)
and NoSQL databases (MongoDB, Neo4j)
"""

from typing import Optional, Any, Dict
from sqlalchemy import create_engine, Engine, text
from sqlalchemy.exc import SQLAlchemyError
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class DatabaseConnector:
    """
    Manages database connections for multiple database types.
    Supports both SQL (PostgreSQL, MySQL, SQLite, SQL Server)
    and NoSQL (MongoDB, Neo4j) databases.
    """

    SUPPORTED_DATABASES = ['postgresql', 'mysql', 'sqlite', 'mssql', 'mongodb', 'neo4j']

    # Database types
    TYPE_SQL = 'sql'
    TYPE_MONGODB = 'mongodb'
    TYPE_NEO4J = 'neo4j'

    def __init__(self):
        self.engine: Optional[Engine] = None
        self.connection_string: Optional[str] = None
        self.db_type: Optional[str] = None

        # For NoSQL connections
        self.mongo_client: Optional[Any] = None
        self.mongo_db: Optional[Any] = None
        self.neo4j_driver: Optional[Any] = None

    def connect(self, connection_string: str, **kwargs) -> Any:
        """
        Establish a connection to the database.

        Args:
            connection_string (str): Database connection string
                Examples:
                - PostgreSQL: postgresql://user:password@localhost:5432/dbname
                - MySQL: mysql+pymysql://user:password@localhost:3306/dbname
                - SQLite: sqlite:///path/to/database.db
                - SQL Server: mssql+pyodbc://user:password@host:port/dbname?driver=ODBC+Driver+17+for+SQL+Server
                - MongoDB: mongodb://user:password@localhost:27017/dbname
                - Neo4j: neo4j://localhost:7687 (with auth in kwargs)

        Returns:
            Engine/Client: Database connection object

        Raises:
            Exception: If connection fails
        """
        try:
            logger.info("Attempting to connect to database...")
            self.connection_string = connection_string

            # Detect database type from connection string
            if connection_string.startswith('mongodb'):
                return self._connect_mongodb(connection_string, **kwargs)
            elif connection_string.startswith('neo4j'):
                return self._connect_neo4j(connection_string, **kwargs)
            else:
                # SQL databases (PostgreSQL, MySQL, SQLite, SQL Server)
                return self._connect_sql(connection_string)

        except Exception as e:
            logger.error(f"Failed to connect to database: {str(e)}")
            raise

    def _connect_sql(self, connection_string: str) -> Engine:
        """Connect to SQL databases via SQLAlchemy."""
        self.engine = create_engine(connection_string, pool_pre_ping=True)
        self.db_type = self.TYPE_SQL

        # Test the connection
        with self.engine.connect() as conn:
            conn.execute(text("SELECT 1"))

        logger.info(f"Successfully connected to SQL database: {self.engine.dialect.name}")
        return self.engine

    def _connect_mongodb(self, connection_string: str, **kwargs) -> Any:
        """Connect to MongoDB."""
        try:
            from pymongo import MongoClient
        except ImportError:
            raise ImportError("pymongo is required for MongoDB connections. Install with: pip install pymongo")

        # Extract database name from connection string
        db_name = kwargs.get('database')
        if not db_name:
            # Try to extract from connection string
            parts = connection_string.split('/')
            if len(parts) > 3:
                db_name = parts[-1].split('?')[0]
            else:
                raise ValueError("Database name must be provided for MongoDB")

        self.mongo_client = MongoClient(connection_string)
        self.mongo_db = self.mongo_client[db_name]
        self.db_type = self.TYPE_MONGODB

        # Test connection
        self.mongo_client.server_info()

        logger.info(f"Successfully connected to MongoDB: {db_name}")
        return self.mongo_db

    def _connect_neo4j(self, connection_string: str, **kwargs) -> Any:
        """Connect to Neo4j."""
        try:
            from neo4j import GraphDatabase
        except ImportError:
            raise ImportError("neo4j is required for Neo4j connections. Install with: pip install neo4j")

        # Neo4j requires auth separately
        auth = kwargs.get('auth', ('neo4j', 'password'))
        username = kwargs.get('username', auth[0])
        password = kwargs.get('password', auth[1])

        self.neo4j_driver = GraphDatabase.driver(
            connection_string,
            auth=(username, password)
        )
        self.db_type = self.TYPE_NEO4J

        # Test connection
        with self.neo4j_driver.session() as session:
            session.run("RETURN 1")

        logger.info("Successfully connected to Neo4j")
        return self.neo4j_driver

    def disconnect(self):
        """
        Close the database connection.
        """
        if self.engine:
            self.engine.dispose()
            self.engine = None
            logger.info("SQL database connection closed")

        if self.mongo_client:
            self.mongo_client.close()
            self.mongo_client = None
            self.mongo_db = None
            logger.info("MongoDB connection closed")

        if self.neo4j_driver:
            self.neo4j_driver.close()
            self.neo4j_driver = None
            logger.info("Neo4j connection closed")

        self.connection_string = None
        self.db_type = None

    def get_engine(self) -> Optional[Engine]:
        """
        Get the current database engine (SQL only).

        Returns:
            Optional[Engine]: Current SQLAlchemy engine or None
        """
        return self.engine

    def get_connection(self) -> Any:
        """
        Get the current database connection (works for all types).

        Returns:
            Engine/Database/Driver: Connection object based on database type
        """
        if self.db_type == self.TYPE_SQL:
            return self.engine
        elif self.db_type == self.TYPE_MONGODB:
            return self.mongo_db
        elif self.db_type == self.TYPE_NEO4J:
            return self.neo4j_driver
        return None

    def is_connected(self) -> bool:
        """
        Check if database connection is active.

        Returns:
            bool: True if connected, False otherwise
        """
        try:
            if self.db_type == self.TYPE_SQL and self.engine:
                with self.engine.connect() as conn:
                    conn.execute(text("SELECT 1"))
                return True
            elif self.db_type == self.TYPE_MONGODB and self.mongo_client:
                self.mongo_client.server_info()
                return True
            elif self.db_type == self.TYPE_NEO4J and self.neo4j_driver:
                with self.neo4j_driver.session() as session:
                    session.run("RETURN 1")
                return True
        except Exception:
            return False

        return False

    def get_database_type(self) -> Optional[str]:
        """
        Get the type of database currently connected.

        Returns:
            Optional[str]: Database type (postgresql, mysql, sqlite, mongodb, neo4j, etc.)
        """
        if self.db_type == self.TYPE_SQL and self.engine:
            return self.engine.dialect.name
        elif self.db_type == self.TYPE_MONGODB:
            return 'mongodb'
        elif self.db_type == self.TYPE_NEO4J:
            return 'neo4j'
        return None
