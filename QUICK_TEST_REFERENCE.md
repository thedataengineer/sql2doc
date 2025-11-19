# Quick Test Reference Guide

## One-Liners for Azure VM

### Pre-test Checks
```bash
# Health check (all systems go?)
./test_deployment_health.sh

# Check Ollama service
curl http://localhost:11434/api/tags | python -m json.tool
```

### Run Tests
```bash
# Run all E2E tests
./run_e2e_tests_azure.sh

# Run just schema explainer tests
pytest tests/test_ai_documentation_e2e.py::TestSchemaExplainerWithRealOllama -v

# Run just NL query tests
pytest tests/test_ai_documentation_e2e.py::TestNaturalLanguageQueryGeneratorWithRealOllama -v

# Run integration tests
pytest tests/test_ai_documentation_e2e.py::TestAIDocumentationIntegrationWithRealOllama -v
```

### Run Tests with Custom Config
```bash
# With remote Ollama
OLLAMA_HOST="http://remote-host:11434" ./run_e2e_tests_azure.sh

# With custom pytest options
PYTEST_OPTIONS="-vv --tb=long" ./run_e2e_tests_azure.sh

# With specific test file
TEST_FILE="tests/test_ai_documentation.py" ./run_e2e_tests_azure.sh
```

## Local Development

### Setup
```bash
# Activate venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Ensure Ollama is running
ollama serve &
ollama pull llama3.2
```

### Run Tests
```bash
# Fast tests (no Ollama needed)
pytest tests/test_ai_documentation.py -v

# Full E2E tests (with Ollama)
pytest tests/test_ai_documentation_e2e.py -v

# All tests
pytest tests/ -v

# Specific test
pytest tests/test_ai_documentation_e2e.py::TestSchemaExplainerWithRealOllama::test_explain_table_real_ollama -v
```

### Coverage
```bash
# Generate coverage report
pytest tests/ --cov=src --cov-report=html

# View in browser
open htmlcov/index.html
```

### Debug Mode
```bash
# Verbose with debug logging
pytest tests/ -vv --log-cli-level=DEBUG

# Stop on first failure
pytest tests/ -x -v

# Show print statements
pytest tests/ -s -v
```

## Troubleshooting Commands

### Check Ollama
```bash
# Is Ollama running?
curl http://localhost:11434/api/tags

# Start Ollama
ollama serve &

# Pull model
ollama pull llama3.2

# List models
ollama list
```

### Check Environment
```bash
# Python version
python --version

# Package versions
pip list | grep -E "sqlalchemy|pytest|ollama"

# Which Python
which python

# Virtual env check
python -c "import sys; print(sys.prefix)"
```

### Test Diagnostics
```bash
# Run single test with full output
pytest tests/test_ai_documentation_e2e.py::TestSchemaExplainerWithRealOllama::test_explain_table_real_ollama -vv -s

# Show all captured output
pytest tests/ -v --tb=long --capture=no

# Detailed failure info
pytest tests/ -v --tb=long -rf

# Create JUnit XML report
pytest tests/ --junit-xml=report.xml
```

## Performance Monitoring

### Test Timing
```bash
# Show test durations
pytest tests/test_ai_documentation_e2e.py -v --durations=10

# Profile specific test
pytest tests/test_ai_documentation_e2e.py::TestSchemaExplainerWithRealOllama::test_explain_table_real_ollama -v --durations=0
```

### System Monitoring
```bash
# Watch Ollama process
watch -n 1 'ps aux | grep ollama'

# Memory usage
ps aux | grep ollama | awk '{print $6 " KB"}'

# CPU usage
top -p $(pgrep ollama) -b -n 1
```

## Batch Testing

### Run Everything
```bash
# All tests with summary
pytest tests/ -v --tb=short

# All tests with coverage
pytest tests/ -v --cov=src --cov-report=term-missing

# Parallel execution (faster)
pytest tests/ -n auto
```

### Run by Category
```bash
# Just mocked tests
pytest tests/test_ai_documentation.py -v

# Just E2E tests
pytest tests/test_ai_documentation_e2e.py -v

# Just schema explainer
pytest tests/ -k "SchemaExplainer" -v

# Just NL query generator
pytest tests/ -k "NaturalLanguageQueryGenerator" -v

# Just integration tests
pytest tests/ -k "Integration" -v
```

## CI/CD Integration

### GitHub Actions
```bash
# Run tests (will skip E2E if no Ollama)
pytest tests/ -v --junit-xml=results.xml

# With Ollama service
ollama serve &
ollama pull llama3.2
pytest tests/ -v
```

### Azure DevOps
```bash
# In pipeline
pip install -r requirements.txt
pytest tests/test_ai_documentation_e2e.py -v --junit-xml=$(Build.ArtifactStagingDirectory)/results.xml
```

## Environment Variables Reference

```bash
# Ollama Configuration
export OLLAMA_HOST="http://localhost:11434"  # Default
export OLLAMA_HOST="http://remote-host:11434"  # Remote

# Test Configuration  
export TEST_FILE="tests/test_ai_documentation_e2e.py"
export PYTEST_OPTIONS="-v --tb=short"

# Combined example
export OLLAMA_HOST="http://ollama-vm:11434" \
       TEST_FILE="tests/test_ai_documentation_e2e.py" \
       PYTEST_OPTIONS="-vv" && ./run_e2e_tests_azure.sh
```

## Output Examples

### Successful Run
```
tests/test_ai_documentation_e2e.py::TestSchemaExplainerWithRealOllama::test_explain_table_real_ollama PASSED [ 5%]
...
======================== 17 passed in 87.90s =========================
```

### Skipped Tests (Ollama not available)
```
tests/test_ai_documentation_e2e.py::TestSchemaExplainerWithRealOllama::test_explain_table_real_ollama SKIPPED [ 5%]
(reason: Ollama service not available at http://localhost:11434)
```

### With Failures
```
FAILED tests/test_ai_documentation_e2e.py::TestSomeTest - AssertionError: ...
======================== 1 failed, 16 passed in 88.5s ========================
```

## Quick Checklist

### Before Running Tests
- [ ] Virtual environment activated
- [ ] Dependencies installed (`pip install -r requirements.txt`)
- [ ] Ollama running (`ollama serve &`)
- [ ] Model available (`ollama pull llama3.2`)
- [ ] Health check passing (`./test_deployment_health.sh`)

### Running Tests
- [ ] Run mocked tests first: `pytest tests/test_ai_documentation.py -v`
- [ ] Run E2E tests: `pytest tests/test_ai_documentation_e2e.py -v`
- [ ] Check coverage: `pytest --cov=src`
- [ ] Review results

### Troubleshooting
- [ ] Check Ollama: `curl http://localhost:11434/api/tags`
- [ ] Check models: `ollama list`
- [ ] Check Python: `python -c "import src.schema_explainer"`
- [ ] Run health check: `./test_deployment_health.sh`

## Documentation Links

- [E2E_TESTS_SUMMARY.md](E2E_TESTS_SUMMARY.md) - Detailed test overview
- [AZURE_E2E_TESTING.md](AZURE_E2E_TESTING.md) - Azure deployment guide
- [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) - Architecture & development
- [README.md](README.md) - Project overview
