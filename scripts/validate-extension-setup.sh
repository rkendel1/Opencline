#!/bin/bash
# Validation script for Docker extension setup
# This script validates that all required files and configurations are in place

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function to print colored output
log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

echo "================================================"
echo "Docker Extension Setup Validation"
echo "================================================"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

# Check required files
echo "Checking required files..."
FILES=(
    "Dockerfile"
    "docker-compose.yml"
    "Makefile"
    ".dockerignore"
    "package.json"
    "scripts/package-extension.sh"
    "scripts/cline-integration.sh"
    "DOCKER.md"
    "DOCKER_INDEX.md"
    "DOCKER_EXTENSION.md"
    "DOCKER_QUICK_START.md"
)

ALL_FILES_OK=true
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        log_info "Found: $file"
    else
        log_error "Missing: $file"
        ALL_FILES_OK=false
    fi
done

echo ""

# Check Dockerfile content
echo "Checking Dockerfile configuration..."
if grep -q "vsce" Dockerfile; then
    log_info "Dockerfile includes vsce installation"
else
    log_error "Dockerfile missing vsce installation"
    ALL_FILES_OK=false
fi

if grep -q "code-server --install-extension" Dockerfile; then
    log_info "Dockerfile includes extension installation"
else
    log_error "Dockerfile missing extension installation"
    ALL_FILES_OK=false
fi

echo ""

# Check package.json scripts
echo "Checking package.json scripts..."
if grep -q "package:vsix" package.json; then
    log_info "package.json includes package:vsix script"
else
    log_warn "package.json missing package:vsix script (optional)"
fi

if grep -q "package:docker" package.json; then
    log_info "package.json includes package:docker script"
else
    log_warn "package.json missing package:docker script (optional)"
fi

echo ""

# Check .dockerignore
echo "Checking .dockerignore..."
if [ -f ".dockerignore" ]; then
    if grep -q "node_modules" .dockerignore; then
        log_info ".dockerignore excludes node_modules"
    else
        log_warn ".dockerignore should exclude node_modules"
    fi
    
    if grep -q "dist" .dockerignore; then
        log_info ".dockerignore excludes dist"
    else
        log_warn ".dockerignore should exclude dist"
    fi
fi

echo ""

# Check if scripts are executable
echo "Checking script permissions..."
if [ -x "scripts/package-extension.sh" ]; then
    log_info "scripts/package-extension.sh is executable"
else
    log_error "scripts/package-extension.sh is not executable"
    ALL_FILES_OK=false
fi

if [ -x "scripts/cline-integration.sh" ]; then
    log_info "scripts/cline-integration.sh is executable"
else
    log_error "scripts/cline-integration.sh is not executable"
    ALL_FILES_OK=false
fi

echo ""

# Check Makefile targets
echo "Checking Makefile..."
if grep -q "^build:" Makefile; then
    log_info "Makefile has build target"
else
    log_error "Makefile missing build target"
    ALL_FILES_OK=false
fi

if grep -q "^up:" Makefile; then
    log_info "Makefile has up target"
else
    log_error "Makefile missing up target"
    ALL_FILES_OK=false
fi

echo ""

# Summary
echo "================================================"
if [ "$ALL_FILES_OK" = true ]; then
    log_info "All validation checks passed!"
    echo ""
    echo "Your Docker setup is ready. Next steps:"
    echo "  1. Run 'make init' to create .env file (optional)"
    echo "  2. Run 'make build' to build the Docker image"
    echo "  3. Run 'make up' to start the environment"
    echo "  4. Access Code Server at http://localhost:8080"
else
    log_error "Some validation checks failed. Please review the errors above."
    exit 1
fi
echo "================================================"
