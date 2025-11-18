# SQL Data Dictionary Generator with AI

A comprehensive tool for generating data dictionaries and running profiling scripts for SQL databases with an intuitive Streamlit UI. Now with AI-powered natural language queries and automated documentation!

## Features

### Core Features
- **Multi-Database Support**: PostgreSQL, MySQL, SQLite
- **Comprehensive Data Dictionary Generation**:
  - Table and column information
  - Data types and constraints
  - Primary and foreign keys
  - Indexes and relationships
  - Row counts and statistics
- **Data Profiling**:
  - NULL value analysis
  - Duplicate detection
  - Data completeness scoring
  - Column statistics (min, max, avg)
  - Value distribution analysis
- **Custom SQL Query Execution**: Run custom profiling queries
- **Multiple Export Formats**: JSON and Markdown
- **Interactive Streamlit UI**: User-friendly web interface

### AI-Powered Features (New!)
- **Natural Language to SQL**: Ask questions in plain English, get SQL queries
  - Uses local Ollama/Llama3.2 (on-premises, privacy-first)
  - Automatic schema context injection
  - Confidence scoring for generated queries
  - Auto-execution with safety limits
- **AI-Enhanced Documentation**:
  - Automated table and column explanations
  - Relationship documentation
  - Database-wide summaries
  - Human-readable purpose and usage notes
- **On-Premises AI**: No cloud dependencies, all processing happens locally

## Installation

### Prerequisites

- Python 3.8 or higher
- pip package manager
- Ollama (for AI features - optional but recommended)

### Setup

1. Clone or download this repository:
```bash
cd sql2doc
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. (Optional) Set up Ollama for AI features:
```bash
# Install Ollama from https://ollama.ai
# Download and install for your platform

# Pull the Llama 3.2 model
ollama pull llama3.2

# Start Ollama service (if not running)
ollama serve
```

Note: AI features will gracefully degrade if Ollama is not available. The core functionality works without AI.

## Usage

### Running the Application

Start the Streamlit application:

```bash
streamlit run app.py
```

The application will open in your default web browser at `http://localhost:8501`.

### Connecting to a Database

1. Use the sidebar to configure your database connection
2. Select database type (PostgreSQL, MySQL, or SQLite)
3. Enter connection details:
   - **PostgreSQL**: `postgresql://username:password@host:port/database`
   - **MySQL**: `mysql+pymysql://username:password@host:port/database`
   - **SQLite**: `sqlite:///path/to/database.db`
4. Click "Connect"

### Generating a Data Dictionary

1. Navigate to the "Data Dictionary" tab
2. Choose whether to include row counts (slower for large databases)
3. Click "Generate Dictionary"
4. Browse through tables and view detailed information

### Running Data Profiling

1. Go to the "Table Profiling" tab
2. Select a table from the dropdown
3. Click "Run Profiling"
4. View comprehensive data quality metrics:
   - Row counts
   - NULL value analysis
   - Completeness scores
   - Column-level statistics
   - Value distributions

### Running Custom Queries

1. Navigate to the "Custom Query" tab
2. Enter your SQL query
3. Click "Execute Query"
4. View and download results

### Exporting Data

1. Go to the "Export" tab
2. Choose export format:
   - **JSON**: Complete machine-readable format
   - **Markdown**: Human-readable documentation format
3. Download the generated file

### Using AI Features

#### Natural Language Queries

1. Navigate to the "AI Query (NL)" tab
2. Ensure Ollama is running (check status indicator)
3. Ask a question in plain English:
   - "Show me the top 10 customers by order value"
   - "What are the largest tables in the database?"
   - "Find all foreign key relationships"
4. View generated SQL with confidence score
5. Execute automatically or review first
6. Download results as CSV

#### AI-Enhanced Documentation

1. Generate a data dictionary first (Data Dictionary tab)
2. Navigate to the "AI Documentation" tab
3. Click "Enhance Dictionary with AI"
4. View AI-generated:
   - Table descriptions and purposes
   - Relationship explanations
   - Usage notes
5. Export enhanced documentation

## Project Structure

```
sql2doc/
├── app.py                      # Streamlit UI application
├── requirements.txt            # Python dependencies
├── pytest.ini                  # Pytest configuration
├── .gitignore                  # Git ignore rules
├── src/
│   ├── __init__.py
│   ├── database_connector.py  # Database connection management
│   ├── schema_fetcher.py      # Schema information retrieval
│   ├── dictionary_builder.py  # Data dictionary generation
│   ├── profiling_scripts.py   # Data profiling functionality
│   ├── nl_query_generator.py  # Natural language to SQL (AI)
│   └── schema_explainer.py    # AI-powered documentation
└── tests/
    ├── __init__.py
    ├── test_database_connector.py
    ├── test_schema_fetcher.py
    └── test_profiling_scripts.py
```

## Module Documentation

### DatabaseConnector

Manages database connections for multiple SQL database types.

```python
from src.database_connector import DatabaseConnector

connector = DatabaseConnector()
engine = connector.connect("postgresql://user:pass@localhost:5432/mydb")
```

**Key Methods**:
- `connect(connection_string)`: Establish database connection
- `disconnect()`: Close database connection
- `is_connected()`: Check connection status
- `get_database_type()`: Get database dialect name

### SchemaFetcher

Retrieves schema information from SQL databases.

```python
from src.schema_fetcher import SchemaFetcher

fetcher = SchemaFetcher(engine)
tables = fetcher.get_all_tables()
columns = fetcher.get_table_columns('table_name')
```

**Key Methods**:
- `get_all_tables()`: List all tables
- `get_table_columns(table_name)`: Get column details
- `get_primary_keys(table_name)`: Get primary key columns
- `get_foreign_keys(table_name)`: Get foreign key relationships
- `get_indexes(table_name)`: Get index information

### DictionaryBuilder

Compiles comprehensive data dictionaries from schema information.

```python
from src.dictionary_builder import DictionaryBuilder

builder = DictionaryBuilder(engine)
dictionary = builder.build_full_dictionary()
builder.export_to_json(dictionary, 'output.json')
```

**Key Methods**:
- `build_full_dictionary()`: Generate complete data dictionary
- `build_table_dictionary(table_name)`: Generate dictionary for specific table
- `export_to_json(dictionary, file_path)`: Export to JSON
- `export_to_markdown(dictionary, file_path)`: Export to Markdown

### DataProfiler

Executes data profiling scripts for quality assessment.

```python
from src.profiling_scripts import DataProfiler

profiler = DataProfiler(engine)
profile = profiler.profile_table('table_name')
```

**Key Methods**:
- `profile_table(table_name)`: Complete table profiling
- `profile_column(table_name, column_name)`: Column-level profiling
- `check_null_values(table_name)`: NULL value analysis
- `check_duplicates(table_name)`: Duplicate detection
- `calculate_completeness(table_name)`: Completeness score
- `get_value_distribution(table_name, column_name)`: Value distribution
- `run_custom_query(query)`: Execute custom SQL query

### NaturalLanguageQueryGenerator (AI)

Converts natural language questions to SQL queries using local LLM.

```python
from src.nl_query_generator import NaturalLanguageQueryGenerator

nl_gen = NaturalLanguageQueryGenerator(engine, model="llama3.2")
result = nl_gen.ask("Show me the top 10 customers")
print(result['sql'])
```

**Key Methods**:
- `generate_sql(question)`: Generate SQL from natural language
- `execute_query(sql, limit)`: Execute generated SQL safely
- `ask(question, execute)`: Complete workflow (generate + execute)
- `is_available()`: Check if Ollama is running
- `get_database_schema()`: Get schema context for LLM

### SchemaExplainer (AI)

Generates AI-powered documentation and explanations for database schemas.

```python
from src.schema_explainer import SchemaExplainer

explainer = SchemaExplainer(engine, model="llama3.2")
explanation = explainer.explain_table("users", columns)
enhanced = explainer.enhance_dictionary(dictionary)
```

**Key Methods**:
- `explain_table(table_name, columns)`: Generate table explanation
- `explain_column(table, column, type)`: Explain specific column
- `generate_relationship_explanation(table, fks)`: Explain relationships
- `enhance_dictionary(dictionary)`: Add AI docs to full dictionary
- `generate_database_summary(dictionary)`: Create database overview
- `is_available()`: Check if Ollama is running

## Running Tests

Execute the test suite:

```bash
pytest
```

Run with coverage:

```bash
pytest --cov=src --cov-report=html
```

Run specific test file:

```bash
pytest tests/test_database_connector.py
```

## Example Workflows

### Workflow 1: Generate Complete Documentation

1. Connect to your database
2. Generate data dictionary with row counts
3. Export to Markdown for documentation
4. Share with team or include in project docs

### Workflow 2: Data Quality Assessment

1. Connect to database
2. Select table for profiling
3. Review NULL value analysis
4. Check for duplicates
5. Examine value distributions for key columns
6. Export results for reporting

### Workflow 3: Custom Analysis

1. Connect to database
2. Navigate to Custom Query tab
3. Write custom profiling SQL:
   ```sql
   SELECT
       column_name,
       COUNT(*) as total,
       COUNT(DISTINCT column_name) as unique_values,
       COUNT(*) - COUNT(column_name) as nulls
   FROM information_schema.columns
   GROUP BY column_name;
   ```
4. Execute and download results

## Security Considerations

- **On-Premises First**: Designed for on-prem deployments with local data
- **No Cloud Dependencies**: All processing happens locally
- **Connection Security**: Supports encrypted database connections
- **Credential Management**: Use environment variables for sensitive credentials
- **Query Safety**: Custom queries are executed with read-only intentions

## Best Practices

1. **Start Small**: Test with a small database first
2. **Row Counts**: Disable row counts for very large databases
3. **Regular Profiling**: Run profiling periodically to track data quality
4. **Export Documentation**: Keep data dictionaries up-to-date in version control
5. **Custom Queries**: Use profiling queries to identify data issues early

## Troubleshooting

### Connection Issues

- Verify database is running and accessible
- Check connection string format
- Ensure proper network access and firewall rules
- Verify database user permissions

### Performance Issues

- Disable row counts for large databases
- Profile tables individually rather than all at once
- Consider database indexes for profiling queries
- Use query limits for value distributions

### Test Failures

- Ensure all dependencies are installed
- Check Python version compatibility
- Verify pytest configuration

## Contributing

This project follows best practices for full-stack development with a focus on:

- Local-first architecture
- On-premises deployment
- Security and privacy
- Code maintainability
- Comprehensive testing

## License

MIT License - See LICENSE file for details

## Support

For issues, questions, or contributions, please refer to the project repository.

## Acknowledgments

Built with:
- SQLAlchemy for database abstraction
- Streamlit for interactive UI
- Pandas for data manipulation
- Pytest for testing
- Ollama for local LLM inference
- Llama 3.2 for AI-powered features
- Vanna AI framework (concepts integrated)

---

**Note**: This tool is designed for authorized database access and profiling. Always ensure you have proper permissions before connecting to production databases.
