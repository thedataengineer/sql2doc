#!/usr/bin/env python3
"""
Test AI Documentation with Ambiguous/Real-World Schema
Tests challenging scenarios: abbreviations, flex fields, generic names
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent / 'src'))

from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, ForeignKey, Text, Boolean
from sqlalchemy.orm import declarative_base
from datetime import datetime
import json

from schema_explainer import SchemaExplainer

Base = declarative_base()

# Real-world challenging schema with ambiguous names
class Entity(Base):
    """Generic entity table - could be anything!"""
    __tablename__ = 'entity'
    ent_id = Column(Integer, primary_key=True)
    ent_type = Column(String(10))  # What type? Who knows!
    ent_nm = Column(String(100))   # Abbreviated name
    ent_cd = Column(String(20))    # Code? What kind?
    status = Column(String(1))     # A, I, D? What do they mean?
    created_dt = Column(DateTime)
    modified_dt = Column(DateTime)
    created_by = Column(String(50))
    modified_by = Column(String(50))

class Transaction(Base):
    """Transactions with flex fields"""
    __tablename__ = 'txn'
    txn_id = Column(Integer, primary_key=True)
    ent_id = Column(Integer, ForeignKey('entity.ent_id'))
    txn_dt = Column(DateTime)
    txn_type = Column(String(3))   # ACC, PYM, REF?
    amt = Column(Float)            # Amount of what?
    cur = Column(String(3))        # Currency
    ref_no = Column(String(50))    # Reference to what?

    # Flex fields - commonly seen in enterprise systems
    attr1 = Column(String(255))
    attr2 = Column(String(255))
    attr3 = Column(String(255))
    value1 = Column(Float)
    value2 = Column(Float)
    flag1 = Column(Boolean)
    flag2 = Column(Boolean)
    note = Column(Text)

class Relationship(Base):
    """Self-referencing relationships table"""
    __tablename__ = 'rel'
    rel_id = Column(Integer, primary_key=True)
    src_id = Column(Integer)       # Source what?
    tgt_id = Column(Integer)       # Target what?
    rel_type = Column(String(10))  # REL, CHD, PAR?
    eff_dt = Column(DateTime)      # Effective date
    exp_dt = Column(DateTime)      # Expiry date
    priority = Column(Integer)     # Priority of what?

class Data(Base):
    """Generic data table - the worst!"""
    __tablename__ = 'data'
    id = Column(Integer, primary_key=True)
    key = Column(String(50))
    value = Column(Text)
    type = Column(String(20))
    parent_id = Column(Integer, ForeignKey('data.id'))
    seq = Column(Integer)

    # More flex fields
    field1 = Column(String(100))
    field2 = Column(String(100))
    field3 = Column(String(100))
    num1 = Column(Float)
    num2 = Column(Float)
    date1 = Column(DateTime)
    date2 = Column(DateTime)


def main():
    print("=" * 100)
    print("AI Documentation Test: Ambiguous & Real-World Schema")
    print("Challenge: Can AI infer meaning from abbreviated/generic column names?")
    print("=" * 100)
    print()

    # Create in-memory SQLite database
    engine = create_engine('sqlite:///:memory:')
    Base.metadata.create_all(engine)

    print("✅ Created challenging database schema with:")
    print("   - Abbreviated column names (ent_nm, txn_dt, amt)")
    print("   - Generic flex fields (attr1, value1, field1)")
    print("   - Ambiguous relationships (src_id, tgt_id)")
    print("   - Single-character codes (status: A/I/D)")
    print()

    # Initialize AI explainer
    explainer = SchemaExplainer(engine, ollama_host="http://localhost:11434")

    if not explainer.is_available():
        print("❌ Ollama is not available")
        return

    print("✅ Ollama is available\n")

    # Test 1: Entity table with abbreviations
    print("=" * 100)
    print("TEST 1: Abbreviated Column Names (entity table)")
    print("=" * 100)

    columns = [
        {'name': 'ent_id', 'type': 'INTEGER', 'nullable': False},
        {'name': 'ent_type', 'type': 'VARCHAR(10)', 'nullable': True},
        {'name': 'ent_nm', 'type': 'VARCHAR(100)', 'nullable': True},
        {'name': 'ent_cd', 'type': 'VARCHAR(20)', 'nullable': True},
        {'name': 'status', 'type': 'VARCHAR(1)', 'nullable': True},
        {'name': 'created_dt', 'type': 'DATETIME', 'nullable': True},
        {'name': 'modified_dt', 'type': 'DATETIME', 'nullable': True},
        {'name': 'created_by', 'type': 'VARCHAR(50)', 'nullable': True},
        {'name': 'modified_by', 'type': 'VARCHAR(50)', 'nullable': True}
    ]

    result = explainer.explain_table('entity', columns)
    print("\nAI-Generated Documentation:")
    print(json.dumps(result, indent=2))
    print()

    print("IDEAL DOCUMENTATION:")
    print(json.dumps({
        "table_description": "Entity master table storing business entities such as customers, suppliers, or partners. Uses abbreviated naming conventions common in legacy systems.",
        "purpose": "Central repository for entities across the system. The 'ent_type' field indicates entity classification (e.g., 'CUST', 'SUPP'). Status field uses single-character codes: A=Active, I=Inactive, D=Deleted.",
        "usage_notes": "Entity code (ent_cd) serves as business key. Always check status before processing. Audit fields (created_dt, modified_dt, created_by, modified_by) track changes."
    }, indent=2))
    print()

    # Test 2: Flex fields
    print("=" * 100)
    print("TEST 2: Flex Fields (txn table)")
    print("=" * 100)

    columns = [
        {'name': 'txn_id', 'type': 'INTEGER', 'nullable': False},
        {'name': 'ent_id', 'type': 'INTEGER', 'nullable': False},
        {'name': 'txn_dt', 'type': 'DATETIME', 'nullable': True},
        {'name': 'txn_type', 'type': 'VARCHAR(3)', 'nullable': True},
        {'name': 'amt', 'type': 'FLOAT', 'nullable': True},
        {'name': 'cur', 'type': 'VARCHAR(3)', 'nullable': True},
        {'name': 'ref_no', 'type': 'VARCHAR(50)', 'nullable': True},
        {'name': 'attr1', 'type': 'VARCHAR(255)', 'nullable': True},
        {'name': 'attr2', 'type': 'VARCHAR(255)', 'nullable': True},
        {'name': 'attr3', 'type': 'VARCHAR(255)', 'nullable': True},
        {'name': 'value1', 'type': 'FLOAT', 'nullable': True},
        {'name': 'value2', 'type': 'FLOAT', 'nullable': True},
        {'name': 'flag1', 'type': 'BOOLEAN', 'nullable': True},
        {'name': 'flag2', 'type': 'BOOLEAN', 'nullable': True},
        {'name': 'note', 'type': 'TEXT', 'nullable': True}
    ]

    result = explainer.explain_table('txn', columns)
    print("\nAI-Generated Documentation:")
    print(json.dumps(result, indent=2))
    print()

    print("IDEAL DOCUMENTATION:")
    print(json.dumps({
        "table_description": "Transaction table with configurable flex fields for business-specific attributes. Supports various transaction types (ACC=Accrual, PYM=Payment, REF=Refund).",
        "purpose": "Stores financial transactions linked to entities. Flex fields (attr1-3, value1-2, flag1-2) allow customization without schema changes - meaning varies by implementation.",
        "usage_notes": "Currency (cur) uses ISO 4217 codes (USD, EUR, etc.). Reference number (ref_no) links to external systems. Flex field usage should be documented separately per deployment."
    }, indent=2))
    print()

    # Test 3: Self-referencing ambiguous relationships
    print("=" * 100)
    print("TEST 3: Ambiguous Relationships (rel table)")
    print("=" * 100)

    columns = [
        {'name': 'rel_id', 'type': 'INTEGER', 'nullable': False},
        {'name': 'src_id', 'type': 'INTEGER', 'nullable': True},
        {'name': 'tgt_id', 'type': 'INTEGER', 'nullable': True},
        {'name': 'rel_type', 'type': 'VARCHAR(10)', 'nullable': True},
        {'name': 'eff_dt', 'type': 'DATETIME', 'nullable': True},
        {'name': 'exp_dt', 'type': 'DATETIME', 'nullable': True},
        {'name': 'priority', 'type': 'INTEGER', 'nullable': True}
    ]

    result = explainer.explain_table('rel', columns)
    print("\nAI-Generated Documentation:")
    print(json.dumps(result, indent=2))
    print()

    print("IDEAL DOCUMENTATION:")
    print(json.dumps({
        "table_description": "Generic relationship mapping table using temporal effectiveness. Source (src_id) and target (tgt_id) can reference various entity types based on rel_type.",
        "purpose": "Flexible relationship storage supporting parent-child (PAR/CHD), hierarchies, and associations. Time-based validity (eff_dt to exp_dt) tracks relationship history.",
        "usage_notes": "Priority determines which relationship applies when multiple exist. Common rel_types: PAR=Parent, CHD=Child, ASC=Associate. Always filter by current effective date range."
    }, indent=2))
    print()

    # Test 4: Generic data table
    print("=" * 100)
    print("TEST 4: Generic/Worst-Case (data table)")
    print("=" * 100)

    columns = [
        {'name': 'id', 'type': 'INTEGER', 'nullable': False},
        {'name': 'key', 'type': 'VARCHAR(50)', 'nullable': True},
        {'name': 'value', 'type': 'TEXT', 'nullable': True},
        {'name': 'type', 'type': 'VARCHAR(20)', 'nullable': True},
        {'name': 'parent_id', 'type': 'INTEGER', 'nullable': True},
        {'name': 'seq', 'type': 'INTEGER', 'nullable': True},
        {'name': 'field1', 'type': 'VARCHAR(100)', 'nullable': True},
        {'name': 'field2', 'type': 'VARCHAR(100)', 'nullable': True},
        {'name': 'field3', 'type': 'VARCHAR(100)', 'nullable': True},
        {'name': 'num1', 'type': 'FLOAT', 'nullable': True},
        {'name': 'num2', 'type': 'FLOAT', 'nullable': True},
        {'name': 'date1', 'type': 'DATETIME', 'nullable': True},
        {'name': 'date2', 'type': 'DATETIME', 'nullable': True}
    ]

    result = explainer.explain_table('data', columns)
    print("\nAI-Generated Documentation:")
    print(json.dumps(result, indent=2))
    print()

    print("IDEAL DOCUMENTATION:")
    print(json.dumps({
        "table_description": "Generic key-value storage table with hierarchical support (parent_id) and extensibility fields. Often used for configuration, metadata, or EAV (Entity-Attribute-Value) patterns.",
        "purpose": "Provides schema-less data storage. 'Type' field categorizes data kind. Parent_id enables tree structures. Seq orders siblings. Flex fields (field1-3, num1-2, date1-2) extend basic key-value model.",
        "usage_notes": "WARNING: Generic schema makes querying complex. Document 'type' values and field usage externally. Consider performance implications of EAV pattern. Parent_id self-references this table's id."
    }, indent=2))
    print()

    print("=" * 100)
    print("ANALYSIS & RECOMMENDATIONS")
    print("=" * 100)
    print()
    print("Key Challenges Identified:")
    print("1. Abbreviated names lack context (ent_nm = entity name)")
    print("2. Flex fields have no semantic meaning (attr1, value1)")
    print("3. Single-character codes need lookup tables (status: A/I/D)")
    print("4. Generic names hide purpose (data, entity, rel)")
    print()
    print("Prompt Improvements Needed:")
    print("1. Add pattern recognition for common abbreviations")
    print("2. Detect flex field patterns and explain their purpose")
    print("3. Suggest common code meanings (A=Active, etc.)")
    print("4. Identify anti-patterns and warn about them")
    print("5. Use GraphRAG to maintain cross-table context")
    print()

if __name__ == '__main__':
    main()