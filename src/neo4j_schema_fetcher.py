"""
Neo4j Schema Fetcher
Handles schema inspection for Neo4j graph databases
"""

from typing import List, Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)


class Neo4jSchemaFetcher:
    """
    Fetches and analyzes schema information from Neo4j graph databases.
    Focuses on node labels, relationship types, and properties.
    """

    def __init__(self, neo4j_driver: Any):
        """
        Initialize Neo4j schema fetcher.

        Args:
            neo4j_driver: Neo4j driver connection
        """
        self.driver = neo4j_driver

    def get_all_labels(self) -> List[str]:
        """
        Get all node labels in the database.

        Returns:
            List[str]: Node label names
        """
        with self.driver.session() as session:
            result = session.run("CALL db.labels()")
            return [record['label'] for record in result]

    def get_all_relationship_types(self) -> List[str]:
        """
        Get all relationship types in the database.

        Returns:
            List[str]: Relationship type names
        """
        with self.driver.session() as session:
            result = session.run("CALL db.relationshipTypes()")
            return [record['relationshipType'] for record in result]

    def get_label_info(self, label: str) -> Dict[str, Any]:
        """
        Get detailed information about a specific node label.

        Args:
            label: Node label name

        Returns:
            dict: Label metadata and properties
        """
        with self.driver.session() as session:
            # Get node count
            count_query = f"MATCH (n:{label}) RETURN count(n) as count"
            count_result = session.run(count_query)
            node_count = count_result.single()['count']

            # Sample nodes to determine properties
            sample_query = f"MATCH (n:{label}) RETURN n LIMIT 100"
            sample_result = session.run(sample_query)

            # Analyze properties
            property_info = self._analyze_properties([record['n'] for record in sample_result])

            # Get relationships
            rel_query = f"""
            MATCH (n:{label})-[r]-(m)
            RETURN type(r) as rel_type, labels(m) as target_labels,
                   count(*) as count
            ORDER BY count DESC
            LIMIT 20
            """
            rel_result = session.run(rel_query)
            relationships = [dict(record) for record in rel_result]

            return {
                'label': label,
                'node_count': node_count,
                'properties': property_info,
                'relationships': relationships,
                'sample_size': min(100, node_count)
            }

    def get_relationship_info(self, rel_type: str) -> Dict[str, Any]:
        """
        Get detailed information about a specific relationship type.

        Args:
            rel_type: Relationship type name

        Returns:
            dict: Relationship metadata
        """
        with self.driver.session() as session:
            # Get relationship count
            count_query = f"MATCH ()-[r:{rel_type}]->() RETURN count(r) as count"
            count_result = session.run(count_query)
            rel_count = count_result.single()['count']

            # Get source and target labels
            pattern_query = f"""
            MATCH (source)-[r:{rel_type}]->(target)
            RETURN DISTINCT labels(source) as source_labels,
                   labels(target) as target_labels,
                   count(*) as count
            ORDER BY count DESC
            LIMIT 10
            """
            pattern_result = session.run(pattern_query)
            patterns = [dict(record) for record in pattern_result]

            # Sample relationships to analyze properties
            sample_query = f"MATCH ()-[r:{rel_type}]->() RETURN r LIMIT 100"
            sample_result = session.run(sample_query)
            property_info = self._analyze_properties([record['r'] for record in sample_result])

            return {
                'type': rel_type,
                'count': rel_count,
                'properties': property_info,
                'patterns': patterns,
                'sample_size': min(100, rel_count)
            }

    def _analyze_properties(self, entities: List[Any]) -> Dict[str, Any]:
        """
        Analyze properties across sampled nodes or relationships.

        Args:
            entities: List of Neo4j nodes or relationships

        Returns:
            dict: Property analysis
        """
        if not entities:
            return {}

        property_analysis = {}
        total_count = len(entities)

        for entity in entities:
            props = dict(entity)

            for prop_name, prop_value in props.items():
                if prop_name not in property_analysis:
                    property_analysis[prop_name] = {
                        'count': 0,
                        'type': None,
                        'null_count': 0,
                        'sample_values': []
                    }

                property_analysis[prop_name]['count'] += 1

                if prop_value is None:
                    property_analysis[prop_name]['null_count'] += 1
                else:
                    # Determine type
                    if property_analysis[prop_name]['type'] is None:
                        property_analysis[prop_name]['type'] = type(prop_value).__name__

                    # Store sample values
                    if len(property_analysis[prop_name]['sample_values']) < 5:
                        str_value = str(prop_value)[:100]
                        if str_value not in property_analysis[prop_name]['sample_values']:
                            property_analysis[prop_name]['sample_values'].append(str_value)

        # Calculate statistics
        for prop_name, prop_data in property_analysis.items():
            prop_data['presence_percentage'] = (prop_data['count'] / total_count) * 100
            prop_data['is_required'] = prop_data['count'] == total_count

        return property_analysis

    def get_database_stats(self) -> Dict[str, Any]:
        """
        Get overall database statistics.

        Returns:
            dict: Database-level statistics
        """
        with self.driver.session() as session:
            # Get node count
            node_result = session.run("MATCH (n) RETURN count(n) as count")
            node_count = node_result.single()['count']

            # Get relationship count
            rel_result = session.run("MATCH ()-[r]->() RETURN count(r) as count")
            rel_count = rel_result.single()['count']

            # Get label count
            label_result = session.run("CALL db.labels() YIELD label RETURN count(label) as count")
            label_count = label_result.single()['count']

            # Get relationship type count
            rel_type_result = session.run(
                "CALL db.relationshipTypes() YIELD relationshipType RETURN count(relationshipType) as count"
            )
            rel_type_count = rel_type_result.single()['count']

            # Get property key count
            prop_result = session.run("CALL db.propertyKeys() YIELD propertyKey RETURN count(propertyKey) as count")
            prop_count = prop_result.single()['count']

            return {
                'total_nodes': node_count,
                'total_relationships': rel_count,
                'label_count': label_count,
                'relationship_type_count': rel_type_count,
                'property_key_count': prop_count
            }

    def get_schema_visualization(self) -> Dict[str, Any]:
        """
        Get schema information suitable for visualization.

        Returns:
            dict: Schema structure with nodes and relationships
        """
        with self.driver.session() as session:
            # Get schema summary using Neo4j's built-in procedure
            try:
                result = session.run("CALL db.schema.visualization()")
                record = result.single()

                nodes = []
                relationships = []

                # Extract node information
                for node in record['nodes']:
                    nodes.append({
                        'label': list(node.labels)[0] if node.labels else 'Unknown',
                        'properties': list(dict(node).keys())
                    })

                # Extract relationship information
                for rel in record['relationships']:
                    relationships.append({
                        'type': rel.type,
                        'properties': list(dict(rel).keys())
                    })

                return {
                    'nodes': nodes,
                    'relationships': relationships
                }

            except Exception as e:
                logger.warning(f"Could not get schema visualization: {str(e)}")
                # Fallback to manual schema construction
                labels = self.get_all_labels()
                rel_types = self.get_all_relationship_types()

                return {
                    'nodes': [{'label': label, 'properties': []} for label in labels],
                    'relationships': [{'type': rt, 'properties': []} for rt in rel_types]
                }

    def run_cypher_query(self, query: str, parameters: Optional[Dict] = None) -> List[Dict]:
        """
        Execute a custom Cypher query.

        Args:
            query: Cypher query string
            parameters: Query parameters (optional)

        Returns:
            List[dict]: Query results
        """
        with self.driver.session() as session:
            result = session.run(query, parameters or {})
            return [dict(record) for record in result]