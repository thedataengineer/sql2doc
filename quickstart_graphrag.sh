#!/bin/bash
# QuickStart GraphRAG - Get up and running in 5 minutes

set -e

echo "========================================"
echo "  GraphRAG QuickStart Setup"
echo "========================================"
echo ""

# Check Python
echo "Step 1: Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Please install Python 3.8+"
    exit 1
fi
echo "✅ Python found: $(python3 --version)"
echo ""

# Check PostgreSQL
echo "Step 2: Checking PostgreSQL..."
if ! command -v psql &> /dev/null; then
    echo "⚠️  PostgreSQL client not found. Install with:"
    echo "   macOS: brew install postgresql"
    echo "   Ubuntu: sudo apt-get install postgresql-client"
    echo ""
fi

# Install Python dependencies
echo "Step 3: Installing Python dependencies..."
pip3 install -q networkx sqlalchemy psycopg2-binary ollama
echo "✅ Dependencies installed"
echo ""

# Check Ollama
echo "Step 4: Checking Ollama..."
if ! command -v ollama &> /dev/null; then
    echo "⚠️  Ollama not found. Install from: https://ollama.ai"
    echo "   After installation, run: ollama pull llama3.2"
    echo ""
else
    echo "✅ Ollama found"

    # Check if llama3.2 model exists
    if ollama list | grep -q "llama3.2"; then
        echo "✅ llama3.2 model available"
    else
        echo "📥 Pulling llama3.2 model..."
        ollama pull llama3.2
    fi
    echo ""
fi

# Load sample databases
echo "Step 5: Loading sample databases..."
echo ""
echo "Choose which database to load:"
echo "  1) Healthcare ODS (22 tables, clinical operations)"
echo "  2) Telecommunications OCDM (25+ tables, telecom operations)"
echo "  3) Both"
echo "  4) Skip (use existing database)"
echo ""
read -p "Enter choice (1-4): " choice

DB_USER=${POSTGRES_USER:-postgres}
DB_PASS=${POSTGRES_PASSWORD:-postgres}
DB_HOST=${POSTGRES_HOST:-localhost}
DB_PORT=${POSTGRES_PORT:-5432}

case $choice in
    1)
        echo "Loading Healthcare ODS..."
        createdb -h $DB_HOST -p $DB_PORT -U $DB_USER healthcare_ods_db 2>/dev/null || echo "Database already exists"
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -f test_data/healthcare_ods_schema.sql
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -f test_data/healthcare_ods_sample_data.sql
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -f test_data/healthcare_ods_procedures.sql
        export DATABASE_URL="postgresql://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/healthcare_ods_db"
        echo "✅ Healthcare ODS loaded"
        ;;
    2)
        echo "Loading Telecommunications OCDM..."
        createdb -h $DB_HOST -p $DB_PORT -U $DB_USER telecom_ocdm_db 2>/dev/null || echo "Database already exists"
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -f test_data/telecom_ocdm_schema.sql
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -f test_data/telecom_ocdm_sample_data.sql
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -f test_data/telecom_ocdm_procedures.sql
        export DATABASE_URL="postgresql://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/telecom_ocdm_db"
        echo "✅ Telecom OCDM loaded"
        ;;
    3)
        echo "Loading both databases..."
        createdb -h $DB_HOST -p $DB_PORT -U $DB_USER healthcare_ods_db 2>/dev/null || echo "Healthcare DB already exists"
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -f test_data/healthcare_ods_schema.sql
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -f test_data/healthcare_ods_sample_data.sql
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -f test_data/healthcare_ods_procedures.sql

        createdb -h $DB_HOST -p $DB_PORT -U $DB_USER telecom_ocdm_db 2>/dev/null || echo "Telecom DB already exists"
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -f test_data/telecom_ocdm_schema.sql
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -f test_data/telecom_ocdm_sample_data.sql
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -f test_data/telecom_ocdm_procedures.sql

        export DATABASE_URL="postgresql://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/healthcare_ods_db"
        echo "✅ Both databases loaded"
        ;;
    4)
        echo "Skipping database load"
        if [ -z "$DATABASE_URL" ]; then
            echo "⚠️  Set DATABASE_URL environment variable to your database"
        fi
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
echo ""

# Run tests
echo "Step 6: Running GraphRAG tests..."
echo ""

if [ -n "$DATABASE_URL" ]; then
    echo "Testing with database: $DATABASE_URL"
    python3 test_graphrag.py --schema healthcare

    echo ""
    echo "========================================"
    echo "  ✅ Setup Complete!"
    echo "========================================"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Review the generated graph:"
    echo "   cat schema_knowledge_graph.json | jq"
    echo ""
    echo "2. Compare documentation quality:"
    echo "   python3 test_graphrag.py --schema compare"
    echo ""
    echo "3. Test on telecom schema:"
    echo "   python3 test_graphrag.py --schema telecom"
    echo ""
    echo "4. Read the guide:"
    echo "   cat GRAPHRAG_GUIDE.md"
    echo ""
    echo "5. Try it in your code:"
    echo "   from graphrag_engine import GraphRAGEngine"
    echo "   # See GRAPHRAG_GUIDE.md for examples"
    echo ""
else
    echo "⚠️  No DATABASE_URL set. Configure your database connection:"
    echo "   export DATABASE_URL='postgresql://user:pass@localhost/dbname'"
    echo "   python3 test_graphrag.py --schema healthcare"
fi
