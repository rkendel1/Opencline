# Quick Reference: Docker Setup with VS Code Extension

## 🚀 Get Started in 3 Steps

```bash
# Step 1: Build the Docker image (includes packaging Cline extension)
make build

# Step 2: Start the environment
make up

# Step 3: Open your browser
# Navigate to: http://localhost:8080
# The Cline extension is already installed! 🎉
```

## 📋 Common Commands

| Command | Description |
|---------|-------------|
| `make build` | Build Docker image with Cline extension |
| `make up` | Start the environment |
| `make down` | Stop the environment |
| `make restart` | Restart the environment |
| `make logs` | View container logs |
| `make shell` | Open shell in container |
| `make clean` | Remove containers and images |
| `make init` | Create .env file from template |

## 🔧 Using Docker Compose Directly

```bash
# Build and start
docker compose up -d

# Stop
docker compose down

# View logs
docker compose logs -f

# Rebuild from scratch
docker compose build --no-cache
```

## 📦 What Gets Installed

✅ **Cline Extension** - Packaged and installed automatically during build  
✅ **Code Server** - Web-based VS Code at http://localhost:8080  
✅ **Aider** - AI pair programming tool (from source)  
✅ **GitHub CLI** - Git operations  
✅ **Supabase CLI** - Backend development  
✅ **Helper Scripts** - Simplified workflows  

## 🎯 Extension Packaging Details

The Cline VS Code extension is built and installed during the Docker build process:

1. **Automatic** (during `make build`):
   - Source code is copied to build context
   - Dependencies are installed
   - Webview UI is built
   - Extension is packaged as `.vsix`
   - Extension is installed in Code Server
   - Build artifacts are cleaned up

2. **Manual** (if needed):
   ```bash
   # Package extension locally
   npm run package:vsix
   
   # Or use the script
   ./scripts/package-extension.sh
   ```

## 📖 Documentation

- **[DOCKER_EXTENSION.md](DOCKER_EXTENSION.md)** - Detailed extension setup
- **[DOCKER.md](DOCKER.md)** - Complete Docker guide
- **[DOCKER_INDEX.md](DOCKER_INDEX.md)** - Documentation index
- **[Makefile](Makefile)** - All available commands

## 🆘 Troubleshooting

### Extension not installed?
```bash
# Check logs
make logs

# Rebuild from scratch
make clean
make build
make up
```

### Build fails?
```bash
# Use no-cache build
docker compose build --no-cache

# Or with make
make clean && make build
```

### Can't access Code Server?
1. Check container is running: `docker compose ps`
2. Check port 8080 is available: `lsof -i :8080`
3. View logs: `make logs`

## 🔐 Environment Setup

```bash
# Create .env file
make init

# Or manually
cp .env.example .env

# Edit .env and add your tokens:
# - GITHUB_TOKEN
# - SUPABASE_ACCESS_TOKEN
```

## ⚡ Quick Tips

- **First time?** Run `make init` then `make build` then `make up`
- **Need help?** Inside container, run `cline_help`
- **Access files?** Use `/workspace` directory (mounted from `./workspace`)
- **Edit Aider?** Source is at `/opt/aider` (also linked at `/workspace/aider`)

## 🎓 Next Steps

1. Access Code Server at http://localhost:8080
2. Open the Cline extension (should be in sidebar)
3. Try the helper commands: `cline_help`
4. Read [DOCKER_WORKFLOWS.md](DOCKER_WORKFLOWS.md) for examples
