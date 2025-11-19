#!/bin/bash
# Script to run E2E tests on Azure VM deployment
# This script runs the AI documentation e2e tests against a deployed instance

set -e

echo "=========================================="
echo "SQL2Doc E2E Tests - Azure VM Execution"
echo "=========================================="
echo ""

# Configuration
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
PYTEST_OPTIONS="${PYTEST_OPTIONS:--v --tb=short}"
TEST_FILE="${TEST_FILE:-tests/test_ai_documentation_e2e.py}"

echo "Configuration:"
echo "  Ollama Host: $OLLAMA_HOST"
echo "  Test File: $TEST_FILE"
echo "  Pytest Options: $PYTEST_OPTIONS"
echo ""

# Check Python environment
echo "Checking Python environment..."
python --version
echo ""

# Check if Ollama is available
echo "Checking Ollama availability at $OLLAMA_HOST..."
if curl -s "$OLLAMA_HOST/api/tags" > /dev/null; then
    echo "✓ Ollama service is available"
    echo ""
    
    # List available models
    echo "Available Ollama models:"
    curl -s "$OLLAMA_HOST/api/tags" | python -m json.tool | grep -A 5 '"name"' | head -20
    echo ""
else
    echo "⚠ Warning: Ollama service not reachable at $OLLAMA_HOST"
    echo "  Tests marked with @ollama_available will be skipped"
    echo ""
fi

# Check required model
echo "Checking for llama3.2 model..."
if curl -s "$OLLAMA_HOST/api/tags" | grep -q "llama3.2"; then
    echo "✓ llama3.2 model is available"
    echo ""
else
    echo "⚠ Warning: llama3.2 model not found"
    echo "  To install: ollama pull llama3.2"
    echo ""
fi

# Run tests
echo "Running E2E tests..."
echo "=========================================="
echo ""

# Run real Ollama-based e2e tests
if [ -f "$TEST_FILE" ]; then
    pytest "$TEST_FILE" $PYTEST_OPTIONS
    TEST_EXIT_CODE=$?
else
    echo "Error: Test file not found: $TEST_FILE"
    exit 1
fi

echo ""
echo "=========================================="
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✓ All E2E tests passed!"
else
    echo "✗ Some tests failed (exit code: $TEST_EXIT_CODE)"
fi
echo "=========================================="

exit $TEST_EXIT_CODE
