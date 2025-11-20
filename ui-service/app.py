"""
SQL2Doc UI - Streamlit Frontend
Production-ready UI with dynamic database discovery
"""

import streamlit as st
import requests
import pandas as pd
import plotly.graph_objects as go
import plotly.express as px
from typing import Dict, List, Optional
import os
import json

# Configuration
GRAPHRAG_API_URL = os.getenv("GRAPHRAG_API_URL", "http://graphrag:8000")

# Page config
st.set_page_config(
    page_title="SQL2Doc - GraphRAG Enhanced",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        font-weight: bold;
        color: #1f77b4;
    }
    .database-banner {
        background: linear-gradient(90deg, #1e3a8a 0%, #3b82f6 100%);
        color: white;
        padding: 0.75rem 1.5rem;
        border-radius: 0.5rem;
        margin-bottom: 1.5rem;
        font-size: 1.1rem;
        font-weight: bold;
        text-align: center;
    }
</style>
""", unsafe_allow_html=True)


# Helper functions
def check_graphrag_health() -> Dict:
    """Check GraphRAG service health."""
    try:
        response = requests.get(f"{GRAPHRAG_API_URL}/health", timeout=5)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}


def fetch_available_databases(host: str, port: str, user: str, password: str) -> List[Dict]:
    """Fetch list of available databases from PostgreSQL server."""
    try:
        import psycopg2
        conn = psycopg2.connect(
            host=host,
            port=int(port),
            database="postgres",
            user=user,
            password=password,
            connect_timeout=5
        )
        cursor = conn.cursor()
        cursor.execute("""
            SELECT datname, pg_size_pretty(pg_database_size(datname)) as size
            FROM pg_database
            WHERE datistemplate = false
            AND datname NOT IN ('postgres', 'azure_maintenance', 'azure_sys')
            ORDER BY datname;
        """)
        databases = [{"name": row[0], "size": row[1]} for row in cursor.fetchall()]
        cursor.close()
        conn.close()
        return databases
    except Exception as e:
        st.warning(f"Could not fetch databases: {e}")
        return []


def build_knowledge_graph(database_id: str, database_url: str) -> Dict:
    """Build knowledge graph for database."""
    try:
        response = requests.post(
            f"{GRAPHRAG_API_URL}/graph/build",
            json={"database_id": database_id, "database_url": database_url},
            timeout=120
        )
        response.raise_for_status()
        return response.json()
    except Exception as e:
        return {"error": str(e)}


def get_tables(database_id: str) -> List[Dict]:
    """Get list of tables from knowledge graph."""
    try:
        response = requests.get(f"{GRAPHRAG_API_URL}/graph/{database_id}/tables", timeout=30)
        response.raise_for_status()
        return response.json().get("tables", [])
    except Exception as e:
        st.error(f"Error fetching tables: {e}")
        return []


def get_table_context(database_id: str, table_name: str, depth: int = 2) -> Optional[Dict]:
    """Get rich context for a table."""
    try:
        response = requests.post(
            f"{GRAPHRAG_API_URL}/graph/context",
            json={"database_id": database_id, "table_name": table_name, "depth": depth},
            timeout=30
        )
        response.raise_for_status()
        return response.json().get("context")
    except Exception as e:
        st.error(f"Error fetching context: {e}")
        return None


def generate_documentation(database_id: str, table_name: str) -> Optional[Dict]:
    """Generate AI-enhanced documentation."""
    try:
        response = requests.post(
            f"{GRAPHRAG_API_URL}/documentation/generate",
            json={
                "database_id": database_id,
                "table_name": table_name,
                "include_relationships": True,
                "include_semantic_cluster": True
            },
            timeout=240
        )
        response.raise_for_status()
        return response.json().get("documentation")
    except Exception as e:
        st.error(f"Error generating documentation: {e}")
        return None


# Main app
def main():
    st.markdown('<p class="main-header">📊 SQL2Doc - GraphRAG Enhanced</p>', unsafe_allow_html=True)

    # Sidebar
    with st.sidebar:
        st.markdown("### Configuration")

        # Check service health
        health = check_graphrag_health()

        if health.get("status") == "healthy":
            st.success("✅ GraphRAG Service: Online")
            st.info(f"🤖 Ollama: {health.get('ollama_status', 'unknown')}")
            st.metric("Active Databases", health.get("active_databases", 0))
        else:
            st.error("❌ GraphRAG Service: Offline")
            st.warning(f"Error: {health.get('error', 'Unknown error')}")
            st.stop()

        st.markdown("---")

        # Database configuration
        st.subheader("🗄️ Database Connection")

        # Connection method selector
        conn_method = st.radio(
            "Connection Method",
            ["Preset Database", "Custom Connection"],
            help="Choose a preset database or configure custom connection"
        )

        if conn_method == "Preset Database":
            # Server connection details (shared for all databases)
            st.info("📡 PostgreSQL Server Configuration")

            col1, col2 = st.columns(2)
            with col1:
                server_host = st.text_input("Server Host", value="10.0.2.4", key="server_host")
                server_user = st.text_input("Username", value="sqladmin", key="server_user")
            with col2:
                server_port = st.text_input("Server Port", value="5432", key="server_port")
                server_password = st.text_input("Password", value="Sql2Doc2024!ML", type="password", key="server_password")

            # Fetch available databases button
            if st.button("🔍 Fetch Available Databases", type="secondary", use_container_width=True):
                with st.spinner("Fetching databases from server..."):
                    available_dbs = fetch_available_databases(
                        server_host,
                        server_port,
                        server_user,
                        server_password
                    )
                    if available_dbs:
                        st.session_state.available_databases = available_dbs
                        st.success(f"✅ Found {len(available_dbs)} databases")
                    else:
                        st.error("❌ Could not fetch databases. Check connection settings.")

            # Show available databases dropdown if fetched
            if hasattr(st.session_state, 'available_databases') and st.session_state.available_databases:
                st.markdown("---")
                st.markdown("**📚 Available Databases**")

                # Format database options with metadata
                db_options = []
                db_map = {}
                for db in st.session_state.available_databases:
                    label = f"{db['name']} ({db.get('size', 'unknown size')})"
                    db_options.append(label)
                    db_map[label] = db['name']

                selected_db_label = st.selectbox(
                    "Select Database",
                    options=db_options,
                    help="Choose from available databases on the server"
                )

                # Get actual database name
                default_db_name = db_map[selected_db_label]

                # Generate database_id from name (remove _db suffix if exists)
                database_id = default_db_name.replace("_db", "").replace("_", "-")

                # Use server connection details
                default_host = server_host
                default_user = server_user
                default_password = server_password
                default_port = server_port

                # Build connection string
                database_url_input = f"postgresql://{default_user}:{default_password}@{default_host}:{default_port}/{default_db_name}"

                st.caption(f"📊 Database: `{default_db_name}`")
                st.caption(f"🔗 Host: `{default_host}:{default_port}`")

            else:
                # Fallback to hardcoded presets
                st.markdown("---")
                st.info("💡 Click 'Fetch Available Databases' or select a preset below")

                db_preset = st.selectbox(
                    "Preset Databases",
                    options=[
                        "Healthcare ODS (healthcare_ods_db)",
                        "Telecom OCDM (telecom_ocdm_db)",
                        "Legal Collections (legal_collections_db)"
                    ],
                    help="Quick access to common databases"
                )

                # Parse preset selection
                if "Healthcare" in db_preset:
                    database_id = "healthcare"
                    default_db_name = "healthcare_ods_db"
                elif "Telecom" in db_preset:
                    database_id = "telecom"
                    default_db_name = "telecom_ocdm_db"
                else:  # Legal Collections
                    database_id = "legal"
                    default_db_name = "legal_collections_db"

                # Use server connection details
                default_host = server_host
                default_user = server_user
                default_password = server_password
                default_port = server_port

                # Build connection string
                database_url_input = f"postgresql://{default_user}:{default_password}@{default_host}:{default_port}/{default_db_name}"

                st.caption(f"📊 Database: `{default_db_name}`")
                st.caption(f"🔗 Host: `{default_host}:{default_port}`")

        else:  # Custom Connection
            st.info("Configure a custom PostgreSQL database connection")

            conn_host = st.text_input("Host", value="localhost")
            conn_port = st.text_input("Port", value="5432")
            conn_database = st.text_input("Database Name", value="")
            conn_user = st.text_input("Username", value="sqladmin")
            conn_password = st.text_input("Password", type="password")
            database_id = st.text_input("Database ID", value="custom")

            if conn_database and conn_user and conn_password:
                database_url_input = f"postgresql://{conn_user}:{conn_password}@{conn_host}:{conn_port}/{conn_database}"
            else:
                database_url_input = ""
                st.warning("⚠️ Please fill in all connection fields")

        st.markdown("---")

        # Build knowledge graph button
        col1, col2 = st.columns([3, 1])
        with col1:
            build_button = st.button("🔨 Build Knowledge Graph", type="primary", use_container_width=True)
        with col2:
            if st.button("🔄", help="Refresh page"):
                st.rerun()

        if build_button:
            if not database_url_input:
                st.error("⚠️ Please provide database URL")
            else:
                with st.spinner(f"Building knowledge graph for {database_id}..."):
                    result = build_knowledge_graph(database_id, database_url_input)

                    if "error" in result:
                        st.error(f"❌ Error: {result['error']}")
                    elif result.get("status") == "success":
                        stats = result.get("statistics", {})
                        st.success(f"✅ Knowledge graph built successfully!")

                        # Show statistics
                        col1, col2, col3 = st.columns(3)
                        with col1:
                            st.metric("Tables", stats.get("total_tables", 0))
                        with col2:
                            st.metric("Nodes", stats.get("total_nodes", 0))
                        with col3:
                            st.metric("Edges", stats.get("total_edges", 0))

                        st.info("💡 Switch to 'Tables Overview' tab to explore the schema")

    # Main content
    st.markdown(f'''
        <div class="database-banner">
            🗄️ Database: {database_id if 'database_id' in locals() else 'None'}
        </div>
    ''', unsafe_allow_html=True)

    tabs = st.tabs([
        "📋 Tables Overview",
        "🔍 Table Explorer",
        "📚 Documentation Generator"
    ])

    # Tab 1: Tables Overview
    with tabs[0]:
        st.markdown("### Database Tables")

        tables = get_tables(database_id if 'database_id' in locals() else "")

        if not tables:
            st.info("No tables found. Build the knowledge graph first.")
        else:
            # Summary metrics
            col1, col2, col3 = st.columns(3)
            total_tables = len(tables)
            total_rows = sum(t.get("row_count", 0) for t in tables)

            with col1:
                st.metric("Total Tables", total_tables)
            with col2:
                st.metric("Total Rows", f"{total_rows:,}")
            with col3:
                avg_columns = sum(t.get("column_count", 0) for t in tables) / total_tables if total_tables > 0 else 0
                st.metric("Avg Columns", f"{avg_columns:.1f}")

            st.markdown("---")

            # Display tables
            for table in tables:
                with st.expander(f"📁 {table['name']} ({table.get('row_count', 0):,} rows)"):
                    st.write(f"**Columns:** {table.get('column_count', 0)}")

    # Tab 2: Table Explorer
    with tabs[1]:
        st.markdown("### Table Explorer")

        tables = get_tables(database_id if 'database_id' in locals() else "")

        if not tables:
            st.info("No tables found. Build the knowledge graph first.")
        else:
            selected_table = st.selectbox("Select Table", options=[t["name"] for t in tables])
            depth = st.slider("Graph Traversal Depth", 1, 5, 2)

            if st.button("🔍 Explore Table", type="primary"):
                with st.spinner("Fetching context..."):
                    context = get_table_context(database_id, selected_table, depth)

                    if context:
                        st.success(f"✅ Context loaded for {selected_table}")

                        # Display context
                        col1, col2 = st.columns(2)

                        with col1:
                            st.markdown("### 📋 Columns")
                            columns_df = pd.DataFrame(context.get("columns", []))
                            if not columns_df.empty:
                                st.dataframe(columns_df, use_container_width=True)

                        with col2:
                            st.markdown("### 🔗 Foreign Keys")
                            fks = context.get("foreign_keys", [])
                            if fks:
                                for fk in fks:
                                    st.write(f"→ {fk['referenced_table']}")
                            else:
                                st.info("No foreign keys")

    # Tab 3: Documentation Generator
    with tabs[2]:
        st.markdown("### AI Documentation Generator")

        tables = get_tables(database_id if 'database_id' in locals() else "")

        if not tables:
            st.info("No tables found. Build the knowledge graph first.")
        else:
            selected_table = st.selectbox("Select Table to Document", options=[t["name"] for t in tables], key="doc_table_select")

            if st.button("📚 Generate Documentation", type="primary"):
                with st.spinner("🤖 Generating AI-enhanced documentation..."):
                    docs = generate_documentation(database_id, selected_table)

                    if docs:
                        st.success("✅ Documentation generated successfully!")

                        # Display documentation
                        st.markdown("### 📄 Table Description")
                        st.write(docs.get("table_description", "No description available"))

                        st.markdown("### 🎯 Purpose")
                        st.info(docs.get("purpose", "No purpose information"))

                        st.markdown("### 📝 Usage Notes")
                        st.write(docs.get("usage_notes", "No usage notes"))

                        # Export options
                        st.markdown("---")
                        col1, col2 = st.columns(2)

                        with col1:
                            st.download_button(
                                "💾 Download as JSON",
                                data=json.dumps(docs, indent=2),
                                file_name=f"{selected_table}_documentation.json",
                                mime="application/json"
                            )

                        with col2:
                            md_content = f"""# {selected_table}

## Description
{docs.get("table_description", "")}

## Purpose
{docs.get("purpose", "")}

## Usage Notes
{docs.get("usage_notes", "")}
"""
                            st.download_button(
                                "📄 Download as Markdown",
                                data=md_content,
                                file_name=f"{selected_table}_documentation.md",
                                mime="text/markdown"
                            )


if __name__ == "__main__":
    main()
