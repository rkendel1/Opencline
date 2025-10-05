# Docker AI Development Environment

This Docker-based development environment provides a turnkey setup for modifying and running [Aider](https://github.com/paul-gauthier/aider) directly from its source code, integrated with Cline and Code Server.

## Features

- **Aider from Source**: Aider is cloned to `/opt/aider` and installed in development mode, making it easy to modify and test changes
- **Code Server**: Web-based VS Code interface accessible at `http://localhost:8080`
- **Cline**: AI-powered coding assistant installed globally
- **GitHub CLI**: For seamless Git operations and GitHub integration
- **Supabase CLI**: For local Supabase development
- **Python 3.11+**: Required for Aider development
- **Node.js 20**: For Cline and other JavaScript tools

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- (Optional) GitHub token for API access
- (Optional) Supabase access token

### Setup

1. **Clone this repository**:
   ```bash
   git clone <repository-url>
   cd Opencline
   ```

2. **Create environment file** (optional):
   ```bash
   cp .env.example .env
   # Edit .env and add your tokens
   ```

3. **Start the environment**:
   ```bash
   docker compose up -d
   ```

4. **Access Code Server**:
   Open your browser and navigate to `http://localhost:8080`

## Usage

### Cline Integration Helper Commands

The environment includes a comprehensive set of helper commands that are automatically available in the terminal:

```bash
# Show all available commands
cline_help

# Run Aider on a project
aider_run /workspace/my-project

# Commit and push changes
aider_commit "Fixed authentication bug"

# Initialize a new project
project_init my-new-app

# Run Aider tests
aider_test

# Update Aider from upstream
aider_update

# Start Supabase local development
supabase_start
```

### Plain-English Commands via Cline

The environment is configured to support natural language commands through Cline. These map to the helper functions:

- **"Run aider on this repo"** → `aider_run /workspace`
- **"Commit my changes"** → `aider_commit "auto commit"`
- **"Edit aider's source"** → `aider_edit`
- **"Run aider tests"** → `aider_test`
- **"Update aider"** → `aider_update`
- **"Start Supabase local"** → `supabase_start`
- **"Initialize new project"** → `project_init <name>`

### Manual Command Execution

You can also run commands directly in the Code Server terminal:

```bash
# Show available helper commands
cline_help

# Run Aider on the current workspace
aider_run /workspace

# Run Aider with specific options
python3 /opt/aider/aider/main.py /workspace --model gpt-4

# Edit Aider's source code
cd /workspace/aider  # Symlink to /opt/aider
# OR
cd /opt/aider  # Direct path

# Commit changes to Aider fork
cd /workspace/aider
git add .
git commit -m "My changes to Aider"
git push
```

### Helper Functions

The environment includes pre-defined helper functions (see `cline_help` for full list):

- `aider_run [path] [args]` - Run Aider on a project
- `aider_commit [message]` - Commit and push with GitHub authentication
- `aider_edit` - Show info about editing Aider source
- `aider_test [args]` - Run Aider test suite
- `aider_update` - Update Aider from upstream repository
- `project_init <name>` - Create a new project with git initialization
- `supabase_start` - Start Supabase local development

## Directory Structure

```
/workspace          # Your projects and files (mounted from ./workspace)
  └── aider/        # Symlink to /opt/aider for easy editing
/opt/aider          # Aider source code (editable installation)
```

## Modifying Aider

1. **Access Aider source code**:
   - In Code Server, navigate to `/workspace/aider` or `/opt/aider`
   
2. **Make changes**:
   - Edit files directly in Code Server
   - Changes are immediately reflected since Aider is installed with `pip install -e`

3. **Test changes**:
   ```bash
   python3 /opt/aider/aider/main.py --help
   ```

4. **Commit and push to your fork**:
   ```bash
   cd /workspace/aider
   git remote add fork https://github.com/YOUR_USERNAME/aider.git
   git add .
   git commit -m "Description of changes"
   git push fork main
   ```

## Environment Variables

Configure the following environment variables in `.env` or directly in `docker-compose.yml`:

- `GITHUB_TOKEN`: GitHub personal access token for API access and git operations
- `SUPABASE_ACCESS_TOKEN`: Supabase access token for CLI operations
- `CODE_SERVER_AUTH`: Authentication mode for Code Server (default: `none`)

## Optional: Ollama Integration

To use local LLM models with Ollama:

1. Uncomment the Ollama service section in `docker-compose.yml`
2. Uncomment the Ollama installation line in `Dockerfile`
3. Restart the environment:
   ```bash
   docker compose down
   docker compose up -d
   ```

## Accessing the Container

To get a shell in the running container:

```bash
docker compose exec cline-aider-dev bash
```

## Stopping the Environment

```bash
docker compose down
```

To remove all data and start fresh:

```bash
docker compose down -v
rm -rf workspace
```

## Troubleshooting

### Code Server not accessible

- Check if the container is running: `docker compose ps`
- Check logs: `docker compose logs cline-aider-dev`
- Ensure port 8080 is not already in use

### GitHub authentication issues

- Ensure `GITHUB_TOKEN` is set in `.env`
- Run `gh auth status` in the container terminal to verify

### Aider not found

- The Aider executable should be in PATH
- Try running directly: `python3 /opt/aider/aider/main.py`

## Advanced Usage

### Custom Aider Installation

If you want to use a specific Aider branch or fork:

1. Modify the `Dockerfile` to clone from your fork:
   ```dockerfile
   RUN git clone https://github.com/YOUR_USERNAME/aider.git ${AIDER_PATH}
   ```

2. Rebuild the image:
   ```bash
   docker compose build
   ```

### Mounting Additional Volumes

Add additional volume mounts to `docker-compose.yml`:

```yaml
volumes:
  - ./workspace:/workspace
  - ./my-project:/workspace/my-project
```

## Development Workflow Example

1. Start the environment: `docker compose up -d`
2. Open Code Server at `http://localhost:8080`
3. Open Aider source: `/workspace/aider`
4. Make changes to Aider's code
5. Test changes: Run Aider from the terminal
6. Use Cline to: "Run aider tests"
7. Use Cline to: "Commit aider updates to my fork"
8. Use Cline to: "Push to GitHub"

## License

This Docker configuration is part of the Opencline project. See the main repository LICENSE file for details.

## Additional Resources

- [DOCKER_WORKFLOWS.md](DOCKER_WORKFLOWS.md) - Example workflows and use cases
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contributing to Opencline
- [Aider Documentation](https://aider.chat) - Official Aider documentation
