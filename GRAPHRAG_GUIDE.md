# GraphRAG Implementation Guide

## Overview

**GraphRAG** (Graph-based Retrieval Augmented Generation) enhances AI documentation by building a knowledge graph from your database schema and using graph-based context retrieval to provide richer, more accurate documentation.

## Key Benefits

### 1. **Relationship-Aware Documentation**
Traditional approach: Analyzes each table in isolation
GraphRAG approach: Understands how tables relate and their role in the data model

**Example:**
```
Traditional: "patients table stores patient information"
GraphRAG: "patients table is the central entity referenced by encounters,
           diagnoses, and medication_orders, serving as the master record
           for all clinical activities"
```

### 2. **Semantic Clustering**
Automatically groups related tables into business domains:
- **MASTER tables**: customers, patients, products
- **TRANSACTION tables**: orders, payments, encounters
- **LOOKUP tables**: status codes, categories, types
- **JUNCTION tables**: many-to-many relationships
- **AUDIT tables**: logs, history, trails

### 3. **Graph Traversal for Context**
Finds related tables within N-hops to understand the broader context:
```python
context = kg.get_table_context("patients", depth=2)
# Returns: encounters, diagnoses, medications, procedures, allergies, etc.
```

### 4. **Relationship Path Finding**
Discovers how to navigate between tables:
```python
path = kg.get_relationship_path("customers", "invoices")
# Returns: ['customers', 'accounts', 'invoices']
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GraphRAG Engine                          │
└────────────┬────────────────────────────────────────────────┘
             │
             ├──> Schema Knowledge Graph
             │    ├── Table Nodes (with row counts)
             │    ├── Column Nodes (with types)
             │    ├── Index Nodes
             │    └── Relationships (FK, References)
             │
             ├──> Graph Algorithms
             │    ├── Shortest Path Finding
             │    ├── Semantic Clustering
             │    ├── Community Detection
             │    └── Centrality Analysis
             │
             └──> Context Enrichment
                  ├── Relationship Context
                  ├── Semantic Cluster
                  ├── Category Tags
                  └── Domain Knowledge
                       │
                       ▼
                  Enhanced LLM Prompts
                       │
                       ▼
                  Better Documentation
```

## Installation

```bash
# Install required packages
pip install networkx sqlalchemy ollama

# Make sure Ollama is running with llama3.2
ollama pull llama3.2
ollama serve
```

## Quick Start

### 1. Build Knowledge Graph

```python
from sqlalchemy import create_engine
from graphrag_engine import SchemaKnowledgeGraph

# Connect to your database
engine = create_engine("postgresql://user:pass@localhost/mydb")

# Build knowledge graph
kg = SchemaKnowledgeGraph(engine)
kg.build_graph()

print(f"Nodes: {len(kg.nodes)}")
print(f"Edges: {len(kg.edges)}")
print(f"Tables: {len(kg.get_all_tables())}")
```

### 2. Explore Graph Context

```python
# Get rich context for a table
context = kg.get_table_context("customers", depth=2)

print(f"Categories: {context['categories']}")
print(f"Foreign Keys: {context['foreign_keys']}")
print(f"Referenced By: {context['referenced_by']}")
print(f"Related Tables: {context['related_tables']}")
print(f"Semantic Cluster: {context['semantic_cluster']}")
```

### 3. Generate Enhanced Documentation

```python
import ollama
from graphrag_engine import GraphRAGEngine

# Initialize
ollama_client = ollama.Client(host="http://localhost:11434")
graphrag = GraphRAGEngine(engine, ollama_client, model="llama3.2")

# Build graph
graphrag.build_knowledge_graph()

# Generate documentation
docs = graphrag.generate_enriched_documentation(
    "customers",
    include_relationships=True,
    include_semantic_cluster=True
)

print(docs['table_description'])
print(docs['purpose'])
print(docs['relationships_summary'])
```

### 4. Export Knowledge Graph

```python
# Export for visualization
graph_json = kg.export_graph(format="json")

with open("schema_graph.json", "w") as f:
    f.write(graph_json)

# Can be imported into tools like:
# - Gephi
# - Cytoscape
# - Neo4j Browser
# - D3.js visualizations
```

## Integration with Existing Code

### Enhance SchemaExplainer

```python
from schema_explainer import SchemaExplainer
from graphrag_engine import SchemaKnowledgeGraph

class EnhancedSchemaExplainer(SchemaExplainer):
    def __init__(self, engine, **kwargs):
        super().__init__(engine, **kwargs)
        self.kg = SchemaKnowledgeGraph(engine)
        self.kg.build_graph()

    def explain_table_with_context(self, table_name, columns):
        # Get graph context
        context = self.kg.get_table_context(table_name, depth=2)

        # Original explanation
        basic_explanation = super().explain_table(table_name, columns)

        # Enhance with graph insights
        enhanced = {
            **basic_explanation,
            'categories': context['categories'],
            'related_tables': context['related_tables'],
            'semantic_cluster': context['semantic_cluster']
        }

        return enhanced
```

### Enhance NL Query Generator

```python
from nl_query_generator import NaturalLanguageQueryGenerator
from graphrag_engine import SchemaKnowledgeGraph

class GraphAwareQueryGenerator(NaturalLanguageQueryGenerator):
    def __init__(self, engine, **kwargs):
        super().__init__(engine, **kwargs)
        self.kg = SchemaKnowledgeGraph(engine)
        self.kg.build_graph()

    def generate_sql(self, question):
        # Parse entities from question
        entities = self.extract_entities(question)

        # Find relationship path
        if len(entities) >= 2:
            path = self.kg.get_relationship_path(entities[0], entities[1])
            if path:
                # Include join path in prompt
                prompt = f"Question: {question}\nJoin Path: {' -> '.join(path)}"
                return super().generate_sql(prompt)

        return super().generate_sql(question)
```

## Testing

Run the comprehensive test suite:

```bash
# Test on healthcare schema
python test_graphrag.py --schema healthcare

# Test on telecom schema
python test_graphrag.py --schema telecom

# Compare with/without GraphRAG
python test_graphrag.py --schema compare

# Test both schemas
python test_graphrag.py --schema both
```

## Real-World Examples

### Example 1: Understanding Complex Relationships

**Without GraphRAG:**
```json
{
  "table_description": "Table for storing medical prescriptions",
  "purpose": "Tracks medication orders"
}
```

**With GraphRAG:**
```json
{
  "table_description": "Central medication ordering table that links patients, encounters, prescribers, and medication definitions. Acts as source of truth for medication administration tracking.",
  "purpose": "Manages the complete medication lifecycle from order to administration, supporting clinical decision support and regulatory compliance",
  "relationships_summary": "References patients (1:N), encounters (1:N), medication_definitions (N:1), and personnel (N:1). Referenced by medication_administrations (1:N) for tracking actual doses given.",
  "domain_position": "Core TRANSACTION table in clinical operations domain, bridge between ordering and administration workflows"
}
```

### Example 2: Auto-Detecting Data Patterns

GraphRAG automatically categorizes:

```python
# Lookup tables
"dwr_geography" → LOOKUP
"health_plans" → LOOKUP

# Transaction tables
"dwb_usage_detail_record" → TRANSACTION
"charges" → TRANSACTION

# Master entities
"dwb_customer" → MASTER
"patients" → MASTER

# Junction tables
"patient_insurance" → JUNCTION
"order_items" → JUNCTION
```

### Example 3: Finding Hidden Relationships

```python
# Find all tables related to billing
context = kg.get_table_context("charges", depth=3)
print(context['semantic_cluster'])
# Output: ['charges', 'invoices', 'payments', 'accounts',
#          'customers', 'insurance', 'encounters', 'procedures']

# Understand the billing workflow path
path = kg.get_relationship_path("encounters", "invoices")
print(' → '.join(path))
# Output: encounters → charges → invoices
```

## Advanced Features

### 1. Custom Table Categorization

```python
def custom_categorizer(table_name: str, context: dict) -> set:
    categories = set()

    # Custom business logic
    if "financial" in table_name.lower():
        categories.add("FINANCIAL")

    if context.get('row_count', 0) > 1000000:
        categories.add("HIGH_VOLUME")

    return categories

kg.table_categories["my_table"] = custom_categorizer("my_table", context)
```

### 2. Graph Analytics

```python
import networkx as nx

# Find most central tables (most important)
centrality = nx.degree_centrality(kg.graph)
most_important = sorted(centrality.items(), key=lambda x: x[1], reverse=True)[:5]

print("Most Central Tables:")
for table, score in most_important:
    print(f"  {table}: {score:.3f}")

# Detect communities (business domains)
communities = nx.community.louvain_communities(kg.graph.to_undirected())
for i, community in enumerate(communities):
    tables = [n for n in community if n.startswith("table:")]
    print(f"Domain {i+1}: {[t.replace('table:', '') for t in tables]}")
```

### 3. Export for Visualization

```python
# Export to Gephi
nx.write_gexf(kg.graph, "schema.gexf")

# Export to Neo4j Cypher
def generate_cypher():
    statements = []
    for node_id, node in kg.nodes.items():
        props = json.dumps(node.properties)
        statements.append(
            f"CREATE (:{node.node_type} {{id: '{node_id}', "
            f"name: '{node.name}', properties: '{props}'}})"
        )
    return "\n".join(statements)

with open("schema.cypher", "w") as f:
    f.write(generate_cypher())
```

## Performance Considerations

### Memory Usage
- Small DB (< 50 tables): ~10 MB
- Medium DB (50-200 tables): ~50 MB
- Large DB (> 200 tables): ~200 MB

### Build Time
- Knowledge graph building: ~2-10 seconds per 100 tables
- Context retrieval: < 100ms per query
- Documentation generation: 5-15 seconds per table (LLM-dependent)

### Optimization Tips

```python
# 1. Build graph once, reuse many times
kg = SchemaKnowledgeGraph(engine)
kg.build_graph()  # Build once

# Use many times
for table in tables:
    context = kg.get_table_context(table)  # Fast

# 2. Limit depth for faster retrieval
context = kg.get_table_context(table, depth=1)  # Immediate neighbors only

# 3. Cache graph to disk
import pickle
with open("kg_cache.pkl", "wb") as f:
    pickle.dump(kg, f)

# Load from cache
with open("kg_cache.pkl", "rb") as f:
    kg = pickle.load(f)
```

## Troubleshooting

### Issue: "No path found between tables"
**Solution:** Tables may be in disconnected components. Check foreign keys exist.

```python
# Find disconnected components
components = list(nx.weakly_connected_components(kg.graph))
print(f"Found {len(components)} disconnected components")
```

### Issue: "Graph building takes too long"
**Solution:** Skip row count calculation for large tables

```python
class FastKnowledgeGraph(SchemaKnowledgeGraph):
    def _get_row_count(self, table_name):
        # Skip expensive COUNT(*) for large tables
        return 0
```

### Issue: "Out of memory on large databases"
**Solution:** Build graph incrementally or filter tables

```python
# Only build graph for specific schema
inspector = inspect(engine)
tables = [t for t in inspector.get_table_names()
          if not t.startswith('audit_')]
# Build for subset only
```

## Future Enhancements

1. **Vector Embeddings**: Add semantic embeddings to nodes for similarity search
2. **Temporal Graphs**: Track schema evolution over time
3. **Query Pattern Mining**: Learn common join patterns from query logs
4. **Auto Schema Suggestions**: Recommend missing indexes/foreign keys
5. **Cross-Database Graphs**: Build unified graph across multiple databases

## References

- NetworkX Documentation: https://networkx.org/
- Graph RAG Paper: https://arxiv.org/abs/2404.16130
- Knowledge Graphs: https://en.wikipedia.org/wiki/Knowledge_graph

## Support

For issues or questions:
1. Check the test file: `test_graphrag.py`
2. Review examples in this guide
3. File an issue with schema details and error logs
