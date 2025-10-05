# Testing Guide for Docker Extension Setup

This guide provides step-by-step testing procedures to verify the VS Code extension packaging and Docker integration works correctly.

## Prerequisites

- Docker and Docker Compose installed
- At least 4GB of free disk space
- Internet connection (for downloading dependencies)

## Quick Validation Test

Before building anything, verify the setup is correct:

```bash
cd /path/to/Opencline
make validate
```

Expected output:
```
================================================
Docker Extension Setup Validation
================================================

Checking required files...
[✓] Found: Dockerfile
[✓] Found: docker-compose.yml
[✓] Found: Makefile
...

================================================
[✓] All validation checks passed!

Your Docker setup is ready. Next steps:
  1. Run 'make init' to create .env file (optional)
  2. Run 'make build' to build the Docker image
  3. Run 'make up' to start the environment
  4. Access Code Server at http://localhost:8080
================================================
```

## Full Build and Test

### Step 1: Build the Docker Image

```bash
make build
```

**What to watch for:**
1. Base image download (node:20-slim)
2. System package installation
3. Code Server installation
4. vsce installation
5. Aider installation
6. Extension build process:
   ```
   Installing dependencies for extension build...
   Building webview...
   Packaging extension...
   ✓ Cline extension installed in Code Server
   ```

**Success indicators:**
- No fatal errors
- Message: "✓ Cline extension installed in Code Server"
- Build completes successfully

**Common warnings (can be ignored):**
- npm peer dependency warnings
- Optional dependency warnings
- Deprecation warnings

**Build time:**
- First build: 10-20 minutes (depends on internet speed)
- Subsequent builds: 2-5 minutes (if using cache)

### Step 2: Start the Environment

```bash
make up
```

**Expected output:**
```
================================
✓ Environment started successfully!
================================

Access Code Server at: http://localhost:8080

The Cline extension is pre-installed and ready to use.

Useful commands:
  make logs    - View container logs
  make shell   - Open a shell in the container
  make down    - Stop the environment
```

**Verify container is running:**
```bash
docker ps | grep cline-aider-dev
```

Expected: One running container on port 8080

### Step 3: Access Code Server

1. Open browser
2. Navigate to: `http://localhost:8080`
3. Code Server should load

**What to verify:**
- Code Server interface loads correctly
- No authentication prompt (default: auth=none)
- File explorer shows `/workspace` directory

### Step 4: Verify Extension Installation

#### Method 1: Visual Verification

In Code Server:
1. Look at the left sidebar (Activity Bar)
2. Find the Cline icon (should be visible)
3. Click on it to open the Cline panel

#### Method 2: Command Line Verification

In Code Server's integrated terminal:
```bash
code-server --list-extensions
```

Expected output should include:
```
saoudrizwan.claude-dev
```

Or search specifically:
```bash
code-server --list-extensions | grep -i cline
```

#### Method 3: Extension Details

In Code Server:
1. Click Extensions icon in sidebar (or Ctrl+Shift+X)
2. Search for "cline" or "claude-dev"
3. Should show as "Installed"
4. Check version number matches package.json

### Step 5: Test Extension Functionality

1. Click the Cline icon in the sidebar
2. Extension panel should open
3. Try basic interactions:
   - Check if UI elements load
   - Try opening settings
   - Verify no console errors (F12 → Console)

### Step 6: Test Helper Scripts

Open the Code Server terminal and test:

```bash
# Show help
cline_help
```

Expected: List of available helper commands

```bash
# Test Aider
aider_run --help
```

Expected: Aider help message

### Step 7: Test File System

In Code Server terminal:

```bash
# Check workspace
ls -la /workspace

# Check Aider source
ls -la /opt/aider

# Check symlink
ls -la /workspace/aider
```

All should show directory contents without errors.

### Step 8: View Logs

Check container logs for any errors:

```bash
make logs
```

Look for:
- ✓ Extension installation success message
- No error stack traces
- Code Server started successfully

### Step 9: Test Persistence

1. Create a test file in `/workspace`:
   ```bash
   echo "test" > /workspace/test.txt
   ```

2. Stop the container:
   ```bash
   make down
   ```

3. Start again:
   ```bash
   make up
   ```

4. Verify file still exists:
   ```bash
   make shell
   cat /workspace/test.txt
   ```

Expected: File persists (volume mount working)

## Troubleshooting Tests

### Test 1: Extension Not Installed

If extension doesn't show up:

```bash
# Check build logs
docker logs cline-aider-dev-env 2>&1 | grep -C 5 "extension"

# Check extension directory
make shell
ls -la ~/.local/share/code-server/extensions/
```

### Test 2: Build Failures

If build fails:

```bash
# Clean everything and rebuild
make clean
docker system prune -a
make build --no-cache
```

### Test 3: Network Issues

If npm install fails during build:

```bash
# Check network in container
docker run --rm node:20-slim ping -c 3 google.com

# Try building with different DNS
docker build --network=host .
```

### Test 4: Permission Issues

If getting permission errors:

```bash
# Check file permissions
ls -la scripts/

# Fix if needed
chmod +x scripts/*.sh
```

## Performance Tests

### Build Performance

Time the build:
```bash
time make build
```

Expected:
- First build: 10-20 minutes
- Cached build: 2-5 minutes

### Container Performance

Check resource usage:
```bash
docker stats cline-aider-dev-env
```

Typical values:
- CPU: 0-5% (idle), up to 50% (active)
- Memory: 500MB-2GB
- Network: minimal when idle

### Extension Load Time

From opening browser to extension ready:
- Expected: 2-5 seconds
- If > 10 seconds, may indicate issues

## Automated Testing Script

Save this as `test-docker-setup.sh`:

```bash
#!/bin/bash
set -e

echo "=== Docker Extension Setup Test ==="

# Test 1: Validation
echo "Test 1: Running validation..."
make validate

# Test 2: Build
echo "Test 2: Building image..."
make build

# Test 3: Start
echo "Test 3: Starting container..."
make up
sleep 10

# Test 4: Check container
echo "Test 4: Checking container..."
docker ps | grep cline-aider-dev || exit 1

# Test 5: Check extension
echo "Test 5: Checking extension..."
docker exec cline-aider-dev-env code-server --list-extensions | grep claude-dev || exit 1

# Test 6: Check helpers
echo "Test 6: Checking helper scripts..."
docker exec cline-aider-dev-env bash -c "cline_help" || exit 1

# Test 7: HTTP check
echo "Test 7: Checking HTTP endpoint..."
curl -s http://localhost:8080 > /dev/null || exit 1

echo "=== All tests passed! ==="
```

Run it:
```bash
chmod +x test-docker-setup.sh
./test-docker-setup.sh
```

## CI/CD Testing

For GitHub Actions or other CI systems:

```yaml
name: Test Docker Setup

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Validate setup
        run: make validate
      
      - name: Build image
        run: make build
      
      - name: Start container
        run: make up
      
      - name: Wait for startup
        run: sleep 30
      
      - name: Check extension
        run: |
          docker exec cline-aider-dev-env \
            code-server --list-extensions | grep claude-dev
      
      - name: Cleanup
        if: always()
        run: make down
```

## Success Criteria

The setup is successful if:

✅ Validation passes  
✅ Build completes without fatal errors  
✅ Container starts and stays running  
✅ Code Server accessible at http://localhost:8080  
✅ Cline extension visible in sidebar  
✅ Extension listed in code-server --list-extensions  
✅ Helper commands work (cline_help)  
✅ File persistence works across restarts  

## Next Steps After Testing

Once all tests pass:

1. **Read the documentation:**
   - DOCKER_QUICK_START.md for commands
   - DOCKER_EXTENSION.md for extension details
   - DOCKER_WORKFLOWS.md for examples

2. **Start using the environment:**
   - Create projects in /workspace
   - Use Cline for AI assistance
   - Edit Aider source if needed

3. **Customize if needed:**
   - Add environment variables in .env
   - Install additional extensions
   - Mount additional volumes

4. **Share with team:**
   - Documentation is comprehensive
   - Quick start guide available
   - All commands documented in Makefile

## Reporting Issues

If tests fail, gather this information:

```bash
# System info
docker --version
docker compose --version
uname -a

# Build logs
docker logs cline-aider-dev-env > logs.txt

# Container status
docker ps -a

# Image info
docker images | grep opencline
```

Then open an issue on GitHub with:
- Test step that failed
- Error messages
- System information
- Log files
