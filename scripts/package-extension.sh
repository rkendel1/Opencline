#!/bin/bash
# Package VS Code Extension Script
# This script packages the Cline VS Code extension as a .vsix file for installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function to print colored output
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Output directory for the VSIX file
DIST_DIR="${PROJECT_ROOT}/dist"
VSIX_FILE="${DIST_DIR}/cline.vsix"

log_info "Packaging Cline VS Code extension..."
log_info "Project root: ${PROJECT_ROOT}"

# Ensure we're in the project root
cd "${PROJECT_ROOT}"

# Check if vsce is available
if ! command -v vsce &> /dev/null; then
    log_error "vsce (VS Code Extension Manager) is not installed"
    log_info "Installing vsce globally..."
    npm install -g @vscode/vsce
fi

# Ensure dist directory exists
mkdir -p "${DIST_DIR}"

# Package the extension
log_info "Running: vsce package --out ${VSIX_FILE}"
vsce package --out "${VSIX_FILE}"

if [ -f "${VSIX_FILE}" ]; then
    log_info "✓ Extension packaged successfully!"
    log_info "VSIX file location: ${VSIX_FILE}"
    log_info "File size: $(du -h "${VSIX_FILE}" | cut -f1)"
else
    log_error "Failed to create VSIX file"
    exit 1
fi

# Optional: List the file details
ls -lh "${VSIX_FILE}"

log_info "Package complete! You can install this extension with:"
log_info "  code-server --install-extension ${VSIX_FILE}"
log_info "  or"
log_info "  code --install-extension ${VSIX_FILE}"
