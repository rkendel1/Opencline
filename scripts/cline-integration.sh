#!/bin/bash
# Cline Integration Script for Docker Environment
# This script provides helper commands that can be invoked through Cline

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

# Function: Run Aider on the workspace
# Usage: aider_run [path] [additional_args...]
aider_run() {
    local target_path="${1:-/workspace}"
    shift
    log_info "Running Aider on: $target_path"
    python3 /opt/aider/aider/main.py "$target_path" "$@"
}

# Function: Commit and push changes
# Usage: aider_commit [message]
aider_commit() {
    local message="${1:-auto commit from Docker environment}"
    
    log_info "Checking GitHub authentication..."
    if ! gh auth status >/dev/null 2>&1; then
        log_error "GitHub authentication failed. Please run 'gh auth login' first."
        return 1
    fi
    
    log_info "Adding all changes..."
    git add .
    
    log_info "Committing with message: $message"
    git commit -m "$message"
    
    log_info "Pushing to remote..."
    git push
    
    log_info "Changes committed and pushed successfully!"
}

# Function: Edit Aider source code
# Usage: aider_edit
aider_edit() {
    log_info "Opening Aider source code in workspace..."
    log_info "Aider source is available at:"
    log_info "  - /opt/aider (original location)"
    log_info "  - /workspace/aider (symlink for easy access)"
    echo ""
    echo "You can edit Aider's code and test changes immediately."
    echo "Changes are live due to 'pip install -e' installation."
}

# Function: Run Aider tests
# Usage: aider_test [test_args...]
aider_test() {
    log_info "Running Aider tests..."
    cd /opt/aider
    if [ -f "pytest.ini" ] || [ -f "setup.py" ]; then
        python3 -m pytest "$@"
    else
        log_warn "Test framework not found. Installing pytest..."
        pip3 install --break-system-packages pytest
        python3 -m pytest "$@"
    fi
}

# Function: Update Aider from remote
# Usage: aider_update
aider_update() {
    log_info "Updating Aider from remote repository..."
    cd /opt/aider
    git pull
    pip3 install --break-system-packages -e /opt/aider[dev]
    log_info "Aider updated successfully!"
}

# Function: Start Supabase local development
# Usage: supabase_start
supabase_start() {
    log_info "Starting Supabase local development environment..."
    if [ ! -f "supabase/config.toml" ]; then
        log_warn "Supabase not initialized in current directory."
        log_info "Run 'supabase init' first to set up Supabase."
    else
        supabase start
    fi
}

# Function: Initialize a new project with Aider
# Usage: project_init <project_name>
project_init() {
    local project_name="$1"
    
    if [ -z "$project_name" ]; then
        log_error "Please provide a project name: project_init <name>"
        return 1
    fi
    
    local project_dir="/workspace/$project_name"
    
    if [ -d "$project_dir" ]; then
        log_error "Project directory already exists: $project_dir"
        return 1
    fi
    
    log_info "Creating new project: $project_name"
    mkdir -p "$project_dir"
    cd "$project_dir"
    
    git init
    log_info "Initialized git repository in $project_dir"
    
    echo "# $project_name" > README.md
    echo "" >> README.md
    echo "This project was initialized in the Cline+Aider Docker environment." >> README.md
    
    log_info "Project created successfully at: $project_dir"
    log_info "You can now run Aider on this project:"
    log_info "  aider_run $project_dir"
}

# Function: Show available commands
# Usage: cline_help
cline_help() {
    echo "Cline Integration Helper Commands"
    echo "=================================="
    echo ""
    echo "Aider Commands:"
    echo "  aider_run [path] [args]    - Run Aider on a project (default: /workspace)"
    echo "  aider_commit [message]     - Commit and push changes with GitHub"
    echo "  aider_edit                 - Information about editing Aider source"
    echo "  aider_test [args]          - Run Aider test suite"
    echo "  aider_update               - Update Aider from upstream"
    echo ""
    echo "Project Commands:"
    echo "  project_init <name>        - Initialize a new project with git"
    echo ""
    echo "Infrastructure Commands:"
    echo "  supabase_start             - Start Supabase local development"
    echo ""
    echo "General:"
    echo "  cline_help                 - Show this help message"
    echo ""
    echo "Examples:"
    echo "  aider_run /workspace/my-project"
    echo "  aider_commit 'Fixed authentication bug'"
    echo "  project_init my-new-app"
}

# Export functions so they're available in shell
export -f aider_run
export -f aider_commit
export -f aider_edit
export -f aider_test
export -f aider_update
export -f supabase_start
export -f project_init
export -f cline_help

# Show welcome message when script is sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Script is being executed, not sourced
    log_warn "This script should be sourced, not executed."
    log_info "Add 'source /usr/local/bin/cline-integration.sh' to your shell config."
else
    # Script is being sourced
    log_info "Cline integration helpers loaded!"
    log_info "Type 'cline_help' to see available commands."
fi
