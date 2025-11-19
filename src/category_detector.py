"""
Category Data Detector - Identifies lookup/category tables and extracts values
Critical for understanding coded columns (status, type, etc.)
"""

from typing import Dict, List, Optional, Set, Any
from sqlalchemy import Engine, text, inspect
import logging

logger = logging.getLogger(__name__)


class CategoryDetector:
    """
    Detects and extracts category/lookup data from database.
    Essential for understanding coded columns.
    """

    # Common lookup table patterns (Oracle Retail, SAP, Microsoft Dynamics style)
    LOOKUP_PREFIXES = ['DWL_', 'LKP_', 'LOOKUP_', 'REF_', 'CODE_', 'LU_']
    LOOKUP_SUFFIXES = ['_LKP', '_LOOKUP', '_REF', '_CODE', '_TYPE', '_TYP', '_CTGRY', '_CATEGORY']

    # Common lookup table names
    LOOKUP_NAMES = {
        'status', 'stat', 'type', 'typ', 'category', 'ctgry',
        'lookup', 'lkp', 'reference', 'ref', 'code', 'cd'
    }

    # Common code column patterns
    CODE_COLUMN_PATTERNS = [
        '_cd', '_code', '_typ', '_type', '_stat', '_status',
        '_ctgry', '_category', '_class', '_flag'
    ]

    def __init__(self, engine: Engine, max_samples: int = 100):
        """
        Initialize category detector.

        Args:
            engine: SQLAlchemy engine
            max_samples: Max distinct values to sample per column
        """
        self.engine = engine
        self.max_samples = max_samples
        self._lookup_cache = {}

    def is_lookup_table(self, table_name: str) -> bool:
        """
        Determine if table is likely a lookup/category table.

        Args:
            table_name: Name of table to check

        Returns:
            bool: True if table appears to be lookup table
        """
        table_upper = table_name.upper()
        table_lower = table_name.lower()

        # Check prefixes (DWL_, LKP_, etc.)
        for prefix in self.LOOKUP_PREFIXES:
            if table_upper.startswith(prefix):
                logger.info(f"✓ {table_name} detected as lookup table (prefix: {prefix})")
                return True

        # Check suffixes (_LKP, _TYPE, etc.)
        for suffix in self.LOOKUP_SUFFIXES:
            if table_upper.endswith(suffix):
                logger.info(f"✓ {table_name} detected as lookup table (suffix: {suffix})")
                return True

        # Check if name contains lookup keywords
        for keyword in self.LOOKUP_NAMES:
            if keyword in table_lower:
                logger.info(f"✓ {table_name} detected as lookup table (keyword: {keyword})")
                return True

        return False

    def is_code_column(self, column_name: str) -> bool:
        """
        Determine if column likely contains coded values.

        Args:
            column_name: Name of column

        Returns:
            bool: True if column likely contains codes
        """
        column_lower = column_name.lower()

        # Check for code patterns
        for pattern in self.CODE_COLUMN_PATTERNS:
            if pattern in column_lower:
                return True

        # Single character columns often codes (status: A/I/D)
        if len(column_name) <= 2 and column_lower in ['s', 'st', 'ty', 'cd']:
            return True

        return False

    def sample_column_values(
        self,
        table_name: str,
        column_name: str,
        limit: int = None
    ) -> Optional[List[Any]]:
        """
        Sample distinct values from a column.

        Args:
            table_name: Table name
            column_name: Column name
            limit: Max values to return (default: self.max_samples)

        Returns:
            List of distinct values or None if error
        """
        if limit is None:
            limit = self.max_samples

        try:
            query = text(f"""
                SELECT DISTINCT {column_name}
                FROM {table_name}
                WHERE {column_name} IS NOT NULL
                LIMIT :limit
            """)

            with self.engine.connect() as conn:
                result = conn.execute(query, {"limit": limit})
                values = [row[0] for row in result]

            if values:
                logger.info(f"Sampled {len(values)} distinct values from {table_name}.{column_name}")
                return values

            return None

        except Exception as e:
            logger.warning(f"Could not sample {table_name}.{column_name}: {str(e)}")
            return None

    def get_column_cardinality(self, table_name: str, column_name: str) -> Optional[int]:
        """
        Get count of distinct values in column.

        Args:
            table_name: Table name
            column_name: Column name

        Returns:
            Number of distinct values or None
        """
        try:
            query = text(f"""
                SELECT COUNT(DISTINCT {column_name})
                FROM {table_name}
            """)

            with self.engine.connect() as conn:
                result = conn.execute(query)
                count = result.scalar()
                return count

        except Exception as e:
            logger.warning(f"Could not get cardinality for {table_name}.{column_name}: {str(e)}")
            return None

    def detect_categorical_columns(self, table_name: str) -> Dict[str, Dict[str, Any]]:
        """
        Detect which columns contain categorical data and sample their values.

        Args:
            table_name: Table name to analyze

        Returns:
            Dict mapping column names to their category info
        """
        inspector = inspect(self.engine)

        try:
            columns = inspector.get_columns(table_name)
        except Exception as e:
            logger.error(f"Could not inspect {table_name}: {str(e)}")
            return {}

        categorical_cols = {}

        for col in columns:
            col_name = col['name']
            col_type = str(col['type']).upper()

            # Skip IDs and timestamps
            if col_name.lower().endswith('_id') or 'DATE' in col_type or 'TIME' in col_type:
                continue

            # Check if it's a code column
            if not self.is_code_column(col_name):
                # For non-code columns, check cardinality for strings
                if 'VARCHAR' in col_type or 'CHAR' in col_type:
                    cardinality = self.get_column_cardinality(table_name, col_name)
                    if cardinality and cardinality <= 50:  # Low cardinality suggests categories
                        logger.info(f"Low cardinality detected for {table_name}.{col_name}: {cardinality} values")
                    else:
                        continue
                else:
                    continue

            # Sample values
            values = self.sample_column_values(table_name, col_name, limit=20)

            if values:
                cardinality = self.get_column_cardinality(table_name, col_name)
                categorical_cols[col_name] = {
                    'type': col_type,
                    'sample_values': values,
                    'distinct_count': cardinality,
                    'is_code_column': self.is_code_column(col_name)
                }

                logger.info(f"✓ Categorical column detected: {table_name}.{col_name} ({cardinality} distinct values)")

        return categorical_cols

    def find_lookup_table_for_column(
        self,
        table_name: str,
        column_name: str
    ) -> Optional[str]:
        """
        Find corresponding lookup table for a coded column.

        Args:
            table_name: Source table name
            column_name: Column with coded values

        Returns:
            Name of lookup table or None
        """
        inspector = inspect(self.engine)
        all_tables = inspector.get_table_names()

        # Build possible lookup table names
        column_base = column_name.replace('_cd', '').replace('_code', '').replace('_typ', '').replace('_type', '')

        candidates = [
            f'DWL_{column_base.upper()}',
            f'LKP_{column_base.upper()}',
            f'{column_base.upper()}_LKP',
            f'{column_base.lower()}_lookup',
            f'lkp_{column_base.lower()}',
            f'lookup_{column_base.lower()}'
        ]

        for candidate in candidates:
            if candidate in all_tables:
                logger.info(f"✓ Found lookup table for {table_name}.{column_name}: {candidate}")
                return candidate

        # Check foreign keys pointing to likely lookup tables
        try:
            foreign_keys = inspector.get_foreign_keys(table_name)
            for fk in foreign_keys:
                if column_name in fk.get('constrained_columns', []):
                    ref_table = fk.get('referred_table', '')
                    if self.is_lookup_table(ref_table):
                        logger.info(f"✓ Found lookup table via FK: {ref_table}")
                        return ref_table
        except Exception as e:
            logger.warning(f"Could not check foreign keys for {table_name}: {str(e)}")

        return None

    def get_lookup_table_description(self, lookup_table: str) -> Dict[str, Any]:
        """
        Get description of lookup table including all valid values.

        Args:
            lookup_table: Name of lookup table

        Returns:
            Dict with table info and all category values
        """
        if lookup_table in self._lookup_cache:
            return self._lookup_cache[lookup_table]

        inspector = inspect(self.engine)

        try:
            columns = inspector.get_columns(lookup_table)

            # Find code and description columns
            code_col = None
            desc_col = None

            for col in columns:
                col_name = col['name'].lower()
                if 'code' in col_name or 'cd' in col_name or col_name in ['id', 'key']:
                    code_col = col['name']
                if 'desc' in col_name or 'name' in col_name or 'label' in col_name:
                    desc_col = col['name']

            # Sample all values
            if code_col:
                query_parts = [code_col]
                if desc_col:
                    query_parts.append(desc_col)

                query = text(f"SELECT {', '.join(query_parts)} FROM {lookup_table} LIMIT 100")

                with self.engine.connect() as conn:
                    result = conn.execute(query)
                    rows = [dict(row._mapping) for row in result]

                info = {
                    'table': lookup_table,
                    'code_column': code_col,
                    'description_column': desc_col,
                    'values': rows,
                    'count': len(rows)
                }

                self._lookup_cache[lookup_table] = info
                logger.info(f"✓ Cached lookup table: {lookup_table} ({len(rows)} values)")
                return info

        except Exception as e:
            logger.error(f"Error reading lookup table {lookup_table}: {str(e)}")

        return {}

    def get_category_context(self, table_name: str) -> Dict[str, Any]:
        """
        Get comprehensive category context for a table.
        Identifies all categorical columns and their possible values.

        Args:
            table_name: Table to analyze

        Returns:
            Dict with category information for documentation
        """
        context = {
            'is_lookup_table': self.is_lookup_table(table_name),
            'categorical_columns': {},
            'related_lookups': {},
            'category_dependencies': []
        }

        # Detect categorical columns
        categorical_cols = self.detect_categorical_columns(table_name)
        context['categorical_columns'] = categorical_cols

        # Find lookup tables for each categorical column
        for col_name, col_info in categorical_cols.items():
            lookup_table = self.find_lookup_table_for_column(table_name, col_name)
            if lookup_table:
                lookup_info = self.get_lookup_table_description(lookup_table)
                if lookup_info:
                    context['related_lookups'][col_name] = lookup_info
                    context['category_dependencies'].append({
                        'column': col_name,
                        'lookup_table': lookup_table,
                        'note': f'⚠️ IMPERATIVE: Must reference {lookup_table} for valid {col_name} values'
                    })

        return context
