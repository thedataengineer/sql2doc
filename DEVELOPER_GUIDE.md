# Developer Guide

## Architecture Overview

The SQL Data Dictionary Generator follows a modular architecture with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│         Streamlit UI (app.py)           │
│     User Interface & Interaction        │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│          Core Modules (src/)            │
├─────────────────────────────────────────┤
│  DatabaseConnector                      │
│  ├─ Connection Management               │
│  └─ Engine Creation                     │
├─────────────────────────────────────────┤
│  SchemaFetcher                          │
│  ├─ Table Discovery                     │
│  ├─ Column Information                  │
│  ├─ Constraints & Keys                  │
│  └─ Index Information                   │
├─────────────────────────────────────────┤
│  DictionaryBuilder                      │
│  ├─ Dictionary Compilation              │
│  ├─ Export (JSON/Markdown)              │
│  └─ Summary Generation                  │
├─────────────────────────────────────────┤
│  DataProfiler                           │
│  ├─ Column Profiling                    │
│  ├─ Quality Checks                      │
│  ├─ Custom Queries                      │
│  └─ Statistical Analysis                │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│         Database (SQLAlchemy)           │
│    PostgreSQL / MySQL / SQLite          │
└─────────────────────────────────────────┘
```

## Module Design Principles

### 1. DatabaseConnector

**Purpose**: Manage database connections with support for multiple database types.

**Design Decisions**:
- Uses SQLAlchemy for database abstraction
- Implements connection pooling with `pool_pre_ping=True` for connection health checks
- Provides connection state management
- Supports multiple database dialects

**Key Methods**:
```python
connect(connection_string: str) -> Engine
disconnect() -> None
is_connected() -> bool
get_database_type() -> Optional[str]
```

### 2. SchemaFetcher

**Purpose**: Extract schema metadata from databases.

**Design Decisions**:
- Uses SQLAlchemy Inspector API for database-agnostic metadata retrieval
- Handles errors gracefully, returning empty lists on failures
- Caches inspector instance for performance
- Provides granular methods for different schema elements

**Key Methods**:
```python
get_all_tables() -> List[str]
get_table_columns(table_name: str) -> List[Dict[str, Any]]
get_primary_keys(table_name: str) -> List[str]
get_foreign_keys(table_name: str) -> List[Dict[str, Any]]
get_indexes(table_name: str) -> List[Dict[str, Any]]
```

### 3. DictionaryBuilder

**Purpose**: Compile comprehensive data dictionaries from schema information.

**Design Decisions**:
- Aggregates data from SchemaFetcher
- Supports optional row counting (performance consideration)
- Multiple export formats (JSON, Markdown)
- Generates summary statistics

**Key Methods**:
```python
build_full_dictionary(include_row_counts: bool) -> Dict[str, Any]
build_table_dictionary(table_name: str) -> Dict[str, Any]
export_to_json(dictionary: Dict, file_path: str) -> None
export_to_markdown(dictionary: Dict, file_path: str) -> None
```

### 4. DataProfiler

**Purpose**: Execute data profiling and quality assessment.

**Design Decisions**:
- Performs both column-level and table-level profiling
- Calculates statistical metrics (min, max, avg)
- Detects data quality issues (nulls, duplicates)
- Supports custom SQL query execution
- Handles numeric and non-numeric columns differently

**Key Methods**:
```python
profile_table(table_name: str) -> Dict[str, Any]
profile_column(table_name: str, column_name: str) -> Dict[str, Any]
check_null_values(table_name: str) -> Dict[str, Any]
calculate_completeness(table_name: str) -> float
run_custom_query(query: str) -> List[Dict[str, Any]]
```

## Adding New Features

### Adding a New Database Type

1. Ensure SQLAlchemy supports the database
2. Add the driver to `requirements.txt`
3. Update `DatabaseConnector.SUPPORTED_DATABASES`
4. Add connection string examples in documentation
5. Test with the new database type

Example:
```python
# In requirements.txt
mssql-pyodbc==2.1.0

# In app.py, add to selectbox
db_type_select = st.selectbox(
    "Database Type",
    ["PostgreSQL", "MySQL", "SQLite", "SQL Server"]
)
```

### Adding a New Profiling Check

1. Create a new method in `DataProfiler` class
2. Add the check to `profile_table()` method
3. Update UI to display the new check
4. Add tests for the new functionality

Example:
```python
def check_data_types(self, table_name: str) -> Dict[str, Any]:
    """Check for data type consistency."""
    # Implementation
    pass

# Add to profile_table()
profile['data_quality']['type_check'] = self.check_data_types(table_name)
```

### Adding a New Export Format

1. Create export method in `DictionaryBuilder`
2. Add format option in UI
3. Implement the export logic
4. Add tests

Example:
```python
def export_to_csv(self, dictionary: Dict[str, Any], file_path: str):
    """Export data dictionary to CSV format."""
    # Flatten the dictionary structure
    # Write to CSV
    pass
```

## Testing Strategy

### Unit Tests

Each module has comprehensive unit tests:

- `test_database_connector.py`: Connection management tests
- `test_schema_fetcher.py`: Schema retrieval tests
- `test_profiling_scripts.py`: Profiling functionality tests

### Test Database

Tests use SQLite in-memory databases for speed and isolation:

```python
@pytest.fixture
def test_engine(tmp_path):
    db_file = tmp_path / "test.db"
    engine = create_engine(f"sqlite:///{db_file}")
    # Create test schema
    yield engine
    engine.dispose()
```

### Running Tests

```bash
# Run all tests
pytest

# Run specific module
pytest tests/test_database_connector.py

# Run with coverage
pytest --cov=src --cov-report=html

# Run with verbose output
pytest -v
```

## Performance Considerations

### Row Counting

Row counting can be slow for large tables. Considerations:

- Make it optional in the UI
- Use `COUNT(*)` which is optimized by most databases
- Consider sampling for very large tables

### Connection Pooling

SQLAlchemy handles connection pooling automatically:

```python
engine = create_engine(
    connection_string,
    pool_pre_ping=True,  # Verify connections before use
    pool_size=5,         # Default pool size
    max_overflow=10      # Additional connections if needed
)
```

### Query Optimization

For profiling queries:

- Use indexes when available
- Limit result sets with LIMIT clauses
- Consider ANALYZE/EXPLAIN for slow queries
- Profile in batches for large tables

## Security Best Practices

### 1. Connection String Security

Never hardcode credentials:

```python
# Bad
connection_string = "postgresql://user:password@localhost/db"

# Good
from dotenv import load_dotenv
load_dotenv()
connection_string = os.getenv('DATABASE_URL')
```

### 2. SQL Injection Prevention

Use parameterized queries:

```python
# Bad
query = f"SELECT * FROM {table_name}"

# Good
from sqlalchemy import text
query = text("SELECT * FROM :table_name")
result = conn.execute(query, {"table_name": table_name})
```

### 3. Read-Only Access

Recommend read-only database users for profiling:

```sql
-- PostgreSQL example
CREATE USER profiler WITH PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE mydb TO profiler;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO profiler;
```

## On-Premises Deployment

### Local Installation

```bash
# Clone repository
git clone <repo-url>
cd sql2doc

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run application
streamlit run app.py
```

### Docker Deployment

Create `Dockerfile`:

```dockerfile
FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8501

CMD ["streamlit", "run", "app.py"]
```

Build and run:

```bash
docker build -t sql2doc .
docker run -p 8501:8501 sql2doc
```

### Internal Network Configuration

For on-premises deployment:

1. Configure firewall rules for database access
2. Use internal DNS for database hosts
3. Set up reverse proxy if needed (nginx, Apache)
4. Configure SSL/TLS for secure connections

## Troubleshooting

### Common Issues

**Issue**: Connection timeout
**Solution**: Check network connectivity, firewall rules, and database availability

**Issue**: Permission denied on tables
**Solution**: Grant SELECT permissions to the database user

**Issue**: Tests failing
**Solution**: Ensure pytest and all dependencies are installed

**Issue**: Slow profiling
**Solution**: Disable row counts, profile tables individually, check database indexes

## Code Style and Standards

### Python Style

- Follow PEP 8
- Use type hints where appropriate
- Write docstrings for all public methods
- Keep functions focused and small

### Naming Conventions

- Classes: PascalCase (`DatabaseConnector`)
- Functions/Methods: snake_case (`get_all_tables`)
- Constants: UPPER_SNAKE_CASE (`SUPPORTED_DATABASES`)
- Private methods: Leading underscore (`_get_columns`)

### Documentation

- Module-level docstrings
- Class-level docstrings
- Method docstrings with Args, Returns, Raises sections
- Inline comments for complex logic

Example:

```python
def profile_column(self, table_name: str, column_name: str) -> Dict[str, Any]:
    """
    Profile a specific column.

    Args:
        table_name (str): Name of the table
        column_name (str): Name of the column

    Returns:
        Dict[str, Any]: Column profiling data containing:
            - null_count: Number of NULL values
            - distinct_count: Number of distinct values
            - null_percentage: Percentage of NULL values
            - distinct_percentage: Percentage of distinct values

    Raises:
        SQLAlchemyError: If database query fails
    """
    # Implementation
```

## Future Enhancements

Potential areas for improvement:

1. **Data Lineage Tracking**: Track data flow between tables
2. **Schema Comparison**: Compare schemas across environments
3. **Automated Profiling Schedule**: Schedule regular profiling runs
4. **Alert System**: Alert on data quality issues
5. **API Mode**: REST API for programmatic access
6. **Performance Metrics**: Track query performance over time
7. **Machine Learning**: Detect anomalies in data distributions

## Contributing

When contributing:

1. Create a feature branch
2. Write tests for new functionality
3. Update documentation
4. Follow code style guidelines
5. Submit pull request with clear description

## Resources

- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [Streamlit Documentation](https://docs.streamlit.io/)
- [Pytest Documentation](https://docs.pytest.org/)
- [Database Design Best Practices](https://www.postgresql.org/docs/)
