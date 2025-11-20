# SQL2Doc Codebase Structure

**Clean, microservices-based architecture for GraphRAG-enhanced database documentation**

## Directory Structure

```
sql2doc/
├── graphrag-service/              # Backend GraphRAG API Service
│   ├── api.py                      # FastAPI application
│   ├── Dockerfile                  # Backend container image
│   ├── requirements.txt            # Python dependencies
│   └── src/                        # Source modules
│       ├── category_detector.py
│       ├── codebert_embedder.py
│       ├── graph_builder.py
│       └── relationship_inference_engine.py
│
├── ui-service/                    # Frontend Streamlit UI Service
│   ├── app.py                      # Streamlit application
│   ├── Dockerfile                  # Frontend container image
│   └── requirements.txt            # Python dependencies
│
├── test_data/                     # SQL scripts for test databases
│   ├── healthcare_ods.sql
│   ├── telecom_ocdm.sql
│   └── legal_collections.sql
│
├── azure-deployment/              # Infrastructure as Code
│   ├── terraform/                  # Terraform configs
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── scripts/                    # Deployment scripts
│       ├── setup-graphrag-vm.sh
│       └── setup-ui-vm.sh
│
├── docker-compose.yml             # Local development setup
├── docker-compose.microservices.yml  # Production setup (2 VMs)
├── requirements.txt               # Root dependencies (legacy)
├── README.md                      # Project documentation
└── CODEBASE_STRUCTURE.md          # This file
```

## Service Architecture

### 1. GraphRAG Service (Backend)
**Port:** 8000
**Technology:** FastAPI + Neo4j + Ollama + PostgreSQL

**Responsibilities:**
- Database schema extraction
- Knowledge graph construction
- Relationship inference using CodeBERT
- AI-powered documentation generation via Ollama
- RESTful API for UI

**Key Endpoints:**
- `GET /health` - Service health check
- `POST /graph/build` - Build knowledge graph for database
- `GET /graph/{db_id}/tables` - List all tables
- `POST /graph/context` - Get rich context for a table
- `POST /documentation/generate` - Generate AI documentation

### 2. UI Service (Frontend)
**Port:** 8501
**Technology:** Streamlit

**Responsibilities:**
- User interface for database connection
- Dynamic database discovery from PostgreSQL
- Knowledge graph visualization
- Table exploration with rich context
- Documentation generation and export

**Features:**
- Dynamic database browser (fetches from PostgreSQL server)
- Preset database quick access
- Custom connection support
- AI documentation with export to JSON/Markdown

## Deployment Models

### Local Development
```bash
docker-compose up
```
- All services on one machine
- Shared network
- PostgreSQL, Ollama, GraphRAG API, and UI

### Production (2-VM Azure)
```bash
# VM1: GraphRAG + Ollama + PostgreSQL
# VM2: UI Service

cd azure-deployment/terraform
terraform apply
```

**VM 1 (GraphRAG VM):**
- GraphRAG API (port 8000)
- Ollama LLM (port 11434)
- PostgreSQL (port 5432)

**VM 2 (UI VM):**
- Streamlit UI (port 8501)

## Key Design Decisions

### 1. Microservices Architecture
- **Why:** Scalability, independent deployment, clear separation of concerns
- **Trade-off:** More complex orchestration vs monolithic simplicity

### 2. Dynamic Database Discovery
- **Why:** No hardcoded database list, user can see all available DBs
- **Implementation:** Query PostgreSQL system catalog via psycopg2

### 3. Ollama for Local LLM
- **Why:** Privacy, no external API costs, full control
- **Trade-off:** Requires GPU/significant RAM vs external API simplicity

### 4. Neo4j for Knowledge Graph
- **Why:** Native graph database, Cypher query language, GraphRAG patterns
- **Trade-off:** Additional service vs using PostgreSQL

## Getting Started

### Prerequisites
- Docker & Docker Compose
- Python 3.11+
- Azure CLI (for cloud deployment)
- Terraform (for infrastructure)

### Quick Start

1. **Clone repository**
   ```bash
   git clone <repo-url>
   cd sql2doc
   ```

2. **Local Development**
   ```bash
   docker-compose up -d
   ```

   Access services:
   - UI: http://localhost:8501
   - GraphRAG API: http://localhost:8000/docs
   - Ollama: http://localhost:11434

3. **Azure Deployment**
   ```bash
   cd azure-deployment/terraform
   terraform init
   terraform apply
   ```

## Environment Variables

### GraphRAG Service
```bash
OLLAMA_HOST=http://ollama:11434
OLLAMA_MODEL=llama3.2
DATABASE_URL=postgresql://user:pass@host:5432/dbname
LOG_LEVEL=INFO
```

### UI Service
```bash
GRAPHRAG_API_URL=http://graphrag:8000
```

## Contributing

When adding features:
1. Keep services decoupled
2. Use environment variables for config
3. Update both local and production docker-compose files
4. Document API changes in OpenAPI spec
5. Test with all three test databases

## License

Proprietary - Internal Use Only
