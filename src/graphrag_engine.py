"""
GraphRAG Engine - Graph-based Retrieval Augmented Generation
Builds knowledge graph from database schema for enhanced AI documentation
"""

from typing import Dict, List, Optional, Any, Set, Tuple
from sqlalchemy import Engine, inspect, text
from dataclasses import dataclass, field
import logging
import json
from collections import defaultdict
import networkx as nx

logger = logging.getLogger(__name__)


@dataclass
class SchemaNode:
    """Node in the schema knowledge graph"""
    node_id: str
    node_type: str  # TABLE, COLUMN, CONSTRAINT, INDEX
    name: str
    properties: Dict[str, Any] = field(default_factory=dict)
    embeddings: Optional[List[float]] = None


@dataclass
class SchemaEdge:
    """Edge in the schema knowledge graph"""
    source: str
    target: str
    edge_type: str  # HAS_COLUMN, REFERENCES, INDEXES, CONSTRAINS
    properties: Dict[str, Any] = field(default_factory=dict)


class SchemaKnowledgeGraph:
    """
    Builds and maintains a knowledge graph of database schema.
    Provides graph-based context retrieval for LLM prompts.
    """

    def __init__(self, engine: Engine):
        """
        Initialize knowledge graph builder.

        Args:
            engine: SQLAlchemy engine
        """
        self.engine = engine
        self.graph = nx.MultiDiGraph()
        self.nodes: Dict[str, SchemaNode] = {}
        self.edges: List[SchemaEdge] = []
        self.table_categories: Dict[str, Set[str]] = defaultdict(set)

    def build_graph(self) -> None:
        """Build complete knowledge graph from database schema."""
        logger.info("Building schema knowledge graph...")

        inspector = inspect(self.engine)
        table_names = inspector.get_table_names()

        # Phase 1: Add table nodes
        for table_name in table_names:
            self._add_table_node(table_name, inspector)

        # Phase 2: Add column nodes and relationships
        for table_name in table_names:
            self._add_column_nodes(table_name, inspector)

        # Phase 3: Add foreign key relationships
        for table_name in table_names:
            self._add_foreign_key_edges(table_name, inspector)

        # Phase 4: Add index nodes
        for table_name in table_names:
            self._add_index_nodes(table_name, inspector)

        # Phase 5: Compute table categories and semantic clusters
        self._categorize_tables()

        logger.info(f"✓ Knowledge graph built: {len(self.nodes)} nodes, {len(self.edges)} edges")

    def _add_table_node(self, table_name: str, inspector) -> None:
        """Add table node to graph."""
        try:
            # Get table metadata
            row_count = self._get_row_count(table_name)
            columns = inspector.get_columns(table_name)
            pk_constraint = inspector.get_pk_constraint(table_name)

            node_id = f"table:{table_name}"
            node = SchemaNode(
                node_id=node_id,
                node_type="TABLE",
                name=table_name,
                properties={
                    "row_count": row_count,
                    "column_count": len(columns),
                    "primary_keys": pk_constraint.get('constrained_columns', [])
                }
            )

            self.nodes[node_id] = node
            self.graph.add_node(node_id, **node.properties)
            logger.debug(f"Added table node: {table_name}")

        except Exception as e:
            logger.warning(f"Error adding table node {table_name}: {e}")

    def _add_column_nodes(self, table_name: str, inspector) -> None:
        """Add column nodes and HAS_COLUMN edges."""
        try:
            columns = inspector.get_columns(table_name)
            table_node_id = f"table:{table_name}"

            for col in columns:
                col_name = col['name']
                col_type = str(col['type'])
                nullable = col.get('nullable', True)

                # Create column node
                node_id = f"column:{table_name}.{col_name}"
                node = SchemaNode(
                    node_id=node_id,
                    node_type="COLUMN",
                    name=col_name,
                    properties={
                        "table": table_name,
                        "data_type": col_type,
                        "nullable": nullable,
                        "default": col.get('default'),
                    }
                )

                self.nodes[node_id] = node
                self.graph.add_node(node_id, **node.properties)

                # Add HAS_COLUMN edge
                edge = SchemaEdge(
                    source=table_node_id,
                    target=node_id,
                    edge_type="HAS_COLUMN",
                    properties={"position": len(self.graph[table_node_id]) if table_node_id in self.graph else 0}
                )
                self.edges.append(edge)
                self.graph.add_edge(edge.source, edge.target, type=edge.edge_type, **edge.properties)

        except Exception as e:
            logger.warning(f"Error adding column nodes for {table_name}: {e}")

    def _add_foreign_key_edges(self, table_name: str, inspector) -> None:
        """Add REFERENCES edges for foreign keys."""
        try:
            foreign_keys = inspector.get_foreign_keys(table_name)
            table_node_id = f"table:{table_name}"

            for fk in foreign_keys:
                ref_table = fk.get('referred_table')
                constrained_cols = fk.get('constrained_columns', [])
                referred_cols = fk.get('referred_columns', [])

                if not ref_table:
                    continue

                # Add table-level reference edge
                ref_table_node_id = f"table:{ref_table}"
                edge = SchemaEdge(
                    source=table_node_id,
                    target=ref_table_node_id,
                    edge_type="REFERENCES",
                    properties={
                        "columns": constrained_cols,
                        "ref_columns": referred_cols,
                        "constraint_name": fk.get('name', 'unnamed')
                    }
                )
                self.edges.append(edge)
                self.graph.add_edge(edge.source, edge.target, type=edge.edge_type, **edge.properties)

                # Add column-level reference edges
                for src_col, ref_col in zip(constrained_cols, referred_cols):
                    src_col_id = f"column:{table_name}.{src_col}"
                    ref_col_id = f"column:{ref_table}.{ref_col}"

                    col_edge = SchemaEdge(
                        source=src_col_id,
                        target=ref_col_id,
                        edge_type="FK_REFERENCES",
                        properties={"fk_name": fk.get('name', 'unnamed')}
                    )
                    self.edges.append(col_edge)
                    self.graph.add_edge(col_edge.source, col_edge.target, type=col_edge.edge_type)

        except Exception as e:
            logger.warning(f"Error adding FK edges for {table_name}: {e}")

    def _add_index_nodes(self, table_name: str, inspector) -> None:
        """Add index nodes and INDEXES edges."""
        try:
            indexes = inspector.get_indexes(table_name)
            table_node_id = f"table:{table_name}"

            for idx in indexes:
                idx_name = idx.get('name', 'unnamed')
                idx_cols = idx.get('column_names', [])
                unique = idx.get('unique', False)

                # Create index node
                node_id = f"index:{table_name}.{idx_name}"
                node = SchemaNode(
                    node_id=node_id,
                    node_type="INDEX",
                    name=idx_name,
                    properties={
                        "table": table_name,
                        "columns": idx_cols,
                        "unique": unique
                    }
                )

                self.nodes[node_id] = node
                self.graph.add_node(node_id, **node.properties)

                # Add INDEXES edge from index to table
                edge = SchemaEdge(
                    source=node_id,
                    target=table_node_id,
                    edge_type="INDEXES",
                    properties={"columns": idx_cols}
                )
                self.edges.append(edge)
                self.graph.add_edge(edge.source, edge.target, type=edge.edge_type, **edge.properties)

        except Exception as e:
            logger.warning(f"Error adding index nodes for {table_name}: {e}")

    def _categorize_tables(self) -> None:
        """Categorize tables based on patterns and relationships."""
        for table_name in self.get_all_tables():
            categories = set()

            # Category 1: Lookup/Reference tables
            if self._is_lookup_table(table_name):
                categories.add("LOOKUP")

            # Category 2: Junction/Bridge tables (many-to-many)
            if self._is_junction_table(table_name):
                categories.add("JUNCTION")

            # Category 3: Transaction tables
            if self._is_transaction_table(table_name):
                categories.add("TRANSACTION")

            # Category 4: Master/Entity tables
            if self._is_master_table(table_name):
                categories.add("MASTER")

            # Category 5: Audit/Log tables
            if self._is_audit_table(table_name):
                categories.add("AUDIT")

            self.table_categories[table_name] = categories

    def _is_lookup_table(self, table_name: str) -> bool:
        """Check if table is a lookup table."""
        table_lower = table_name.lower()
        lookup_patterns = ['lookup', 'lkp', 'ref', 'type', 'status', 'category', 'code', 'dwl_', 'lkp_']
        return any(pattern in table_lower for pattern in lookup_patterns)

    def _is_junction_table(self, table_name: str) -> bool:
        """Check if table is a junction table (many-to-many)."""
        table_node_id = f"table:{table_name}"
        if table_node_id not in self.graph:
            return False

        # Junction tables typically have 2+ foreign keys and few other columns
        fk_count = len([e for e in self.graph.out_edges(table_node_id, data=True)
                       if e[2].get('type') == 'REFERENCES'])
        total_cols = len([n for n in self.graph.neighbors(table_node_id)
                         if n.startswith('column:')])

        return fk_count >= 2 and total_cols <= fk_count + 3

    def _is_transaction_table(self, table_name: str) -> bool:
        """Check if table stores transactional data."""
        trans_patterns = ['transaction', 'order', 'payment', 'invoice', 'charge', 'usage', 'activity']
        return any(pattern in table_name.lower() for pattern in trans_patterns)

    def _is_master_table(self, table_name: str) -> bool:
        """Check if table is a master/entity table."""
        master_patterns = ['customer', 'product', 'account', 'user', 'employee', 'patient', 'subscription']
        return any(pattern in table_name.lower() for pattern in master_patterns)

    def _is_audit_table(self, table_name: str) -> bool:
        """Check if table is for auditing."""
        audit_patterns = ['audit', 'log', 'history', 'trail']
        return any(pattern in table_name.lower() for pattern in audit_patterns)

    def _get_row_count(self, table_name: str) -> int:
        """Get approximate row count for table."""
        try:
            query = text(f"SELECT COUNT(*) FROM {table_name}")
            with self.engine.connect() as conn:
                result = conn.execute(query)
                return result.scalar() or 0
        except Exception:
            return 0

    def get_all_tables(self) -> List[str]:
        """Get list of all tables in graph."""
        return [node.name for node in self.nodes.values() if node.node_type == "TABLE"]

    def get_table_context(self, table_name: str, depth: int = 2) -> Dict[str, Any]:
        """
        Get rich context for a table using graph traversal.

        Args:
            table_name: Table to get context for
            depth: Depth of graph traversal (1=immediate, 2=second-degree)

        Returns:
            Dict with comprehensive table context
        """
        table_node_id = f"table:{table_name}"

        if table_node_id not in self.graph:
            return {}

        context = {
            "table_name": table_name,
            "categories": list(self.table_categories.get(table_name, set())),
            "columns": [],
            "primary_keys": [],
            "foreign_keys": [],
            "referenced_by": [],
            "related_tables": [],
            "indexes": [],
            "semantic_cluster": []
        }

        # Get columns
        for neighbor in self.graph.neighbors(table_node_id):
            if neighbor.startswith("column:"):
                col_node = self.nodes.get(neighbor)
                if col_node:
                    context["columns"].append({
                        "name": col_node.name,
                        "type": col_node.properties.get("data_type"),
                        "nullable": col_node.properties.get("nullable")
                    })

        # Get primary keys
        table_node = self.nodes.get(table_node_id)
        if table_node:
            context["primary_keys"] = table_node.properties.get("primary_keys", [])

        # Get foreign key relationships
        for _, target, data in self.graph.out_edges(table_node_id, data=True):
            if data.get('type') == 'REFERENCES':
                ref_table = target.replace("table:", "")
                context["foreign_keys"].append({
                    "referenced_table": ref_table,
                    "columns": data.get('columns', []),
                    "ref_columns": data.get('ref_columns', [])
                })
                context["related_tables"].append(ref_table)

        # Get reverse references (tables that reference this table)
        for source, _, data in self.graph.in_edges(table_node_id, data=True):
            if data.get('type') == 'REFERENCES':
                ref_by_table = source.replace("table:", "")
                context["referenced_by"].append({
                    "table": ref_by_table,
                    "columns": data.get('ref_columns', [])
                })
                if ref_by_table not in context["related_tables"]:
                    context["related_tables"].append(ref_by_table)

        # Get indexes
        for source, _, data in self.graph.in_edges(table_node_id, data=True):
            if data.get('type') == 'INDEXES':
                index_node = self.nodes.get(source)
                if index_node:
                    context["indexes"].append({
                        "name": index_node.name,
                        "columns": index_node.properties.get("columns", []),
                        "unique": index_node.properties.get("unique", False)
                    })

        # Get semantic cluster (tables within depth hops)
        if depth > 1:
            cluster = self._get_semantic_cluster(table_name, depth)
            context["semantic_cluster"] = cluster

        return context

    def _get_semantic_cluster(self, table_name: str, depth: int) -> List[str]:
        """Get tables within N hops in the graph."""
        table_node_id = f"table:{table_name}"
        if table_node_id not in self.graph:
            return []

        cluster = set()
        visited = {table_node_id}
        current_level = {table_node_id}

        for _ in range(depth):
            next_level = set()
            for node in current_level:
                for neighbor in self.graph.neighbors(node):
                    if neighbor.startswith("table:") and neighbor not in visited:
                        cluster.add(neighbor.replace("table:", ""))
                        next_level.add(neighbor)
                        visited.add(neighbor)

                for predecessor in self.graph.predecessors(node):
                    if predecessor.startswith("table:") and predecessor not in visited:
                        cluster.add(predecessor.replace("table:", ""))
                        next_level.add(predecessor)
                        visited.add(predecessor)

            current_level = next_level

        return list(cluster)

    def get_relationship_path(self, table1: str, table2: str) -> Optional[List[str]]:
        """
        Find shortest path between two tables in the graph.

        Args:
            table1: Source table
            table2: Target table

        Returns:
            List of table names in path, or None if no path exists
        """
        node1 = f"table:{table1}"
        node2 = f"table:{table2}"

        if node1 not in self.graph or node2 not in self.graph:
            return None

        try:
            # Convert to undirected for path finding
            undirected = self.graph.to_undirected()
            path = nx.shortest_path(undirected, node1, node2)

            # Extract only table nodes from path
            table_path = [node.replace("table:", "") for node in path if node.startswith("table:")]
            return table_path

        except nx.NetworkXNoPath:
            return None

    def export_graph(self, format: str = "json") -> str:
        """
        Export knowledge graph in specified format.

        Args:
            format: Export format ('json', 'graphml', 'gexf')

        Returns:
            Serialized graph data
        """
        if format == "json":
            data = {
                "nodes": [
                    {
                        "id": node_id,
                        "type": node.node_type,
                        "name": node.name,
                        "properties": node.properties
                    }
                    for node_id, node in self.nodes.items()
                ],
                "edges": [
                    {
                        "source": edge.source,
                        "target": edge.target,
                        "type": edge.edge_type,
                        "properties": edge.properties
                    }
                    for edge in self.edges
                ]
            }
            return json.dumps(data, indent=2)

        elif format == "graphml":
            import io
            buffer = io.BytesIO()
            nx.write_graphml(self.graph, buffer)
            return buffer.getvalue().decode('utf-8')

        else:
            raise ValueError(f"Unsupported export format: {format}")


class GraphRAGEngine:
    """
    Graph-based Retrieval Augmented Generation Engine.
    Enhances LLM prompts with graph-derived context.
    """

    def __init__(self, engine: Engine, ollama_client=None, model: str = "llama3.2"):
        """
        Initialize GraphRAG engine.

        Args:
            engine: SQLAlchemy engine
            ollama_client: Ollama client instance
            model: LLM model name
        """
        self.engine = engine
        self.ollama_client = ollama_client
        self.model = model
        self.kg = SchemaKnowledgeGraph(engine)

    def build_knowledge_graph(self) -> None:
        """Build the schema knowledge graph."""
        self.kg.build_graph()

    def generate_enriched_documentation(
        self,
        table_name: str,
        include_relationships: bool = True,
        include_semantic_cluster: bool = True
    ) -> Dict[str, Any]:
        """
        Generate documentation with graph-enriched context.

        Args:
            table_name: Table to document
            include_relationships: Include related tables in prompt
            include_semantic_cluster: Include semantic cluster analysis

        Returns:
            Dict with AI-generated documentation
        """
        if not self.ollama_client:
            return {"error": "Ollama client not available"}

        # Get graph context
        context = self.kg.get_table_context(table_name, depth=2)

        # Build enriched prompt
        prompt = self._build_graph_enriched_prompt(
            table_name,
            context,
            include_relationships=include_relationships,
            include_semantic_cluster=include_semantic_cluster
        )

        # Generate documentation
        try:
            response = self.ollama_client.chat(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": "You are a database documentation expert. Use the provided graph context to generate comprehensive, accurate documentation."
                    },
                    {"role": "user", "content": prompt}
                ],
                options={"temperature": 0.3, "num_ctx": 8192}
            )

            content = response['message']['content']

            # Parse JSON response
            try:
                if '```json' in content:
                    content = content.split('```json')[1].split('```')[0].strip()
                elif '```' in content:
                    content = content.split('```')[1].split('```')[0].strip()

                result = json.loads(content)
                result['graph_context'] = context
                return result

            except json.JSONDecodeError:
                return {
                    "description": content,
                    "graph_context": context
                }

        except Exception as e:
            logger.error(f"Error generating enriched documentation: {e}")
            return {"error": str(e), "graph_context": context}

    def _build_graph_enriched_prompt(
        self,
        table_name: str,
        context: Dict[str, Any],
        include_relationships: bool,
        include_semantic_cluster: bool
    ) -> str:
        """Build prompt with graph-derived context."""

        # Build column list
        columns_text = "\n".join([
            f"  - {col['name']} ({col['type']}){'  [NULL]' if col.get('nullable') else ''}"
            for col in context.get("columns", [])
        ])

        # Build relationships section
        relationships_text = ""
        if include_relationships:
            fks = context.get("foreign_keys", [])
            refs = context.get("referenced_by", [])

            if fks or refs:
                relationships_text = "\n\nRelationships:"

            if fks:
                relationships_text += "\n\nForeign Keys (this table references):"
                for fk in fks:
                    relationships_text += f"\n  - {', '.join(fk['columns'])} -> {fk['referenced_table']}({', '.join(fk['ref_columns'])})"

            if refs:
                relationships_text += "\n\nReferenced By (other tables reference this):"
                for ref in refs:
                    relationships_text += f"\n  - {ref['table']} references {', '.join(ref['columns'])}"

        # Build semantic cluster section
        cluster_text = ""
        if include_semantic_cluster and context.get("semantic_cluster"):
            cluster_text = f"\n\nRelated Tables in Domain:\n  - " + "\n  - ".join(context["semantic_cluster"])

        # Build categories section
        categories_text = ""
        if context.get("categories"):
            categories_text = f"\n\nTable Categories: {', '.join(context['categories'])}"

        prompt = f"""Analyze this database table using the graph-based context provided.

Table: {table_name}{categories_text}
Primary Keys: {', '.join(context.get('primary_keys', []))}

Columns:
{columns_text}{relationships_text}{cluster_text}

Using the graph context showing relationships and semantic clusters, provide comprehensive documentation in JSON format:
{{
  "table_description": "Detailed description based on structure and relationships",
  "purpose": "Business purpose considering role in data model",
  "usage_notes": "Important notes about data patterns, relationships, and constraints",
  "relationships_summary": "How this table fits in the overall schema graph"
}}"""

        return prompt


# Example usage
if __name__ == "__main__":
    from sqlalchemy import create_engine
    import ollama

    # Connect to database
    engine = create_engine("postgresql://user:pass@localhost/dbname")

    # Initialize GraphRAG
    ollama_client = ollama.Client(host="http://localhost:11434")
    graphrag = GraphRAGEngine(engine, ollama_client)

    # Build knowledge graph
    graphrag.build_knowledge_graph()

    # Generate enriched documentation
    docs = graphrag.generate_enriched_documentation("customers")
    print(json.dumps(docs, indent=2))
