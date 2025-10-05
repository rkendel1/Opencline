# Docker Environment Architecture

## System Architecture

```
┌───────────────────────────────────────────────────────────────────┐
│                         Host System                                │
│                                                                    │
│  ┌──────────────┐                                                 │
│  │   Browser    │  http://localhost:8080                          │
│  └──────┬───────┘                                                 │
│         │                                                          │
│         ▼                                                          │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │              Docker Container (cline-aider-dev)             │ │
│  │                                                             │ │
│  │  ┌──────────────────────────────────────────┐             │ │
│  │  │         Code Server (Port 8080)          │             │ │
│  │  │    Web-based VS Code Interface           │             │ │
│  │  └──────────────────────────────────────────┘             │ │
│  │                                                             │ │
│  │  ┌─────────────────┐  ┌─────────────────┐                │ │
│  │  │  Aider (Source) │  │  Cline (Global) │                │ │
│  │  │  /opt/aider     │  │  npm package    │                │ │
│  │  │  pip install -e │  │                 │                │ │
│  │  └─────────────────┘  └─────────────────┘                │ │
│  │                                                             │ │
│  │  ┌─────────────────┐  ┌─────────────────┐                │ │
│  │  │   GitHub CLI    │  │  Supabase CLI   │                │ │
│  │  │     (gh)        │  │                 │                │ │
│  │  └─────────────────┘  └─────────────────┘                │ │
│  │                                                             │ │
│  │  ┌─────────────────────────────────────────┐             │ │
│  │  │     Runtime Environment                 │             │ │
│  │  │  • Python 3.11+  • Node.js 20           │             │ │
│  │  │  • pip           • npm                  │             │ │
│  │  │  • git           • bash                 │             │ │
│  │  └─────────────────────────────────────────┘             │ │
│  │                                                             │ │
│  │  ┌─────────────────────────────────────────┐             │ │
│  │  │     Helper Scripts                       │             │ │
│  │  │  /usr/local/bin/cline-integration.sh    │             │ │
│  │  │  • aider_run     • project_init          │             │ │
│  │  │  • aider_commit  • supabase_start        │             │ │
│  │  │  • aider_test    • cline_help            │             │ │
│  │  └─────────────────────────────────────────┘             │ │
│  │                                                             │ │
│  └─────────────────────────────────────────────────────────────┘ │
│         │                                                        │
│         │ Volume Mount                                          │
│         ▼                                                        │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │           ./workspace/ (Host Directory)                      │ │
│  │                                                             │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │ │
│  │  │  Project 1  │  │  Project 2  │  │    aider    │       │ │
│  │  │             │  │             │  │  (symlink)  │       │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘       │ │
│  │                                                             │ │
│  │  • Persistent storage                                      │ │
│  │  • Survives container restarts                            │ │
│  │  • Editable from host or container                        │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │        Optional Volume Mounts                               │ │
│  │  • ~/.ssh (read-only)      → Container SSH keys            │ │
│  │  • ~/.gitconfig (read-only) → Container git config         │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                    │
└───────────────────────────────────────────────────────────────────┘
```

## Data Flow

### User Workflow
```
User → Browser → Code Server → Terminal → Helper Scripts → Aider/Tools
  ↓                                          ↓                 ↓
  └────────────────────────────────────── /workspace ←────────┘
```

### File System Layout
```
Container:
/
├── opt/
│   └── aider/                  # Aider source (editable install)
│       ├── aider/              # Main package
│       │   ├── main.py         # Entry point
│       │   └── ...
│       └── setup.py
│
├── workspace/                  # User workspace (volume mount)
│   ├── aider → /opt/aider     # Symlink for convenience
│   ├── project-1/
│   ├── project-2/
│   └── ...
│
├── usr/
│   └── local/
│       └── bin/
│           ├── code-server
│           ├── gh
│           ├── supabase
│           └── cline-integration.sh
│
└── root/
    └── .bashrc                # Sources cline-integration.sh

Host:
./workspace/                    # Maps to /workspace in container
├── project-1/
├── project-2/
└── ...
```

## Component Interactions

### Code Server
- **Purpose**: Web-based IDE
- **Access**: http://localhost:8080
- **Features**:
  - File editing
  - Terminal access
  - Extensions support
  - Git integration

### Aider
- **Location**: /opt/aider (source)
- **Installation**: pip install -e (editable)
- **Access**: 
  - Direct: `python3 /opt/aider/aider/main.py`
  - Helper: `aider_run [path]`
- **Modifications**: Edit source, test immediately

### Cline
- **Installation**: npm global
- **Purpose**: AI coding assistant
- **Integration**: Works with Code Server terminal

### Helper Scripts
- **Location**: /usr/local/bin/cline-integration.sh
- **Auto-loaded**: Via .bashrc
- **Functions**: Wrap common operations
- **Benefits**: Simplified workflows

## Network Architecture

```
External Access:
  Port 8080 (HTTP) → Code Server

Internal Services:
  - Code Server: 0.0.0.0:8080
  - No other exposed ports by default

Optional Services:
  - Ollama: 11434 (if enabled)
  - Supabase: Various (when started)
```

## Environment Variables Flow

```
Host .env file
    ↓
docker-compose.yml (reads .env)
    ↓
Container Environment
    ↓
  ┌─────────────────────┐
  │ GITHUB_TOKEN        │ → gh CLI, git operations
  │ SUPABASE_ACCESS_TOKEN│ → supabase CLI
  │ CODE_SERVER_AUTH    │ → Code Server authentication
  └─────────────────────┘
```

## Build Process

```
1. Dockerfile
   ├── FROM node:20-slim
   ├── Install system packages (Python, build tools, etc.)
   ├── Install Code Server (curl script)
   ├── Install Cline (npm global)
   ├── Clone Aider (git clone)
   ├── Install Aider (pip install -e)
   ├── Install GitHub CLI (apt)
   ├── Install Supabase CLI (binary download)
   ├── Create workspace structure
   ├── Copy helper scripts
   └── Configure startup

2. docker-compose.yml
   ├── Build context
   ├── Port mappings
   ├── Volume mounts
   ├── Environment variables
   └── Service configuration

3. Runtime
   ├── Source helper scripts
   ├── Start Code Server
   └── Wait for connections
```

## Security Layers

```
┌────────────────────────────────────┐
│        External Access             │
│  • Browser: localhost:8080         │
│  • Authentication: Configurable    │
└────────────┬───────────────────────┘
             │
┌────────────▼───────────────────────┐
│      Docker Container              │
│  • Isolated environment            │
│  • No network access (by default)  │
│  • Volume mounts: Read-only opts   │
└────────────┬───────────────────────┘
             │
┌────────────▼───────────────────────┐
│      Workspace Data                │
│  • User projects                   │
│  • Git repositories                │
│  • Persistent storage              │
└────────────────────────────────────┘
```

## Development Cycle

```
1. Edit Code
   ├── Code Server interface
   ├── Direct file access
   └── /workspace or /opt/aider

2. Test Changes
   ├── Run Aider: aider_run
   ├── Run tests: aider_test
   └── Manual testing in terminal

3. Commit
   ├── Git operations in container
   ├── Helper: aider_commit
   └── GitHub CLI integration

4. Deploy/Share
   ├── Push to GitHub
   ├── Share workspace changes
   └── Export Docker image (optional)
```

## Extension Points

### Adding New Tools
```
Dockerfile:
RUN apt-get install -y new-tool

Helper Script:
new_tool_function() {
    new-tool "$@"
}
export -f new_tool_function
```

### Adding New Services
```
docker-compose.yml:
services:
  new-service:
    image: service:latest
    ports:
      - "port:port"
    depends_on:
      - cline-aider-dev
```

### Custom Configurations
```
Volume Mounts:
  - ./my-config:/root/.config/tool

Environment Variables:
  - NEW_VAR=value
```

## Performance Considerations

### Build Optimization
- **Layer Caching**: Steps ordered for maximum reuse
- **Slim Base**: Minimal base image
- **Multi-stage**: Optional for production

### Runtime Optimization
- **Volume Mounts**: No file copying overhead
- **Shared Resources**: Docker layer sharing
- **Lazy Loading**: Tools loaded on demand

### Resource Usage
- **Memory**: ~2GB minimum recommended
- **CPU**: 2+ cores recommended
- **Disk**: ~5GB for image + workspace
- **Network**: Required for initial build

## Monitoring and Debugging

### Log Access
```
docker compose logs -f           # All logs
docker compose logs cline-aider-dev  # Service logs
docker compose exec cline-aider-dev bash  # Shell access
```

### Health Checks
```
docker compose ps               # Service status
curl http://localhost:8080      # Code Server health
docker compose exec cline-aider-dev aider_run --version  # Aider check
```

### Troubleshooting Flow
```
1. Check service status
   ↓
2. Review logs
   ↓
3. Test in container shell
   ↓
4. Verify volumes/env vars
   ↓
5. Rebuild if needed
```
