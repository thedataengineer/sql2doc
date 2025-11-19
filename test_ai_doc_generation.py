#!/usr/bin/env python3
"""
Test AI Documentation Generation
Generates documentation for a sample e-commerce database and analyzes quality
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent / 'src'))

from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
import json

from schema_explainer import SchemaExplainer
from nl_query_generator import NaturalLanguageQueryGenerator

Base = declarative_base()

# Define sample e-commerce schema
class Customer(Base):
    __tablename__ = 'customers'
    customer_id = Column(Integer, primary_key=True)
    first_name = Column(String(50), nullable=False)
    last_name = Column(String(50), nullable=False)
    email = Column(String(100), nullable=False, unique=True)
    phone = Column(String(20))
    created_at = Column(DateTime, default=datetime.utcnow)

class Product(Base):
    __tablename__ = 'products'
    product_id = Column(Integer, primary_key=True)
    name = Column(String(200), nullable=False)
    description = Column(Text)
    price = Column(Float, nullable=False)
    stock_quantity = Column(Integer, default=0)
    category = Column(String(50))
    sku = Column(String(50), unique=True)

class Order(Base):
    __tablename__ = 'orders'
    order_id = Column(Integer, primary_key=True)
    customer_id = Column(Integer, ForeignKey('customers.customer_id'), nullable=False)
    order_date = Column(DateTime, default=datetime.utcnow)
    total_amount = Column(Float, nullable=False)
    status = Column(String(20))
    shipping_address = Column(Text)

class OrderItem(Base):
    __tablename__ = 'order_items'
    order_item_id = Column(Integer, primary_key=True)
    order_id = Column(Integer, ForeignKey('orders.order_id'), nullable=False)
    product_id = Column(Integer, ForeignKey('products.product_id'), nullable=False)
    quantity = Column(Integer, nullable=False)
    unit_price = Column(Float, nullable=False)


def main():
    print("=" * 80)
    print("AI Documentation Generation Test")
    print("=" * 80)
    print()

    # Create in-memory SQLite database
    engine = create_engine('sqlite:///:memory:')
    Base.metadata.create_all(engine)

    print("✅ Created sample e-commerce database with 4 tables:")
    print("   - customers")
    print("   - products")
    print("   - orders")
    print("   - order_items")
    print()

    # Initialize AI components
    explainer = SchemaExplainer(engine, ollama_host="http://localhost:11434")
    nl_generator = NaturalLanguageQueryGenerator(engine, ollama_host="http://localhost:11434")

    # Check if Ollama is available
    if not explainer.is_available():
        print("❌ Ollama is not available. Please ensure Ollama is running with llama3.2 model.")
        return

    print("✅ Ollama is available")
    print()

    # Test 1: Table Explanation
    print("-" * 80)
    print("TEST 1: Table Explanation (customers table)")
    print("-" * 80)

    columns = [
        {'name': 'customer_id', 'type': 'INTEGER', 'nullable': False},
        {'name': 'first_name', 'type': 'VARCHAR(50)', 'nullable': False},
        {'name': 'last_name', 'type': 'VARCHAR(50)', 'nullable': False},
        {'name': 'email', 'type': 'VARCHAR(100)', 'nullable': False},
        {'name': 'phone', 'type': 'VARCHAR(20)', 'nullable': True},
        {'name': 'created_at', 'type': 'DATETIME', 'nullable': True}
    ]

    result = explainer.explain_table('customers', columns)
    print("\nGenerated Documentation:")
    print(json.dumps(result, indent=2))
    print()

    # Test 2: Column Explanation
    print("-" * 80)
    print("TEST 2: Column Explanation")
    print("-" * 80)

    col_explanation = explainer.explain_column('orders', 'total_amount', 'FLOAT')
    print(f"\nColumn: total_amount")
    print(f"Explanation: {col_explanation}")
    print()

    # Test 3: Relationship Explanation
    print("-" * 80)
    print("TEST 3: Relationship Explanation (orders table)")
    print("-" * 80)

    foreign_keys = [
        {
            'constrained_columns': ['customer_id'],
            'referred_table': 'customers',
            'referred_columns': ['customer_id']
        }
    ]

    rel_explanation = explainer.generate_relationship_explanation('orders', foreign_keys)
    print(f"\nRelationship Explanation:")
    print(rel_explanation)
    print()

    # Test 4: Natural Language Query Generation
    print("-" * 80)
    print("TEST 4: Natural Language Query Generation")
    print("-" * 80)

    questions = [
        "Show me all customers who placed orders in the last 30 days",
        "What are the top 5 products by total sales?",
        "Find customers who haven't placed any orders"
    ]

    for i, question in enumerate(questions, 1):
        print(f"\nQuestion {i}: {question}")
        result = nl_generator.generate_sql(question)
        print(f"Generated SQL: {result.get('sql', 'N/A')}")
        print(f"Explanation: {result.get('explanation', 'N/A')}")
        print()

    # Test 5: Database Summary
    print("-" * 80)
    print("TEST 5: Database Summary")
    print("-" * 80)

    summary = explainer.generate_database_summary()
    print(f"\nDatabase Summary:")
    print(summary)
    print()

    print("=" * 80)
    print("✅ Documentation Generation Complete!")
    print("=" * 80)
    print()
    print("NEXT STEPS:")
    print("1. Review generated documentation above")
    print("2. Compare with ideal documentation (see REFERENCE_DOCS.md)")
    print("3. Identify areas for improvement")
    print("4. Update prompts in src/schema_explainer.py and src/nl_query_generator.py")
    print()

if __name__ == '__main__':
    main()