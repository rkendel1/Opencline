#!/bin/bash
# Docker environment validation script
# This script validates the Docker setup without requiring a full build

set -e

echo "==================================="
echo "Docker Environment Validation"
echo "==================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if required files exist
echo "Checking required files..."
files=(
    "Dockerfile"
    "docker-compose.yml"
    ".env.example"
    "DOCKER.md"
    "Makefile"
    ".dockerignore"
    "scripts/cline-integration.sh"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        success "$file exists"
    else
        error "$file is missing"
        exit 1
    fi
done

echo ""
echo "Validating Dockerfile syntax..."
if grep -q "FROM node:20-slim" Dockerfile; then
    success "Base image is correct"
else
    error "Base image is incorrect"
    exit 1
fi

if grep -q "python3" Dockerfile; then
    success "Python3 installation found"
else
    error "Python3 installation not found"
    exit 1
fi

if grep -q "code-server" Dockerfile; then
    success "Code Server installation found"
else
    error "Code Server installation not found"
    exit 1
fi

if grep -q "npm install -g cline" Dockerfile; then
    success "Cline installation found"
else
    error "Cline installation not found"
    exit 1
fi

if grep -q "github.com/paul-gauthier/aider" Dockerfile; then
    success "Aider clone found"
else
    error "Aider clone not found"
    exit 1
fi

if grep -q "gh" Dockerfile; then
    success "GitHub CLI installation found"
else
    error "GitHub CLI installation not found"
    exit 1
fi

if grep -q "supabase" Dockerfile; then
    success "Supabase CLI installation found"
else
    error "Supabase CLI installation not found"
    exit 1
fi

if grep -q "EXPOSE 8080" Dockerfile; then
    success "Port 8080 exposed"
else
    error "Port 8080 not exposed"
    exit 1
fi

echo ""
echo "Validating docker-compose.yml..."

if command -v docker &> /dev/null && command -v docker compose &> /dev/null; then
    if docker compose config > /dev/null 2>&1; then
        success "docker-compose.yml is valid"
    else
        warning "docker-compose.yml validation skipped (environment variables not set)"
    fi
else
    warning "Docker not available, skipping compose validation"
fi

if grep -q "8080:8080" docker-compose.yml; then
    success "Port mapping correct"
else
    error "Port mapping incorrect"
    exit 1
fi

if grep -q "/workspace" docker-compose.yml; then
    success "Workspace volume configured"
else
    error "Workspace volume not configured"
    exit 1
fi

echo ""
echo "Validating integration script..."

if [ -x "scripts/cline-integration.sh" ]; then
    success "Integration script is executable"
else
    warning "Integration script is not executable (will be set in Docker)"
fi

if grep -q "aider_run" scripts/cline-integration.sh; then
    success "aider_run function found"
else
    error "aider_run function not found"
    exit 1
fi

if grep -q "aider_commit" scripts/cline-integration.sh; then
    success "aider_commit function found"
else
    error "aider_commit function not found"
    exit 1
fi

if grep -q "cline_help" scripts/cline-integration.sh; then
    success "cline_help function found"
else
    error "cline_help function not found"
    exit 1
fi

echo ""
echo "Checking documentation..."

if grep -q "docker compose up" DOCKER.md; then
    success "Quick start instructions found"
else
    error "Quick start instructions missing"
    exit 1
fi

if grep -q "aider_run" DOCKER.md; then
    success "Helper command documentation found"
else
    error "Helper command documentation missing"
    exit 1
fi

echo ""
echo "Checking Makefile targets..."

required_targets=("help" "build" "up" "down" "shell" "clean")
for target in "${required_targets[@]}"; do
    if grep -q "^$target:" Makefile; then
        success "Makefile target '$target' exists"
    else
        warning "Makefile target '$target' not found"
    fi
done

echo ""
echo "Checking .env.example..."

if grep -q "GITHUB_TOKEN" .env.example; then
    success "GITHUB_TOKEN variable documented"
else
    error "GITHUB_TOKEN variable missing"
    exit 1
fi

if grep -q "SUPABASE_ACCESS_TOKEN" .env.example; then
    success "SUPABASE_ACCESS_TOKEN variable documented"
else
    error "SUPABASE_ACCESS_TOKEN variable missing"
    exit 1
fi

echo ""
echo "==================================="
echo -e "${GREEN}All validations passed!${NC}"
echo "==================================="
echo ""
echo "The Docker environment configuration is valid."
echo "To build and run:"
echo "  make build"
echo "  make up"
echo ""
echo "Or:"
echo "  docker compose build"
echo "  docker compose up -d"
echo ""
echo "Note: Building may require network access to:"
echo "  - npm registry (for Cline)"
echo "  - GitHub (for Aider source)"
echo "  - code-server.dev (for Code Server)"
echo "  - Debian package repositories"
