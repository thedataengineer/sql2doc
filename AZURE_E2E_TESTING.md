# E2E Testing on Azure VM Deployment

This guide explains how to run the end-to-end tests for the AI documentation features on your Azure VM deployment.

## Prerequisites

1. **Deployed Application**: sql2doc running on Azure VM
2. **Ollama Service**: Running locally or accessible on the VM
3. **Python Environment**: Virtual environment with dependencies installed
4. **pytest**: Already included in requirements.txt

## Test Files

Two test suites are available:

### 1. Mocked Tests (Fast, No External Dependencies)
- **File**: `tests/test_ai_documentation.py`
- **Tests**: 33 tests
- **Duration**: ~1 second
- **Use Case**: Quick validation, CI/CD pipelines
- **Command**:
  ```bash
  pytest tests/test_ai_documentation.py -v
  ```

### 2. Real Ollama Tests (E2E, Comprehensive)
- **File**: `tests/test_ai_documentation_e2e.py`
- **Tests**: 17 tests
- **Duration**: ~1-2 minutes
- **Use Case**: Full integration testing, production validation
- **Requirements**: Ollama service running, llama3.2 model available
- **Command**:
  ```bash
  pytest tests/test_ai_documentation_e2e.py -v
  ```

## Azure VM Setup

### 1. Connect to Azure VM
```bash
# SSH into your Azure VM
ssh -i your-key.pem azureuser@your-vm-ip
```

### 2. Verify Ollama Installation
```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# If not running, start Ollama service
ollama serve &

# Ensure llama3.2 is available
ollama list
# If missing: ollama pull llama3.2
```

### 3. Navigate to Application Directory
```bash
cd /path/to/sql2doc
source venv/bin/activate  # Activate virtual environment
```

### 4. Run E2E Tests

#### Option A: Using the Automated Script
```bash
./run_e2e_tests_azure.sh
```

**With Custom Ollama Host:**
```bash
OLLAMA_HOST="http://remote-host:11434" ./run_e2e_tests_azure.sh
```

#### Option B: Running Pytest Directly

**Run Real Ollama Tests Only:**
```bash
pytest tests/test_ai_documentation_e2e.py -v
```

**Run Specific Test Class:**
```bash
pytest tests/test_ai_documentation_e2e.py::TestSchemaExplainerWithRealOllama -v
```

**Run Specific Test:**
```bash
pytest tests/test_ai_documentation_e2e.py::TestSchemaExplainerWithRealOllama::test_explain_table_real_ollama -v
```

**Run All Tests (Mocked + Real):**
```bash
pytest tests/ -v
```

**Run with Coverage:**
```bash
pytest tests/test_ai_documentation_e2e.py --cov=src --cov-report=html
```

## Environment Variables

### Ollama Configuration
```bash
# Set custom Ollama host
export OLLAMA_HOST="http://localhost:11434"

# Or for remote Ollama service
export OLLAMA_HOST="http://ollama-server.internal:11434"
```

### Test Configuration
```bash
# Run specific test file
export TEST_FILE="tests/test_ai_documentation_e2e.py"

# Custom pytest options
export PYTEST_OPTIONS="-v --tb=short -x"  # -x stops on first failure
```

## Test Output Examples

### Successful Test Run
```
tests/test_ai_documentation_e2e.py::TestSchemaExplainerWithRealOllama::test_explain_table_real_ollama PASSED [  5%]
tests/test_ai_documentation_e2e.py::TestSchemaExplainerWithRealOllama::test_explain_column_real_ollama PASSED [ 11%]
...
==================== 17 passed in 87.90s ====================
```

### Skip Tests (Ollama Not Available)
```
tests/test_ai_documentation_e2e.py::TestSchemaExplainerWithRealOllama::test_explain_table_real_ollama SKIPPED [ 5%]
(reason: Ollama service not available at http://localhost:11434)
```

## Troubleshooting

### Ollama Service Not Responding
```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# Start Ollama if needed
ollama serve &

# Check logs
journalctl -u ollama -f  # If using systemd
```

### Model Not Available
```bash
# List available models
ollama list

# Pull required model
ollama pull llama3.2

# Verify it's available
ollama list | grep llama3.2
```

### Connection Refused
```bash
# If Ollama is on a different host, update environment
export OLLAMA_HOST="http://other-vm:11434"

# Test connectivity
curl $OLLAMA_HOST/api/tags
```

### Database Connection Issues
```bash
# Check database connectivity in test
# Tests create in-memory SQLite databases, so no DB config needed

# If running against external database, update test fixtures
# Modify test_engine fixture in test file
```

## CI/CD Integration

### GitHub Actions Example
```yaml
name: E2E Tests

on: [push, pull_request]

jobs:
  e2e-tests:
    runs-on: ubuntu-latest
    
    services:
      ollama:
        image: ollama/ollama:latest
        options: >-
          --health-cmd="curl -f http://localhost:11434/api/tags || exit 1"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5
        ports:
          - 11434:11434
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.12'
      
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
      
      - name: Pull Ollama model
        run: ollama pull llama3.2
      
      - name: Run E2E tests
        run: pytest tests/test_ai_documentation_e2e.py -v
```

### Azure DevOps Pipeline Example
```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  pythonVersion: '3.12'
  OLLAMA_HOST: 'http://localhost:11434'

steps:
  - task: UsePythonVersion@0
    inputs:
      versionSpec: '$(pythonVersion)'
  
  - script: |
      pip install -r requirements.txt
    displayName: 'Install dependencies'
  
  - script: |
      ollama serve &
      sleep 5
      ollama pull llama3.2
    displayName: 'Start Ollama service'
  
  - script: |
      pytest tests/test_ai_documentation_e2e.py -v --junit-xml=junit/test-results.xml
    displayName: 'Run E2E tests'
  
  - task: PublishTestResults@2
    inputs:
      testResultsFiles: '**/junit/test-results.xml'
      testRunTitle: 'E2E Tests'
    condition: succeededOrFailed()
```

## Performance Notes

### Test Duration
- **Mocked tests**: ~1 second total
- **Real Ollama tests**: ~1-2 minutes total
  - Schema explanation: 200-400ms per table
  - NL query generation: 300-600ms per question
  - Dictionary enhancement: 2-5 seconds for small schemas

### Optimization Tips
1. **Parallel Execution**: Use pytest-xdist for faster runs
   ```bash
   pytest tests/test_ai_documentation_e2e.py -n auto
   ```

2. **Skip Slow Tests**: Focus on critical paths
   ```bash
   pytest tests/test_ai_documentation_e2e.py -m "not slow"
   ```

3. **Cache Models**: Ensure llama3.2 is already pulled to avoid download time

## Monitoring & Logging

### Enable Debug Logging
```bash
# Run with verbose output
pytest tests/test_ai_documentation_e2e.py -vv --log-cli-level=DEBUG
```

### Monitor Ollama Performance
```bash
# Watch Ollama service
watch -n 1 curl http://localhost:11434/api/tags

# Check system resources
top -p $(pgrep ollama)

# View Ollama logs
tail -f ~/.ollama/logs/ollama.log
```

## Test Coverage

### Current Coverage
- **SchemaExplainer**: 16 tests (mocked) + 7 tests (real Ollama)
- **NaturalLanguageQueryGenerator**: 15 tests (mocked) + 8 tests (real Ollama)
- **Integration**: 2 tests (mocked) + 3 tests (real Ollama)

### Generate Coverage Report
```bash
pytest tests/ --cov=src --cov-report=html --cov-report=term

# View HTML report
open htmlcov/index.html
```

## Next Steps

1. **Run tests regularly**: Add to CI/CD pipeline
2. **Monitor performance**: Track test execution times
3. **Expand test coverage**: Add tests for edge cases
4. **Update tests**: Keep in sync with feature changes

## Support

For issues or questions:
1. Check test output for specific error messages
2. Review troubleshooting section above
3. Check Ollama logs and service status
4. Verify database connectivity
5. Ensure Python environment has all dependencies
