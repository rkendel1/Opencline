# Docker Extension Build Flow

## Build Process Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     User runs: make build                        │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Docker Build Process                          │
├─────────────────────────────────────────────────────────────────┤
│  1. Base Image (node:20-slim)                                   │
│     └── Install system dependencies (Python, git, curl, etc.)   │
│                                                                  │
│  2. Install Code Server                                         │
│     └── curl -fsSL https://code-server.dev/install.sh | sh      │
│                                                                  │
│  3. Install vsce (VS Code Extension Manager)                    │
│     └── npm install -g @vscode/vsce                             │
│                                                                  │
│  4. Install Aider (from source)                                 │
│     └── git clone + pip install -e                              │
│                                                                  │
│  5. Install Supabase CLI                                        │
│                                                                  │
│  6. Copy helper scripts                                         │
│     └── scripts/cline-integration.sh                            │
│                                                                  │
│  7. Copy Opencline repository → /tmp/opencline-build            │
│     └── Excludes: node_modules, dist, .git, workspace           │
│                                                                  │
│  8. Build Cline Extension                                       │
│     ├── npm install --production --ignore-scripts               │
│     ├── npm run build:webview                                   │
│     ├── vsce package --out /tmp/cline.vsix                      │
│     └── code-server --install-extension /tmp/cline.vsix         │
│                                                                  │
│  9. Cleanup                                                      │
│     └── rm -rf /tmp/opencline-build                             │
│                                                                  │
│ 10. Setup environment                                           │
│     └── Configure bashrc, workspace, etc.                       │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│              Docker Image Ready with Extension                   │
│                                                                  │
│  ✓ Code Server installed                                        │
│  ✓ Cline Extension pre-installed                                │
│  ✓ Aider from source                                            │
│  ✓ Helper scripts available                                     │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    User runs: make up                            │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Container Starts                               │
│                                                                  │
│  CMD: code-server --bind-addr 0.0.0.0:8080 --auth none          │
│                                                                  │
│  Port 8080 exposed → http://localhost:8080                      │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│           User opens browser: http://localhost:8080              │
│                                                                  │
│  Code Server with Cline Extension Ready! 🎉                     │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐      │
│  │  Code Server UI                                       │      │
│  │  ┌─────────┬────────────────────────────────────┐    │      │
│  │  │ Cline   │  Editor Area                        │    │      │
│  │  │ (Icon)  │                                     │    │      │
│  │  │         │  /workspace (mounted volume)        │    │      │
│  │  │ Files   │                                     │    │      │
│  │  │         │  Terminal:                          │    │      │
│  │  │ Search  │  $ cline_help                       │    │      │
│  │  │         │  $ aider_run                        │    │      │
│  │  │ Git     │                                     │    │      │
│  │  └─────────┴────────────────────────────────────┘    │      │
│  └──────────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

## File Flow

```
Host Machine                Docker Container
──────────────────────────  ──────────────────────────

./Opencline/                
├── scripts/                
│   ├── package-extension.sh  →  Can be used manually
│   └── cline-integration.sh  →  /usr/local/bin/cline-integration.sh
├── package.json            
├── Dockerfile              →  Build instructions
├── docker-compose.yml      →  Service configuration
├── .dockerignore           →  Excludes from build
└── workspace/              →  /workspace (volume mount)

During Build:
./Opencline/  →  /tmp/opencline-build  →  Package  →  Install  →  Cleanup

Result:
Extension installed at: ~/.local/share/code-server/extensions/
```

## Component Interaction

```
┌───────────────────────────────────────────────────────────────┐
│                        User                                    │
└───────────────┬───────────────────────────────────────────────┘
                │
                │ Browser: http://localhost:8080
                ▼
┌───────────────────────────────────────────────────────────────┐
│                   Code Server (Port 8080)                      │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │              Cline VS Code Extension                     │  │
│  │  (Pre-installed from /tmp/cline.vsix)                   │  │
│  └─────────────────────────────────────────────────────────┘  │
│                         │                                      │
│  ┌──────────────────────┼──────────────────────────────────┐  │
│  │   Terminal           │   File System                     │  │
│  │                      │                                   │  │
│  │  Helper Scripts      │   /workspace (mounted)            │  │
│  │  ├─ cline_help       │   └── User projects               │  │
│  │  ├─ aider_run        │                                   │  │
│  │  └─ project_init     │   /opt/aider (editable)           │  │
│  │                      │   └── Aider source code           │  │
│  └──────────────────────┴───────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
```

## Validation Flow

```
User runs: make validate
         │
         ▼
┌────────────────────────────────────────┐
│  scripts/validate-extension-setup.sh   │
├────────────────────────────────────────┤
│  ✓ Check required files exist          │
│  ✓ Check Dockerfile has vsce           │
│  ✓ Check extension installation code   │
│  ✓ Check package.json scripts          │
│  ✓ Check .dockerignore                 │
│  ✓ Check script permissions            │
│  ✓ Check Makefile targets              │
└────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  All checks passed ✓                   │
│                                         │
│  Next steps:                            │
│  1. make build                          │
│  2. make up                             │
│  3. Access http://localhost:8080        │
└────────────────────────────────────────┘
```

## Error Handling

```
Extension Build Failure
         │
         ▼
┌────────────────────────────────────────┐
│  npm install fails?                    │
│  → Continue with || true               │
│                                         │
│  webview build fails?                  │
│  → Log warning, continue               │
│                                         │
│  vsce package fails?                   │
│  → Log warning, continue               │
│                                         │
│  Extension install fails?              │
│  → Log warning, container still works  │
└────────────────────────────────────────┘
         │
         ▼
Container runs without extension
(Still usable as Code Server)
```

## Documentation Structure

```
DOCKER_*.md Files
│
├── DOCKER_INDEX.md          (Hub - start here)
│   └── Links to all other docs
│
├── DOCKER_QUICK_START.md    (Quick reference)
│   └── Commands, tips, troubleshooting
│
├── DOCKER.md                (Main guide)
│   └── Setup, usage, features
│
├── DOCKER_EXTENSION.md      (Extension details)
│   └── Packaging, installation, customization
│
├── DOCKER_ARCHITECTURE.md   (Technical details)
│   └── System design, components
│
└── DOCKER_WORKFLOWS.md      (Examples)
    └── Real-world usage patterns
```
