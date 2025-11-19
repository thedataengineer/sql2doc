"""
GraphRAG Microservice API
FastAPI service exposing GraphRAG functionality as REST endpoints
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from sqlalchemy import create_engine, text
import ollama
import logging
import os
import sys
from datetime import datetime

# Add parent directory to path for imports
sys.path.insert(0, '/app/src')
from graphrag_engine import GraphRAGEngine, SchemaKnowledgeGraph

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI
app = FastAPI(
    title="GraphRAG Service",
    description="Graph-based Retrieval Augmented Generation for Database Schema Documentation",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global state
knowledge_graphs: Dict[str, SchemaKnowledgeGraph] = {}
graphrag_engines: Dict[str, GraphRAGEngine] = {}


# Pydantic models
class DatabaseConfig(BaseModel):
    database_url: str = Field(..., description="SQLAlchemy database URL")
    database_id: str = Field(..., description="Unique identifier for this database")


class TableContextRequest(BaseModel):
    database_id: str
    table_name: str
    depth: int = Field(default=2, ge=1, le=5, description="Graph traversal depth")


class DocumentationRequest(BaseModel):
    database_id: str
    table_name: str
    include_relationships: bool = True
    include_semantic_cluster: bool = True


class RelationshipPathRequest(BaseModel):
    database_id: str
    source_table: str
    target_table: str


class GraphExportRequest(BaseModel):
    database_id: str
    format: str = Field(default="json", pattern="^(json|graphml)$")


class HealthResponse(BaseModel):
    status: str
    timestamp: str
    ollama_status: str
    active_databases: int


# Helper functions
def get_ollama_client():
    """Get Ollama client with configured host."""
    ollama_host = os.getenv("OLLAMA_HOST", "http://localhost:11434")
    try:
        client = ollama.Client(host=ollama_host)
        # Test connection
        client.list()
        return client
    except Exception as e:
        logger.error(f"Failed to connect to Ollama: {e}")
        return None


def get_knowledge_graph(database_id: str) -> SchemaKnowledgeGraph:
    """Get or create knowledge graph for database."""
    if database_id not in knowledge_graphs:
        raise HTTPException(status_code=404, detail=f"Database {database_id} not found. Build graph first.")
    return knowledge_graphs[database_id]


def get_graphrag_engine(database_id: str) -> GraphRAGEngine:
    """Get or create GraphRAG engine for database."""
    if database_id not in graphrag_engines:
        raise HTTPException(status_code=404, detail=f"GraphRAG engine for {database_id} not initialized")
    return graphrag_engines[database_id]


# API Endpoints

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint."""
    ollama_client = get_ollama_client()
    ollama_status = "connected" if ollama_client else "disconnected"

    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow().isoformat(),
        ollama_status=ollama_status,
        active_databases=len(knowledge_graphs)
    )


@app.post("/graph/build")
async def build_knowledge_graph(config: DatabaseConfig, background_tasks: BackgroundTasks):
    """
    Build knowledge graph for a database.
    This can take 10-30 seconds for large databases, so it runs in background.
    """
    database_id = config.database_id

    try:
        # Create engine
        engine = create_engine(config.database_url, pool_pre_ping=True)

        # Test connection
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))

        # Build knowledge graph
        kg = SchemaKnowledgeGraph(engine)
        kg.build_graph()

        # Store globally
        knowledge_graphs[database_id] = kg

        # Initialize GraphRAG engine if Ollama available
        ollama_client = get_ollama_client()
        if ollama_client:
            graphrag = GraphRAGEngine(
                engine,
                ollama_client,
                model=os.getenv("OLLAMA_MODEL", "llama3.2")
            )
            graphrag.kg = kg  # Use already-built graph
            graphrag_engines[database_id] = graphrag

        logger.info(f"Built knowledge graph for {database_id}: {len(kg.nodes)} nodes, {len(kg.edges)} edges")

        return {
            "status": "success",
            "database_id": database_id,
            "statistics": {
                "total_nodes": len(kg.nodes),
                "total_edges": len(kg.edges),
                "total_tables": len(kg.get_all_tables())
            },
            "ollama_available": ollama_client is not None
        }

    except Exception as e:
        logger.error(f"Error building knowledge graph for {database_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/graph/{database_id}/tables")
async def list_tables(database_id: str):
    """Get list of all tables in knowledge graph."""
    kg = get_knowledge_graph(database_id)

    tables = kg.get_all_tables()
    table_info = []

    for table_name in tables:
        categories = list(kg.table_categories.get(table_name, set()))
        table_node_id = f"table:{table_name}"

        if table_node_id in kg.nodes:
            node = kg.nodes[table_node_id]
            table_info.append({
                "name": table_name,
                "categories": categories,
                "row_count": node.properties.get("row_count", 0),
                "column_count": node.properties.get("column_count", 0)
            })

    return {
        "database_id": database_id,
        "total_tables": len(tables),
        "tables": table_info
    }


@app.post("/graph/context")
async def get_table_context(request: TableContextRequest):
    """Get rich context for a table including relationships and semantic cluster."""
    kg = get_knowledge_graph(request.database_id)

    try:
        context = kg.get_table_context(request.table_name, depth=request.depth)

        if not context:
            raise HTTPException(status_code=404, detail=f"Table {request.table_name} not found")

        return {
            "database_id": request.database_id,
            "table_name": request.table_name,
            "context": context
        }

    except Exception as e:
        logger.error(f"Error getting context for {request.table_name}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/graph/path")
async def find_relationship_path(request: RelationshipPathRequest):
    """Find shortest relationship path between two tables."""
    kg = get_knowledge_graph(request.database_id)

    try:
        path = kg.get_relationship_path(request.source_table, request.target_table)

        if path is None:
            return {
                "database_id": request.database_id,
                "source_table": request.source_table,
                "target_table": request.target_table,
                "path_found": False,
                "message": "No path found between tables"
            }

        return {
            "database_id": request.database_id,
            "source_table": request.source_table,
            "target_table": request.target_table,
            "path_found": True,
            "path": path,
            "path_length": len(path)
        }

    except Exception as e:
        logger.error(f"Error finding path: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/documentation/generate")
async def generate_documentation(request: DocumentationRequest):
    """Generate AI-enhanced documentation using GraphRAG."""
    graphrag = get_graphrag_engine(request.database_id)

    try:
        docs = graphrag.generate_enriched_documentation(
            request.table_name,
            include_relationships=request.include_relationships,
            include_semantic_cluster=request.include_semantic_cluster
        )

        return {
            "database_id": request.database_id,
            "table_name": request.table_name,
            "documentation": docs
        }

    except Exception as e:
        logger.error(f"Error generating documentation for {request.table_name}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/graph/export")
async def export_graph(request: GraphExportRequest):
    """Export knowledge graph in specified format."""
    kg = get_knowledge_graph(request.database_id)

    try:
        graph_data = kg.export_graph(format=request.format)

        return {
            "database_id": request.database_id,
            "format": request.format,
            "graph_data": graph_data
        }

    except Exception as e:
        logger.error(f"Error exporting graph: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/graph/{database_id}/statistics")
async def get_graph_statistics(database_id: str):
    """Get detailed statistics about the knowledge graph."""
    kg = get_knowledge_graph(database_id)

    # Count node types
    node_types = {}
    for node in kg.nodes.values():
        node_types[node.node_type] = node_types.get(node.node_type, 0) + 1

    # Count edge types
    edge_types = {}
    for edge in kg.edges:
        edge_types[edge.edge_type] = edge_types.get(edge.edge_type, 0) + 1

    # Count table categories
    category_counts = {}
    for categories in kg.table_categories.values():
        for category in categories:
            category_counts[category] = category_counts.get(category, 0) + 1

    return {
        "database_id": database_id,
        "statistics": {
            "total_nodes": len(kg.nodes),
            "total_edges": len(kg.edges),
            "node_types": node_types,
            "edge_types": edge_types,
            "category_distribution": category_counts,
            "total_tables": len(kg.get_all_tables())
        }
    }


@app.delete("/graph/{database_id}")
async def delete_knowledge_graph(database_id: str):
    """Delete knowledge graph and free memory."""
    if database_id in knowledge_graphs:
        del knowledge_graphs[database_id]

    if database_id in graphrag_engines:
        del graphrag_engines[database_id]

    return {
        "status": "success",
        "message": f"Knowledge graph for {database_id} deleted",
        "remaining_databases": len(knowledge_graphs)
    }


@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "service": "GraphRAG Microservice",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "health": "/health",
            "build_graph": "POST /graph/build",
            "list_tables": "GET /graph/{database_id}/tables",
            "get_context": "POST /graph/context",
            "find_path": "POST /graph/path",
            "generate_docs": "POST /documentation/generate",
            "export_graph": "POST /graph/export",
            "statistics": "GET /graph/{database_id}/statistics"
        },
        "documentation": "/docs"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)