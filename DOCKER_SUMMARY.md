# Docker Environment Setup - Complete Guide

## Overview

This directory contains a complete Docker-based AI development environment that integrates:
- **Aider** - AI pair programming tool (from source)
- **Cline** - AI coding assistant
- **Code Server** - Web-based VS Code
- **Additional Tools** - GitHub CLI, Supabase CLI, Python, Node.js

## Quick Start

```bash
# 1. Initialize environment
make init

# 2. Build the Docker image
make build

# 3. Start the environment
make up

# 4. Access Code Server
# Open http://localhost:8080 in your browser
```

## Files and Their Purpose

### Core Configuration
- **Dockerfile** - Main Docker image definition
- **docker-compose.yml** - Service orchestration
- **.dockerignore** - Build optimization
- **.env.example** - Environment variable template

### Documentation
- **DOCKER.md** - Detailed setup and usage guide
- **DOCKER_WORKFLOWS.md** - Example workflows and use cases
- **README.md** - Main project README (includes Docker section)

### Scripts
- **scripts/cline-integration.sh** - Helper functions for Aline/Cline integration
- **scripts/validate-docker.sh** - Configuration validation script

### Automation
- **Makefile** - Common Docker operations
- **.github/workflows/validate-docker.yml** - CI/CD validation

## Architecture

```
┌─────────────────────────────────────────────┐
│           Docker Container                   │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────┐  ┌──────────────┐       │
│  │ Code Server  │  │    Aider     │       │
│  │  (Port 8080) │  │  (from src)  │       │
│  └──────────────┘  └──────────────┘       │
│                                             │
│  ┌──────────────┐  ┌──────────────┐       │
│  │    Cline     │  │  GitHub CLI  │       │
│  │   (global)   │  │     (gh)     │       │
│  └──────────────┘  └──────────────┘       │
│                                             │
│  ┌──────────────┐  ┌──────────────┐       │
│  │ Supabase CLI │  │   Python     │       │
│  │              │  │   Node.js    │       │
│  └──────────────┘  └──────────────┘       │
│                                             │
│         /workspace (Volume Mount)           │
│              └── aider/ (symlink)          │
│                                             │
└─────────────────────────────────────────────┘
                     │
                     ▼
              Host: ./workspace/
```

## Environment Variables

Configure in `.env` file (copy from `.env.example`):

```bash
GITHUB_TOKEN=ghp_xxxxxxxxxxxxx        # GitHub API access
SUPABASE_ACCESS_TOKEN=sbp_xxxxxxxxxx  # Supabase CLI
CODE_SERVER_AUTH=none                 # Code Server auth mode
```

## Directory Structure

```
/opt/aider/              # Aider source (editable install)
/workspace/              # User workspace (mounted volume)
  └── aider/             # Symlink to /opt/aider
/usr/local/bin/          # Helper scripts
  └── cline-integration.sh
```

## Available Commands

### Make Commands
```bash
make help      # Show all available targets
make build     # Build Docker image
make up        # Start environment
make down      # Stop environment
make restart   # Restart environment
make logs      # View container logs
make shell     # Open shell in container
make clean     # Remove everything
make test      # Run validation tests
make init      # Initialize .env file
```

### Helper Functions (in container)
```bash
cline_help              # Show all helper commands
aider_run [path]        # Run Aider
aider_commit [msg]      # Commit and push
aider_test              # Run tests
aider_update            # Update from upstream
project_init <name>     # Create new project
supabase_start          # Start Supabase local
```

## Use Cases

1. **Developing Aider Features**
   - Modify Aider source at `/workspace/aider`
   - Test changes immediately (editable install)
   - Contribute back to Aider project

2. **AI-Assisted Development**
   - Use Cline for natural language coding
   - Run Aider on your projects
   - Combine both tools for maximum productivity

3. **Full-Stack Development**
   - Code Server for web interface
   - Supabase for backend
   - Aider/Cline for AI assistance

4. **Learning and Experimentation**
   - Safe environment to test Aider
   - Try different AI models
   - Experiment with configurations

## Workflow Examples

See [DOCKER_WORKFLOWS.md](DOCKER_WORKFLOWS.md) for detailed examples:
- Developing Aider features
- Using Cline for AI-assisted development
- Testing with different models
- Contributing to multiple projects
- Local Supabase development
- Debugging Aider issues
- Using with CI/CD

## Integration with Cline

The environment is designed for seamless Cline integration:

```bash
# Cline can execute these commands via natural language:
"Run aider on this project"    → aider_run /workspace/project
"Commit my changes"            → aider_commit "message"
"Update aider from upstream"   → aider_update
"Start supabase"               → supabase_start
```

## Testing the Setup

### Automated Validation
```bash
# Run validation script
./scripts/validate-docker.sh

# Or use make
make test
```

### Manual Testing
```bash
# Build and start
docker compose build
docker compose up -d

# Verify services
docker compose ps
docker compose logs

# Test in container
docker compose exec cline-aider-dev bash
> cline_help
> aider_run --help
> python3 --version
> node --version
```

## Troubleshooting

### Build Issues
**Problem**: Build fails due to network issues
**Solution**: This is common in CI environments. Build locally with proper network access.

**Problem**: Slow build times
**Solution**: Use Docker layer caching. The Dockerfile is optimized for caching.

### Runtime Issues
**Problem**: Code Server not accessible
**Solution**: Check if port 8080 is available: `docker compose ps`

**Problem**: GitHub authentication fails
**Solution**: Set `GITHUB_TOKEN` in `.env` and run `gh auth login` in container

**Problem**: Aider not found
**Solution**: Aider is installed in PATH. Try `python3 /opt/aider/aider/main.py`

### Permission Issues
**Problem**: Cannot write to workspace
**Solution**: Check volume mount permissions in `docker-compose.yml`

## CI/CD Integration

The setup includes GitHub Actions workflow for validation:
- `.github/workflows/validate-docker.yml`

This validates:
- Dockerfile syntax
- docker-compose.yml configuration
- Script syntax
- Documentation completeness

## Performance Optimization

### Build Time
- Uses slim base image (node:20-slim)
- Optimized layer ordering for caching
- Multi-stage builds possible for production

### Runtime
- Volume mounts for persistent data
- No unnecessary services running
- Optimized for development workflow

## Security Considerations

1. **Secrets Management**
   - Use `.env` file (not committed to git)
   - Mount SSH keys as read-only
   - Never commit tokens to repository

2. **Network Security**
   - Code Server authentication configurable
   - Runs on localhost by default
   - No external ports exposed except 8080

3. **Container Isolation**
   - Runs as root in container (standard for dev)
   - Workspace isolated from host
   - Optional network isolation

## Customization

### Adding Tools
Edit `Dockerfile`:
```dockerfile
RUN apt-get install -y your-tool
```

### Adding Helper Functions
Edit `scripts/cline-integration.sh`:
```bash
my_custom_function() {
    # Your code here
}
export -f my_custom_function
```

### Adding Services
Edit `docker-compose.yml`:
```yaml
services:
  my-service:
    image: my-service:latest
    ports:
      - "3000:3000"
```

## Contributing

When contributing Docker-related changes:
1. Update relevant documentation
2. Run validation: `./scripts/validate-docker.sh`
3. Test build locally if possible
4. Update this summary if structure changes

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Aider Documentation](https://aider.chat/)
- [Code Server Documentation](https://coder.com/docs/code-server)
- [Cline Documentation](https://github.com/cline/cline)

## License

Apache 2.0 - See main repository LICENSE file

## Support

For issues related to:
- Docker setup: Check this documentation first
- Aider: Visit [Aider repository](https://github.com/paul-gauthier/aider)
- Cline: Visit [Cline repository](https://github.com/cline/cline)
- Code Server: Visit [Code Server repository](https://github.com/coder/code-server)

---

Last Updated: 2025-10-05
Version: 1.0
