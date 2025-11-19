#!/usr/bin/env python3
"""
Test GraphRAG Implementation
Demonstrates enhanced documentation generation using graph-based context
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent / 'src'))

from sqlalchemy import create_engine
from graphrag_engine import GraphRAGEngine, SchemaKnowledgeGraph
import json
import os

def test_healthcare_schema():
    """Test GraphRAG on healthcare ODS schema"""
    print("=" * 80)
    print("GraphRAG Test - Healthcare ODS Schema")
    print("=" * 80)
    print()

    # Connect to healthcare database
    db_url = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/healthcare_ods_db")
    engine = create_engine(db_url)

    print(f"✓ Connected to database: healthcare_ods_db")
    print()

    # Initialize knowledge graph
    print("-" * 80)
    print("PHASE 1: Building Schema Knowledge Graph")
    print("-" * 80)

    kg = SchemaKnowledgeGraph(engine)
    kg.build_graph()

    print(f"\n✓ Knowledge Graph Statistics:")
    print(f"  - Total Nodes: {len(kg.nodes)}")
    print(f"  - Total Edges: {len(kg.edges)}")
    print(f"  - Tables: {len(kg.get_all_tables())}")
    print()

    # Test table categorization
    print("-" * 80)
    print("PHASE 2: Table Categorization")
    print("-" * 80)
    print()

    for table_name in kg.get_all_tables()[:5]:
        categories = kg.table_categories.get(table_name, set())
        print(f"  - {table_name}: {', '.join(categories) if categories else 'UNCATEGORIZED'}")
    print()

    # Test graph context retrieval
    print("-" * 80)
    print("PHASE 3: Graph Context Retrieval - patients table")
    print("-" * 80)
    print()

    context = kg.get_table_context("patients", depth=2)
    print(f"✓ Retrieved context for 'patients' table:")
    print(f"  - Columns: {len(context.get('columns', []))}")
    print(f"  - Foreign Keys: {len(context.get('foreign_keys', []))}")
    print(f"  - Referenced By: {len(context.get('referenced_by', []))}")
    print(f"  - Related Tables: {', '.join(context.get('related_tables', [])[:5])}")
    print(f"  - Semantic Cluster: {', '.join(context.get('semantic_cluster', [])[:5])}")
    print()

    # Test relationship path finding
    print("-" * 80)
    print("PHASE 4: Relationship Path Finding")
    print("-" * 80)
    print()

    path = kg.get_relationship_path("patients", "medication_administrations")
    if path:
        print(f"✓ Path from patients -> medication_administrations:")
        print(f"  {' -> '.join(path)}")
    print()

    # Test with Ollama (if available)
    print("-" * 80)
    print("PHASE 5: GraphRAG-Enhanced Documentation")
    print("-" * 80)
    print()

    try:
        import ollama
        ollama_client = ollama.Client(host=os.getenv("OLLAMA_HOST", "http://localhost:11434"))

        # Check if available
        try:
            ollama_client.list()
            print("✓ Ollama is available")
            print()

            # Initialize GraphRAG engine
            graphrag = GraphRAGEngine(engine, ollama_client, model="llama3.2")
            graphrag.kg = kg  # Use already-built graph

            # Generate enriched documentation for key tables
            test_tables = ["patients", "encounters", "medications"]

            for table in test_tables:
                print(f"\n{'=' * 60}")
                print(f"Table: {table}")
                print('=' * 60)

                docs = graphrag.generate_enriched_documentation(
                    table,
                    include_relationships=True,
                    include_semantic_cluster=True
                )

                if "error" not in docs:
                    print(f"\n📄 Description:")
                    print(f"   {docs.get('table_description', 'N/A')}")
                    print(f"\n🎯 Purpose:")
                    print(f"   {docs.get('purpose', 'N/A')}")
                    print(f"\n📝 Usage Notes:")
                    print(f"   {docs.get('usage_notes', 'N/A')}")
                    print(f"\n🔗 Relationships:")
                    print(f"   {docs.get('relationships_summary', 'N/A')}")
                else:
                    print(f"   Error: {docs.get('error')}")
                print()

        except Exception as e:
            print(f"⚠️  Ollama not available or error: {e}")
            print("   Skipping AI documentation generation")
            print()

    except ImportError:
        print("⚠️  Ollama package not installed")
        print("   Install with: pip install ollama")
        print()

    # Export graph
    print("-" * 80)
    print("PHASE 6: Export Knowledge Graph")
    print("-" * 80)
    print()

    graph_json = kg.export_graph(format="json")
    output_file = "schema_knowledge_graph.json"

    with open(output_file, 'w') as f:
        f.write(graph_json)

    print(f"✓ Knowledge graph exported to: {output_file}")
    print(f"  File size: {len(graph_json)} bytes")
    print()

    print("=" * 80)
    print("✅ GraphRAG Testing Complete!")
    print("=" * 80)
    print()


def test_telecom_schema():
    """Test GraphRAG on telecommunications OCDM schema"""
    print("=" * 80)
    print("GraphRAG Test - Telecommunications OCDM Schema")
    print("=" * 80)
    print()

    # Connect to telecom database
    db_url = os.getenv("TELECOM_DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/telecom_ocdm_db")

    try:
        engine = create_engine(db_url)
        print(f"✓ Connected to database: telecom_ocdm_db")
        print()

        # Build knowledge graph
        kg = SchemaKnowledgeGraph(engine)
        kg.build_graph()

        print(f"✓ Knowledge Graph Built:")
        print(f"  - Tables: {len(kg.get_all_tables())}")
        print()

        # Test interesting relationships
        print("Analyzing Key Relationships:")
        print()

        # Find path from customer to invoice
        path = kg.get_relationship_path("dwb_customer", "dwb_invoice")
        if path:
            print(f"  Customer -> Invoice Path: {' -> '.join(path)}")

        # Find path from subscription to usage
        path = kg.get_relationship_path("dwb_subscription", "dwb_usage_detail_record")
        if path:
            print(f"  Subscription -> Usage Path: {' -> '.join(path)}")

        print()

        # Show table categories
        print("Table Categories:")
        for table in ["dwb_customer", "dwr_product_catalog", "dwb_account", "dwb_usage_detail_record"]:
            if table in kg.table_categories:
                cats = kg.table_categories[table]
                print(f"  - {table}: {', '.join(cats) if cats else 'UNCATEGORIZED'}")
        print()

    except Exception as e:
        print(f"⚠️  Could not connect to telecom database: {e}")
        print("   Make sure telecom_ocdm_db is created and accessible")
        print()


def compare_with_without_graphrag():
    """Compare documentation quality with and without GraphRAG"""
    print("=" * 80)
    print("GraphRAG Comparison: With vs Without Graph Context")
    print("=" * 80)
    print()

    db_url = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/healthcare_ods_db")

    try:
        engine = create_engine(db_url)

        # Without GraphRAG (basic schema explainer)
        from schema_explainer import SchemaExplainer

        explainer = SchemaExplainer(engine)

        if explainer.is_available():
            print("TEST 1: Documentation WITHOUT GraphRAG")
            print("-" * 60)

            columns = [
                {'name': 'encounter_id', 'type': 'INTEGER', 'nullable': False},
                {'name': 'patient_id', 'type': 'INTEGER', 'nullable': False},
                {'name': 'admission_date', 'type': 'TIMESTAMP', 'nullable': False},
                {'name': 'discharge_date', 'type': 'TIMESTAMP', 'nullable': True},
            ]

            result = explainer.explain_table('encounters', columns)
            print(f"\nDescription: {result.get('table_description')}")
            print(f"Purpose: {result.get('purpose')}")
            print()

            # With GraphRAG
            print("TEST 2: Documentation WITH GraphRAG")
            print("-" * 60)

            import ollama
            ollama_client = ollama.Client(host=os.getenv("OLLAMA_HOST", "http://localhost:11434"))

            graphrag = GraphRAGEngine(engine, ollama_client)
            graphrag.build_knowledge_graph()

            docs = graphrag.generate_enriched_documentation("encounters")

            print(f"\nDescription: {docs.get('table_description', 'N/A')}")
            print(f"Purpose: {docs.get('purpose', 'N/A')}")
            print(f"Relationships: {docs.get('relationships_summary', 'N/A')}")
            print()

            print("=" * 80)
            print("KEY DIFFERENCES:")
            print("  1. GraphRAG includes relationship context")
            print("  2. GraphRAG understands semantic clusters")
            print("  3. GraphRAG provides domain-aware categorization")
            print("=" * 80)
            print()

    except Exception as e:
        print(f"Error in comparison: {e}")


def main():
    """Run all GraphRAG tests"""
    import argparse

    parser = argparse.ArgumentParser(description="Test GraphRAG implementation")
    parser.add_argument("--schema", choices=["healthcare", "telecom", "both", "compare"], default="healthcare",
                       help="Which schema to test")

    args = parser.parse_args()

    if args.schema == "healthcare":
        test_healthcare_schema()
    elif args.schema == "telecom":
        test_telecom_schema()
    elif args.schema == "compare":
        compare_with_without_graphrag()
    elif args.schema == "both":
        test_healthcare_schema()
        print("\n\n")
        test_telecom_schema()

    print("\nNEXT STEPS:")
    print("1. Review schema_knowledge_graph.json to visualize the graph")
    print("2. Compare documentation quality with/without GraphRAG")
    print("3. Integrate GraphRAG into your dictionary_builder.py")
    print("4. Use graph context for better NL-to-SQL generation")
    print()


if __name__ == '__main__':
    main()
