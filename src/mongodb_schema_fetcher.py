"""
MongoDB Schema Fetcher
Handles schema inspection for MongoDB databases by sampling documents
"""

from typing import List, Dict, Any, Optional
import logging
from collections import Counter

logger = logging.getLogger(__name__)


class MongoDBSchemaFetcher:
    """
    Fetches and analyzes schema information from MongoDB databases.
    MongoDB is schema-less, so schema is inferred from document sampling.
    """

    def __init__(self, mongo_db: Any):
        """
        Initialize MongoDB schema fetcher.

        Args:
            mongo_db: MongoDB database connection
        """
        self.db = mongo_db

    def get_all_collections(self) -> List[str]:
        """
        Get list of all collections in the database.

        Returns:
            List[str]: Collection names
        """
        return self.db.list_collection_names()

    def get_collection_info(self, collection_name: str, sample_size: int = 100) -> Dict[str, Any]:
        """
        Analyze collection structure by sampling documents.

        Args:
            collection_name: Name of the collection
            sample_size: Number of documents to sample (default: 100)

        Returns:
            dict: Collection metadata and inferred schema
        """
        collection = self.db[collection_name]

        # Get collection stats
        stats = self.db.command('collStats', collection_name)

        # Sample documents to infer schema
        sample_docs = list(collection.find().limit(sample_size))

        # Analyze field types and structure
        field_info = self._analyze_fields(sample_docs)

        # Get indexes
        indexes = list(collection.list_indexes())

        return {
            'name': collection_name,
            'document_count': stats.get('count', 0),
            'size_bytes': stats.get('size', 0),
            'avg_doc_size': stats.get('avgObjSize', 0),
            'storage_size': stats.get('storageSize', 0),
            'fields': field_info,
            'indexes': self._format_indexes(indexes),
            'sample_size': len(sample_docs),
            'is_capped': stats.get('capped', False),
            'max_doc_count': stats.get('max') if stats.get('capped') else None
        }

    def _analyze_fields(self, documents: List[Dict]) -> Dict[str, Any]:
        """
        Analyze fields across sampled documents.

        Args:
            documents: List of sampled documents

        Returns:
            dict: Field analysis with types, frequency, etc.
        """
        if not documents:
            return {}

        field_analysis = {}

        for doc in documents:
            self._analyze_document_fields(doc, field_analysis, prefix='')

        # Calculate statistics
        total_docs = len(documents)
        for field_name, field_data in field_analysis.items():
            field_data['presence_percentage'] = (field_data['count'] / total_docs) * 100
            field_data['is_required'] = field_data['count'] == total_docs

            # Determine most common type
            if field_data['types']:
                most_common = field_data['types'].most_common(1)[0]
                field_data['primary_type'] = most_common[0]
                field_data['type_variations'] = len(field_data['types'])

        return field_analysis

    def _analyze_document_fields(self, doc: Dict, field_analysis: Dict, prefix: str = ''):
        """
        Recursively analyze fields in a document.

        Args:
            doc: Document to analyze
            field_analysis: Dictionary to accumulate field analysis
            prefix: Field prefix for nested documents
        """
        for key, value in doc.items():
            if key == '_id':
                continue  # Skip _id field

            field_name = f"{prefix}{key}" if prefix else key

            if field_name not in field_analysis:
                field_analysis[field_name] = {
                    'count': 0,
                    'types': Counter(),
                    'null_count': 0,
                    'sample_values': []
                }

            field_analysis[field_name]['count'] += 1

            if value is None:
                field_analysis[field_name]['null_count'] += 1
            else:
                value_type = type(value).__name__

                # Handle nested documents
                if isinstance(value, dict):
                    field_analysis[field_name]['types']['object'] += 1
                    # Recursively analyze nested document
                    self._analyze_document_fields(value, field_analysis, prefix=f"{field_name}.")
                elif isinstance(value, list):
                    field_analysis[field_name]['types']['array'] += 1
                    # Analyze array element types
                    if value and len(value) > 0:
                        elem_type = type(value[0]).__name__
                        field_analysis[field_name]['types'][f'array<{elem_type}>'] += 1
                else:
                    field_analysis[field_name]['types'][value_type] += 1

                # Store sample values (limit to first 5 unique values)
                if len(field_analysis[field_name]['sample_values']) < 5:
                    str_value = str(value)[:100]  # Truncate long values
                    if str_value not in field_analysis[field_name]['sample_values']:
                        field_analysis[field_name]['sample_values'].append(str_value)

    def _format_indexes(self, indexes: List[Dict]) -> List[Dict[str, Any]]:
        """
        Format index information for display.

        Args:
            indexes: Raw index information from MongoDB

        Returns:
            List[dict]: Formatted index information
        """
        formatted = []
        for idx in indexes:
            formatted.append({
                'name': idx.get('name'),
                'keys': list(idx.get('key', {}).keys()),
                'unique': idx.get('unique', False),
                'sparse': idx.get('sparse', False),
                'background': idx.get('background', False)
            })
        return formatted

    def get_database_stats(self) -> Dict[str, Any]:
        """
        Get overall database statistics.

        Returns:
            dict: Database-level statistics
        """
        stats = self.db.command('dbStats')

        return {
            'database_name': stats.get('db'),
            'collections': stats.get('collections', 0),
            'views': stats.get('views', 0),
            'objects': stats.get('objects', 0),
            'data_size': stats.get('dataSize', 0),
            'storage_size': stats.get('storageSize', 0),
            'indexes': stats.get('indexes', 0),
            'index_size': stats.get('indexSize', 0),
            'avg_obj_size': stats.get('avgObjSize', 0)
        }

    def sample_documents(self, collection_name: str, limit: int = 10) -> List[Dict]:
        """
        Get sample documents from a collection.

        Args:
            collection_name: Name of the collection
            limit: Number of documents to return

        Returns:
            List[dict]: Sample documents
        """
        collection = self.db[collection_name]
        return list(collection.find().limit(limit))