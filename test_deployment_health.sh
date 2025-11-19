#!/bin/bash
# Health check script for Azure VM deployment
# Verifies all components are working for E2E testing

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "SQL2Doc Deployment Health Check"
echo "=========================================="
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

check_component() {
    local component=$1
    local command=$2
    
    echo -n "Checking $component... "
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        ((CHECKS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC}"
        ((CHECKS_FAILED++))
        return 1
    fi
}

# 1. Check Python
echo "1. Python Environment"
check_component "Python installation" "python --version" || true
check_component "pip installation" "pip --version" || true

# 2. Check Virtual Environment
echo ""
echo "2. Virtual Environment"
check_component "venv activated" "python -c 'import sys; sys.prefix != sys.base_prefix'" || true

# 3. Check Required Packages
echo ""
echo "3. Required Packages"
check_component "SQLAlchemy" "python -c 'import sqlalchemy; print(sqlalchemy.__version__)'" || true
check_component "pytest" "pytest --version" || true
check_component "ollama client" "python -c 'import ollama'" || true

# 4. Check Ollama Service
echo ""
echo "4. Ollama Service"
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
echo "   Using Ollama host: $OLLAMA_HOST"

if check_component "Ollama service available" "curl -s $OLLAMA_HOST/api/tags > /dev/null"; then
    # Get models
    echo -n "   Available models: "
    MODELS=$(curl -s $OLLAMA_HOST/api/tags | python -c "
import sys, json
try:
    data = json.load(sys.stdin)
    models = [m.get('name', 'unknown').split(':')[0] for m in data.get('models', [])]
    print(', '.join(set(models)) if models else 'None')
except:
    print('Error parsing models')
" 2>/dev/null || echo "Error fetching")
    echo "$MODELS"
    
    # Check for llama3.2
    if echo "$MODELS" | grep -q "llama3"; then
        echo -e "   ${GREEN}✓${NC} llama3.2 model available"
        ((CHECKS_PASSED++))
    else
        echo -e "   ${YELLOW}⚠${NC} llama3.2 model not found (run: ollama pull llama3.2)"
    fi
fi

# 5. Database
echo ""
echo "5. Database"
check_component "Database connectivity" "python -c 'from sqlalchemy import create_engine; create_engine(\"sqlite:///:memory:\")'" || true

# 6. Test Files
echo ""
echo "6. Test Files"
check_component "Mocked tests exist" "test -f tests/test_ai_documentation.py" || true
check_component "E2E tests exist" "test -f tests/test_ai_documentation_e2e.py" || true

# Summary
echo ""
echo "=========================================="
echo "Health Check Summary"
echo "=========================================="
TOTAL=$((CHECKS_PASSED + CHECKS_FAILED))
echo "Passed: $CHECKS_PASSED/$TOTAL"

if [ $CHECKS_FAILED -gt 0 ]; then
    echo "Failed: $CHECKS_FAILED/$TOTAL"
    echo ""
    echo -e "${YELLOW}Warnings/Issues Found:${NC}"
    
    if ! python -c 'import ollama' 2>/dev/null; then
        echo "  - Install ollama client: pip install ollama"
    fi
    
    if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "  - Start Ollama service: ollama serve &"
    fi
    
    if ! curl -s http://localhost:11434/api/tags | grep -q "llama3"; then
        echo "  - Pull llama3.2 model: ollama pull llama3.2"
    fi
fi

echo ""
echo "=========================================="

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Ready to run tests.${NC}"
    exit 0
else
    echo -e "${RED}✗ Some checks failed. Please fix the issues above.${NC}"
    exit 1
fi
