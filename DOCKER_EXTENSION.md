# Docker Setup Guide for VS Code Extension

This guide explains how the Opencline VS Code extension is packaged and installed in the Code Server Docker environment.

## Overview

The Docker environment now includes:
- **Code Server**: Web-based VS Code instance
- **Cline Extension**: Pre-installed and ready to use
- **Aider**: AI pair programming tool (editable from source)
- **Helper Scripts**: Simplified workflows

## Quick Start

```bash
# 1. Build the Docker image (includes extension packaging)
make build

# 2. Start the environment
make up

# 3. Access Code Server
# Open http://localhost:8080 in your browser
# The Cline extension is already installed!
```

## How It Works

### Extension Packaging Process

1. **During Docker Build**:
   - The Dockerfile copies the entire Opencline repository
   - Runs `npm install --production --ignore-scripts` to get dependencies
   - Builds the webview UI with `npm run build:webview`
   - Packages the extension using `vsce package`
   - Installs the packaged extension into Code Server
   - Cleans up build artifacts

2. **Result**:
   - The Cline extension is installed globally in Code Server
   - Available immediately when you access http://localhost:8080
   - No manual installation needed

### Manual Packaging (Optional)

If you want to package the extension manually:

```bash
# Using npm script
npm run package:vsix

# Or using the helper script
./scripts/package-extension.sh

# The VSIX file will be created at: dist/cline.vsix
```

## Docker Commands Reference

### Essential Commands

```bash
make help      # Show all available commands
make build     # Build Docker image with extension
make up        # Start the environment
make down      # Stop the environment
make restart   # Restart the environment
make logs      # View container logs
make shell     # Open shell in container
make clean     # Remove everything
```

### Docker Compose Commands

You can also use `docker compose` directly:

```bash
# Start (simple)
docker compose up -d

# Stop
docker compose down

# View logs
docker compose logs -f

# Rebuild
docker compose build --no-cache
```

## Architecture

### Build Process

```
Dockerfile Build Steps:
├── Install base system (Node.js, Python, etc.)
├── Install Code Server
├── Install vsce (VS Code Extension Manager)
├── Install Aider from source
├── Copy Opencline repository
├── Build webview UI
├── Package extension as .vsix
├── Install extension in Code Server
├── Copy helper scripts
└── Set up environment
```

### File Locations

- **Extension VSIX**: `/tmp/cline.vsix` (during build)
- **Installed Extension**: `~/.local/share/code-server/extensions/`
- **Workspace**: `/workspace` (mounted volume)
- **Aider Source**: `/opt/aider`
- **Helper Scripts**: `/usr/local/bin/cline-integration.sh`

## Customization

### Modifying the Extension

To modify and rebuild the extension:

1. Edit the source code on your host machine
2. Rebuild the Docker image:
   ```bash
   make build
   ```
3. Restart the environment:
   ```bash
   make restart
   ```

### Adding More Extensions

To install additional VS Code extensions, modify the Dockerfile:

```dockerfile
# Install additional extensions
RUN code-server --install-extension <extension-id>
```

## Troubleshooting

### Extension Not Showing Up

1. Check if the extension was installed:
   ```bash
   make shell
   code-server --list-extensions
   ```

2. Check Code Server logs:
   ```bash
   make logs
   ```

3. Rebuild from scratch:
   ```bash
   make clean
   make build
   make up
   ```

### Build Failures

If the build fails during extension packaging:

1. Check network connectivity (required for npm install)
2. Ensure you have enough disk space
3. Try building without cache:
   ```bash
   docker compose build --no-cache
   ```

### Performance Issues

If the build is slow:

1. The `.dockerignore` file excludes unnecessary files
2. Use Docker BuildKit for faster builds:
   ```bash
   DOCKER_BUILDKIT=1 docker compose build
   ```

## Environment Variables

Set these in `.env` file (copy from `.env.example`):

```bash
# GitHub token for API access
GITHUB_TOKEN=your_token_here

# Supabase access token
SUPABASE_ACCESS_TOKEN=your_token_here

# Code Server authentication (default: none)
CODE_SERVER_AUTH=none
```

## Integration with CI/CD

The extension packaging is automated in the Docker build process, making it suitable for CI/CD pipelines:

```bash
# In your CI/CD pipeline
docker compose build
docker compose up -d
# Run tests against Code Server
docker compose down
```

## Advanced Usage

### Using the Helper Functions

Once inside the container (`make shell`), you have access to helper functions:

```bash
# Show help
cline_help

# Run Aider
aider_run /workspace/my-project

# Commit and push changes
aider_commit "My commit message"

# Initialize a new project
project_init my-new-project
```

### Accessing Code Server Remotely

To access Code Server from another machine:

1. Update docker-compose.yml ports section:
   ```yaml
   ports:
     - "0.0.0.0:8080:8080"  # Listen on all interfaces
   ```

2. Set up authentication:
   ```yaml
   environment:
     - CODE_SERVER_AUTH=password
     - PASSWORD=your_secure_password
   ```

## Resources

- **DOCKER.md**: Quick start guide
- **DOCKER_INDEX.md**: Navigation hub
- **DOCKER_ARCHITECTURE.md**: Detailed architecture
- **DOCKER_WORKFLOWS.md**: Common workflows
- **Makefile**: All available make commands

## Support

For issues or questions:
1. Check the logs: `make logs`
2. Review the documentation files
3. Open an issue on GitHub
