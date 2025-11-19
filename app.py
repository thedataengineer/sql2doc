"""
SQL Data Dictionary Generator - Streamlit UI
Main application interface for generating data dictionaries and running profiling scripts
"""

import streamlit as st
import json
import pandas as pd
from datetime import datetime
import sys
import os
from pathlib import Path

# Add src directory to path
sys.path.insert(0, str(Path(__file__).parent / 'src'))

from src.database_connector import DatabaseConnector
from src.schema_fetcher import SchemaFetcher
from src.dictionary_builder import DictionaryBuilder
from src.profiling_scripts import DataProfiler
from src.nl_query_generator import NaturalLanguageQueryGenerator
from src.schema_explainer import SchemaExplainer


# Page configuration
st.set_page_config(
    page_title="SQL Data Dictionary Generator",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        color: #1f77b4;
        margin-bottom: 1rem;
    }
    .sub-header {
        font-size: 1.5rem;
        color: #2c3e50;
        margin-top: 1.5rem;
    }
    .metric-card {
        background-color: #f0f2f6;
        padding: 1rem;
        border-radius: 0.5rem;
        margin: 0.5rem 0;
    }
    .success-box {
        background-color: #d4edda;
        border: 1px solid #c3e6cb;
        color: #155724;
        padding: 1rem;
        border-radius: 0.5rem;
        margin: 1rem 0;
    }
    .error-box {
        background-color: #f8d7da;
        border: 1px solid #f5c6cb;
        color: #721c24;
        padding: 1rem;
        border-radius: 0.5rem;
        margin: 1rem 0;
    }
</style>
""", unsafe_allow_html=True)


# Initialize session state
if 'connector' not in st.session_state:
    st.session_state.connector = DatabaseConnector()
if 'connected' not in st.session_state:
    st.session_state.connected = False
if 'dictionary' not in st.session_state:
    st.session_state.dictionary = None
if 'current_table' not in st.session_state:
    st.session_state.current_table = None


def connect_to_database(connection_string: str, **kwargs) -> bool:
    """Connect to database using connection string."""
    try:
        st.session_state.connector.connect(connection_string, **kwargs)
        st.session_state.connected = True
        return True
    except Exception as e:
        st.error(f"Connection failed: {str(e)}")
        st.session_state.connected = False
        return False


def disconnect_database():
    """Disconnect from database."""
    st.session_state.connector.disconnect()
    st.session_state.connected = False
    st.session_state.dictionary = None


def main():
    """Main application function."""

    # Header
    st.markdown('<p class="main-header">SQL Data Dictionary Generator</p>', unsafe_allow_html=True)
    st.markdown("Generate comprehensive data dictionaries and run profiling scripts for your SQL databases.")

    # Sidebar - Database Connection
    with st.sidebar:
        st.header("Database Connection")

        # Connection status
        if st.session_state.connected:
            st.markdown('<div class="success-box">✓ Connected</div>', unsafe_allow_html=True)
            db_type = st.session_state.connector.get_database_type()
            st.info(f"Database Type: **{db_type}**")

            if st.button("Disconnect", type="secondary"):
                disconnect_database()
                st.rerun()
        else:
            st.markdown('<div class="error-box">⚠ Not Connected</div>', unsafe_allow_html=True)

        st.markdown("---")

        # Connection form
        st.subheader("Connect to Database")

        db_type_select = st.selectbox(
            "Database Type",
            ["PostgreSQL", "MySQL", "SQLite", "SQL Server", "MongoDB", "Neo4j"],
            help="Select your database type"
        )

        if db_type_select == "SQLite":
            db_path = st.text_input("Database File Path", value="database.db")
            connection_string = f"sqlite:///{db_path}"

        elif db_type_select == "MongoDB":
            col1, col2 = st.columns(2)
            with col1:
                host = st.text_input("Host", value="localhost")
                username = st.text_input("Username", value="")
            with col2:
                port = st.text_input("Port", value="27017")
                password = st.text_input("Password", type="password")

            database = st.text_input("Database Name", value="admin")

            if username and password:
                connection_string = f"mongodb://{username}:{password}@{host}:{port}/{database}"
            else:
                connection_string = f"mongodb://{host}:{port}/{database}"

        elif db_type_select == "Neo4j":
            col1, col2 = st.columns(2)
            with col1:
                host = st.text_input("Host", value="localhost")
                username = st.text_input("Username", value="neo4j")
            with col2:
                port = st.text_input("Port", value="7687")
                password = st.text_input("Password", type="password")

            connection_string = f"neo4j://{host}:{port}"
            # Store auth separately for Neo4j
            if 'neo4j_auth' not in st.session_state:
                st.session_state.neo4j_auth = (username, password)
            st.session_state.neo4j_auth = (username, password)

        else:
            # SQL databases: PostgreSQL, MySQL, SQL Server
            col1, col2 = st.columns(2)
            with col1:
                host = st.text_input("Host", value="localhost")
                username = st.text_input("Username", value="postgres" if db_type_select == "PostgreSQL" else "sa")
            with col2:
                default_port = {
                    "PostgreSQL": "5432",
                    "MySQL": "3306",
                    "SQL Server": "1433"
                }.get(db_type_select, "5432")
                port = st.text_input("Port", value=default_port)
                password = st.text_input("Password", type="password")

            database = st.text_input("Database Name")

            if db_type_select == "PostgreSQL":
                connection_string = f"postgresql://{username}:{password}@{host}:{port}/{database}"
            elif db_type_select == "MySQL":
                connection_string = f"mysql+pymysql://{username}:{password}@{host}:{port}/{database}"
            elif db_type_select == "SQL Server":
                # SQL Server connection string with pyodbc
                connection_string = f"mssql+pyodbc://{username}:{password}@{host}:{port}/{database}?driver=ODBC+Driver+17+for+SQL+Server"

        # Advanced connection string
        with st.expander("Advanced: Custom Connection String"):
            custom_conn = st.text_area(
                "Connection String",
                value=connection_string,
                help="Enter a custom SQLAlchemy connection string"
            )
            connection_string = custom_conn

        if st.button("Connect", type="primary", disabled=st.session_state.connected):
            if connection_string:
                with st.spinner("Connecting to database..."):
                    # Handle Neo4j special case with authentication
                    if db_type_select == "Neo4j":
                        auth = st.session_state.get('neo4j_auth', ('neo4j', 'password'))
                        if connect_to_database(connection_string, username=auth[0], password=auth[1]):
                            st.success("Connected successfully!")
                            st.rerun()
                    else:
                        if connect_to_database(connection_string):
                            st.success("Connected successfully!")
                            st.rerun()
            else:
                st.error("Please provide connection details")

        st.markdown("---")
        st.markdown("### Connection Examples")
        st.code("postgresql://user:pass@localhost:5432/db", language="text")
        st.code("mysql+pymysql://user:pass@localhost:3306/db", language="text")
        st.code("sqlite:///path/to/database.db", language="text")
        st.code("mssql+pyodbc://sa:pass@localhost:1433/db?driver=ODBC+Driver+17+for+SQL+Server", language="text")
        st.code("mongodb://user:pass@localhost:27017/dbname", language="text")
        st.code("neo4j://localhost:7687 (auth via username/password fields)", language="text")

    # Main content
    if not st.session_state.connected:
        st.info("👈 Please connect to a database using the sidebar to get started.")
        return

    # Tabs
    tab1, tab2, tab3, tab4, tab5, tab6 = st.tabs([
        "📚 Data Dictionary",
        "📊 Table Profiling",
        "🤖 AI Query (NL)",
        "✨ AI Documentation",
        "🔍 Custom Query",
        "💾 Export"
    ])

    # Tab 1: Data Dictionary
    with tab1:
        st.markdown('<p class="sub-header">Generate Data Dictionary</p>', unsafe_allow_html=True)

        col1, col2 = st.columns([3, 1])
        with col1:
            include_row_counts = st.checkbox("Include row counts", value=True, help="Slower for large databases")
        with col2:
            if st.button("Generate Dictionary", type="primary"):
                with st.spinner("Generating data dictionary..."):
                    try:
                        engine = st.session_state.connector.get_engine()
                        builder = DictionaryBuilder(engine)
                        st.session_state.dictionary = builder.build_full_dictionary(include_row_counts)
                        st.success("Data dictionary generated successfully!")
                    except Exception as e:
                        st.error(f"Error generating dictionary: {str(e)}")

        if st.session_state.dictionary:
            # Summary metrics
            st.markdown("### Summary")
            col1, col2, col3, col4 = st.columns(4)

            with col1:
                st.metric("Total Tables", st.session_state.dictionary.get('total_tables', 0))

            if st.session_state.dictionary.get('tables'):
                total_columns = sum(
                    table.get('total_columns', 0)
                    for table in st.session_state.dictionary['tables'].values()
                )
                total_rows = sum(
                    table.get('row_count', 0)
                    for table in st.session_state.dictionary['tables'].values()
                )
                tables_with_fks = sum(
                    1 for table in st.session_state.dictionary['tables'].values()
                    if table.get('foreign_keys')
                )

                with col2:
                    st.metric("Total Columns", total_columns)
                with col3:
                    st.metric("Total Rows", f"{total_rows:,}")
                with col4:
                    st.metric("Tables with FKs", tables_with_fks)

            st.markdown("---")

            # Table selection
            st.markdown("### Table Details")
            table_names = list(st.session_state.dictionary['tables'].keys())
            selected_table = st.selectbox("Select a table to view details:", table_names)

            if selected_table:
                table_info = st.session_state.dictionary['tables'][selected_table]

                # Table info
                col1, col2, col3 = st.columns(3)
                with col1:
                    st.metric("Columns", table_info.get('total_columns', 0))
                with col2:
                    st.metric("Rows", f"{table_info.get('row_count', 0):,}")
                with col3:
                    st.metric("Nullable Columns", table_info.get('nullable_columns', 0))

                # Table comment
                if table_info.get('comment'):
                    st.info(f"**Description:** {table_info['comment']}")

                # Columns
                st.markdown("#### Columns")
                columns_df = pd.DataFrame(table_info.get('columns', []))
                if not columns_df.empty:
                    st.dataframe(columns_df, use_container_width=True, hide_index=True)

                # Primary Keys
                if table_info.get('primary_keys'):
                    st.markdown("#### Primary Keys")
                    st.write(", ".join(table_info['primary_keys']))

                # Foreign Keys
                if table_info.get('foreign_keys'):
                    st.markdown("#### Foreign Keys")
                    fk_data = []
                    for fk in table_info['foreign_keys']:
                        fk_data.append({
                            'Constraint': fk.get('name', 'unnamed'),
                            'Columns': ', '.join(fk.get('constrained_columns', [])),
                            'References': f"{fk.get('referred_table')}({', '.join(fk.get('referred_columns', []))})"
                        })
                    st.dataframe(pd.DataFrame(fk_data), use_container_width=True, hide_index=True)

                # Indexes
                if table_info.get('indexes'):
                    st.markdown("#### Indexes")
                    idx_data = []
                    for idx in table_info['indexes']:
                        idx_data.append({
                            'Index Name': idx.get('name', 'unnamed'),
                            'Columns': ', '.join(idx.get('columns', [])),
                            'Unique': 'Yes' if idx.get('unique') else 'No'
                        })
                    st.dataframe(pd.DataFrame(idx_data), use_container_width=True, hide_index=True)

    # Tab 2: Table Profiling
    with tab2:
        st.markdown('<p class="sub-header">Data Profiling</p>', unsafe_allow_html=True)

        engine = st.session_state.connector.get_engine()
        schema_fetcher = SchemaFetcher(engine)
        profiler = DataProfiler(engine)

        tables = schema_fetcher.get_all_tables()
        selected_profile_table = st.selectbox("Select a table to profile:", tables, key="profile_table")

        if st.button("Run Profiling", type="primary"):
            with st.spinner(f"Profiling table: {selected_profile_table}..."):
                try:
                    profile_results = profiler.profile_table(selected_profile_table)

                    # Display results
                    st.success("Profiling completed!")

                    # Basic stats
                    col1, col2, col3 = st.columns(3)
                    with col1:
                        st.metric("Total Rows", f"{profile_results.get('row_count', 0):,}")
                    with col2:
                        completeness = profile_results['data_quality'].get('completeness_score', 0)
                        st.metric("Completeness", f"{completeness}%")
                    with col3:
                        null_cols = len(profile_results['data_quality']['null_check'].get('columns_with_nulls', []))
                        st.metric("Columns with NULLs", null_cols)

                    st.markdown("---")

                    # Column profiles
                    st.markdown("### Column Profiles")
                    col_profiles = []
                    for col_name, col_data in profile_results.get('column_profiles', {}).items():
                        col_profiles.append({
                            'Column': col_name,
                            'Null Count': col_data.get('null_count', 0),
                            'Null %': f"{col_data.get('null_percentage', 0):.2f}%",
                            'Distinct Values': col_data.get('distinct_count', 0),
                            'Distinct %': f"{col_data.get('distinct_percentage', 0):.2f}%",
                            'Min': col_data.get('min_value', 'N/A'),
                            'Max': col_data.get('max_value', 'N/A')
                        })

                    if col_profiles:
                        st.dataframe(pd.DataFrame(col_profiles), use_container_width=True, hide_index=True)

                    st.markdown("---")

                    # Data quality checks
                    st.markdown("### Data Quality Checks")

                    # Null values
                    with st.expander("NULL Value Analysis", expanded=True):
                        null_check = profile_results['data_quality'].get('null_check', {})
                        cols_with_nulls = null_check.get('columns_with_nulls', [])

                        if cols_with_nulls:
                            st.warning(f"Found {len(cols_with_nulls)} columns with NULL values")
                            null_df = pd.DataFrame(cols_with_nulls)
                            null_df['null_percentage'] = null_df['null_percentage'].round(2)
                            st.dataframe(null_df, use_container_width=True, hide_index=True)
                        else:
                            st.success("No NULL values found in any column!")

                    # Duplicates
                    with st.expander("Duplicate Check"):
                        dup_check = profile_results['data_quality'].get('duplicate_check', {})
                        if dup_check.get('has_duplicates'):
                            st.warning(
                                f"Found {dup_check.get('duplicate_rows', 0)} duplicate rows "
                                f"({dup_check.get('duplicate_percentage', 0):.2f}%)"
                            )
                        else:
                            st.success("No duplicate rows found!")

                except Exception as e:
                    st.error(f"Error during profiling: {str(e)}")

        # Value distribution
        st.markdown("---")
        st.markdown("### Column Value Distribution")
        col1, col2 = st.columns([2, 1])
        with col1:
            if selected_profile_table:
                columns = schema_fetcher.get_table_columns(selected_profile_table)
                column_names = [col['name'] for col in columns]
                selected_column = st.selectbox("Select column:", column_names, key="dist_column")
        with col2:
            top_n = st.number_input("Top N values", min_value=5, max_value=100, value=10)

        if st.button("Get Distribution"):
            with st.spinner("Fetching value distribution..."):
                try:
                    distribution = profiler.get_value_distribution(selected_profile_table, selected_column, top_n)
                    if distribution:
                        dist_df = pd.DataFrame(distribution)
                        st.dataframe(dist_df, use_container_width=True, hide_index=True)

                        # Bar chart
                        st.bar_chart(dist_df.set_index('value')['count'])
                    else:
                        st.warning("No distribution data available")
                except Exception as e:
                    st.error(f"Error: {str(e)}")

    # Tab 3: AI-Powered Natural Language Query
    with tab3:
        st.markdown('<p class="sub-header">Natural Language Query with AI</p>', unsafe_allow_html=True)

        # Check Ollama availability
        engine = st.session_state.connector.get_engine()
        default_ollama_host = os.getenv('OLLAMA_HOST', 'http://localhost:11434')
        nl_generator = NaturalLanguageQueryGenerator(engine, ollama_host=default_ollama_host)

        if not nl_generator.is_available():
            st.warning("⚠️ Ollama is not available. Please ensure Ollama is running locally.")
            st.info("""
            **Setup Instructions:**
            1. Install Ollama: https://ollama.ai
            2. Run: `ollama pull llama3.2`
            3. Start Ollama service: `ollama serve`
            4. Refresh this page
            """)
        else:
            st.success("✓ Ollama is available and ready")

            st.markdown("Ask questions about your data in plain English, and AI will generate and execute SQL queries.")

            # Settings
            with st.expander("⚙️ Settings"):
                col1, col2 = st.columns(2)
                with col1:
                    ollama_model = st.text_input("Ollama Model", value="llama3.2", help="Model name from Ollama")
                    ollama_host = st.text_input("Ollama Host", value=default_ollama_host)
                with col2:
                    temperature = st.slider("Temperature", 0.0, 1.0, 0.1, 0.1, help="Lower = more deterministic")
                    result_limit = st.number_input("Result Limit", 10, 1000, 100, help="Max rows to return")

                if st.button("Update Settings"):
                    nl_generator = NaturalLanguageQueryGenerator(
                        engine,
                        ollama_host=ollama_host,
                        model=ollama_model,
                        temperature=temperature
                    )
                    st.success("Settings updated!")

            st.markdown("---")

            # Natural language question
            question = st.text_area(
                "Ask a question about your data:",
                height=100,
                placeholder="Example: Show me the top 10 customers by total order value"
            )

            col1, col2 = st.columns([1, 4])
            with col1:
                execute_query = st.checkbox("Auto-execute SQL", value=True, help="Automatically run generated SQL")

            if st.button("Generate SQL", type="primary"):
                if question:
                    with st.spinner("Generating SQL from your question..."):
                        try:
                            result = nl_generator.ask(question, execute=execute_query)

                            # Display generated SQL
                            st.markdown("### Generated SQL")
                            if result.get('sql'):
                                st.code(result['sql'], language="sql")

                                # Confidence and explanation
                                col1, col2 = st.columns(2)
                                with col1:
                                    confidence = result.get('confidence', 0.0)
                                    conf_color = "green" if confidence > 0.7 else "orange" if confidence > 0.4 else "red"
                                    st.markdown(f"**Confidence:** :{conf_color}[{confidence:.0%}]")
                                with col2:
                                    if result.get('generation_error'):
                                        st.warning(f"Note: {result['generation_error']}")

                                # Explanation
                                if result.get('explanation'):
                                    with st.expander("📝 Explanation", expanded=True):
                                        st.write(result['explanation'])

                                # Results (if executed)
                                if execute_query and result.get('execution_success'):
                                    st.markdown("---")
                                    st.markdown("### Query Results")
                                    st.success(f"Query returned {result.get('row_count', 0)} rows")

                                    if result.get('data'):
                                        results_df = pd.DataFrame(result['data'])
                                        st.dataframe(results_df, use_container_width=True)

                                        # Download option
                                        csv = results_df.to_csv(index=False)
                                        st.download_button(
                                            "Download Results (CSV)",
                                            csv,
                                            f"nl_query_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                                            "text/csv"
                                        )
                                    else:
                                        st.info("Query returned no data")

                                elif execute_query and not result.get('execution_success'):
                                    st.error(f"Execution Error: {result.get('execution_error')}")

                            else:
                                st.error("Failed to generate SQL query")
                                if result.get('generation_error'):
                                    st.error(result['generation_error'])

                        except Exception as e:
                            st.error(f"Error: {str(e)}")
                else:
                    st.warning("Please enter a question")

            # Example questions
            with st.expander("💡 Example Questions"):
                examples = [
                    "Show me all tables and their row counts",
                    "What are the top 5 largest tables by row count?",
                    "List all columns in the users table",
                    "Find all foreign key relationships",
                    "Show me records created in the last 7 days",
                    "What is the average value in the price column?"
                ]
                for example in examples:
                    st.code(example, language="text")

    # Tab 4: AI-Enhanced Documentation
    with tab4:
        st.markdown('<p class="sub-header">AI-Enhanced Schema Documentation</p>', unsafe_allow_html=True)

        engine = st.session_state.connector.get_engine()
        explainer = SchemaExplainer(engine)

        if not explainer.is_available():
            st.warning("⚠️ Ollama is not available. Please ensure Ollama is running locally.")
            st.info("""
            **Setup Instructions:**
            1. Install Ollama: https://ollama.ai
            2. Run: `ollama pull llama3.2`
            3. Start Ollama service: `ollama serve`
            4. Refresh this page
            """)
        else:
            st.success("✓ Ollama is available and ready")

            st.markdown("Enhance your data dictionary with AI-generated explanations and documentation.")

            # Option 1: Enhance existing dictionary
            if st.session_state.dictionary:
                st.markdown("### Enhance Existing Dictionary")
                st.info("Add AI-generated descriptions to your current data dictionary")

                if st.button("Enhance Dictionary with AI", type="primary"):
                    with st.spinner("Generating AI explanations for all tables..."):
                        try:
                            enhanced_dict = explainer.enhance_dictionary(st.session_state.dictionary)
                            st.session_state.dictionary = enhanced_dict
                            st.success("Dictionary enhanced with AI explanations!")
                            st.rerun()
                        except Exception as e:
                            st.error(f"Error enhancing dictionary: {str(e)}")

                # Show AI enhancements if available
                if st.session_state.dictionary.get('tables'):
                    sample_table = list(st.session_state.dictionary['tables'].keys())[0]
                    sample_info = st.session_state.dictionary['tables'][sample_table]

                    if 'ai_description' in sample_info:
                        st.markdown("---")
                        st.markdown("### AI-Enhanced Preview")

                        selected_table = st.selectbox(
                            "Select table to view AI documentation:",
                            list(st.session_state.dictionary['tables'].keys())
                        )

                        table_info = st.session_state.dictionary['tables'][selected_table]

                        col1, col2 = st.columns(2)
                        with col1:
                            st.markdown("#### AI Description")
                            st.info(table_info.get('ai_description', 'N/A'))

                        with col2:
                            st.markdown("#### Purpose")
                            st.info(table_info.get('ai_purpose', 'N/A'))

                        if table_info.get('ai_usage_notes'):
                            st.markdown("#### Usage Notes")
                            st.write(table_info['ai_usage_notes'])

                        if table_info.get('ai_relationships'):
                            st.markdown("#### Relationship Explanation")
                            st.write(table_info['ai_relationships'])

            else:
                st.warning("Generate a data dictionary first (see Data Dictionary tab)")

            st.markdown("---")

            # Option 2: Generate database summary
            st.markdown("### Database Summary")
            if st.button("Generate AI Database Summary"):
                if st.session_state.dictionary:
                    with st.spinner("Generating database summary..."):
                        try:
                            summary = explainer.generate_database_summary(st.session_state.dictionary)
                            st.markdown("#### Database Overview")
                            st.info(summary)
                        except Exception as e:
                            st.error(f"Error generating summary: {str(e)}")
                else:
                    st.warning("Generate a data dictionary first")

            st.markdown("---")

            # Option 3: Individual table explanation
            st.markdown("### Individual Table Explanation")
            schema_fetcher = SchemaFetcher(engine)
            tables = schema_fetcher.get_all_tables()

            selected_explain_table = st.selectbox("Select table:", tables, key="explain_table")

            if st.button("Explain Table"):
                with st.spinner(f"Generating explanation for {selected_explain_table}..."):
                    try:
                        columns = schema_fetcher.get_table_columns(selected_explain_table)
                        explanation = explainer.explain_table(selected_explain_table, columns)

                        st.markdown(f"#### {selected_explain_table}")
                        st.markdown("**Description:**")
                        st.info(explanation['table_description'])

                        col1, col2 = st.columns(2)
                        with col1:
                            st.markdown("**Purpose:**")
                            st.write(explanation['purpose'])
                        with col2:
                            st.markdown("**Usage Notes:**")
                            st.write(explanation['usage_notes'])

                    except Exception as e:
                        st.error(f"Error: {str(e)}")

    # Tab 5: Custom Query
    with tab5:
        st.markdown('<p class="sub-header">Run Custom Profiling Query</p>', unsafe_allow_html=True)

        st.info("Execute custom SQL queries for advanced profiling and analysis.")

        query = st.text_area(
            "Enter SQL Query:",
            height=150,
            placeholder="SELECT * FROM table_name LIMIT 10"
        )

        if st.button("Execute Query", type="primary"):
            if query:
                with st.spinner("Executing query..."):
                    try:
                        profiler = DataProfiler(st.session_state.connector.get_engine())
                        results = profiler.run_custom_query(query)

                        if results:
                            st.success(f"Query returned {len(results)} rows")
                            results_df = pd.DataFrame(results)
                            st.dataframe(results_df, use_container_width=True)

                            # Download results
                            csv = results_df.to_csv(index=False)
                            st.download_button(
                                "Download Results (CSV)",
                                csv,
                                f"query_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                                "text/csv"
                            )
                        else:
                            st.warning("Query returned no results")

                    except Exception as e:
                        st.error(f"Query execution failed: {str(e)}")
            else:
                st.warning("Please enter a query")

        # Query examples
        with st.expander("Query Examples"):
            st.code("-- Find tables with most rows\nSELECT table_name, table_rows FROM information_schema.tables ORDER BY table_rows DESC;", language="sql")
            st.code("-- Check for NULL values\nSELECT COUNT(*) FROM table_name WHERE column_name IS NULL;", language="sql")
            st.code("-- Find duplicate records\nSELECT column_name, COUNT(*) FROM table_name GROUP BY column_name HAVING COUNT(*) > 1;", language="sql")

    # Tab 6: Export
    with tab6:
        st.markdown('<p class="sub-header">Export Data Dictionary</p>', unsafe_allow_html=True)

        if st.session_state.dictionary:
            col1, col2 = st.columns(2)

            with col1:
                st.markdown("#### Export as JSON")
                json_str = json.dumps(st.session_state.dictionary, indent=2, default=str)
                st.download_button(
                    "Download JSON",
                    json_str,
                    f"data_dictionary_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json",
                    "application/json",
                    use_container_width=True
                )

            with col2:
                st.markdown("#### Export as Markdown")
                if st.button("Generate Markdown", use_container_width=True):
                    with st.spinner("Generating Markdown..."):
                        try:
                            builder = DictionaryBuilder(st.session_state.connector.get_engine())
                            md_path = f"data_dictionary_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md"
                            builder.export_to_markdown(st.session_state.dictionary, md_path)

                            with open(md_path, 'r') as f:
                                md_content = f.read()

                            st.download_button(
                                "Download Markdown",
                                md_content,
                                md_path,
                                "text/markdown",
                                use_container_width=True
                            )
                        except Exception as e:
                            st.error(f"Error generating Markdown: {str(e)}")

            st.markdown("---")

            # Preview
            st.markdown("#### Dictionary Preview")
            st.json(st.session_state.dictionary, expanded=False)

        else:
            st.info("Generate a data dictionary first (see Data Dictionary tab)")


if __name__ == "__main__":
    main()
