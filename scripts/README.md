# Scripts Directory

This directory contains helper scripts for the Opencline project, including Docker integration and extension packaging.

## Docker & Extension Scripts

### package-extension.sh
**Purpose:** Package the Cline VS Code extension as a .vsix file

**Usage:**
```bash
./scripts/package-extension.sh
```

**Output:** `dist/cline.vsix`

**Description:**
- Checks if vsce is installed (installs if needed)
- Creates the dist directory if it doesn't exist
- Packages the extension using vsce
- Outputs helpful information about the generated file

**Use cases:**
- Manual extension packaging for testing
- Creating distribution files
- Local installation testing

---

### validate-extension-setup.sh
**Purpose:** Validate that the Docker extension setup is correctly configured

**Usage:**
```bash
./scripts/validate-extension-setup.sh
# Or via make:
make validate
```

**What it checks:**
- All required files exist (Dockerfile, docker-compose.yml, etc.)
- Dockerfile includes vsce installation
- Dockerfile includes extension installation steps
- package.json has the correct scripts
- .dockerignore is properly configured
- Scripts have executable permissions
- Makefile has required targets

**Success output:**
```
[✓] All validation checks passed!

Your Docker setup is ready. Next steps:
  1. Run 'make init' to create .env file (optional)
  2. Run 'make build' to build the Docker image
  3. Run 'make up' to start the environment
  4. Access Code Server at http://localhost:8080
```

**Use cases:**
- Pre-build validation
- Troubleshooting setup issues
- CI/CD pipeline checks
- Verifying repository state

---

### cline-integration.sh
**Purpose:** Provides helper functions for the Docker environment

**Usage:**
This script is automatically sourced in the Docker container's .bashrc

**Available functions:**
- `cline_help` - Show all available helper commands
- `aider_run [path]` - Run Aider on a project
- `aider_commit [message]` - Commit and push changes
- `aider_edit` - Show info about editing Aider source
- `aider_test` - Run Aider test suite
- `aider_update` - Update Aider from upstream
- `project_init <name>` - Create a new project
- `supabase_start` - Start Supabase local development

**In the container:**
```bash
# Show all commands
cline_help

# Run Aider
aider_run /workspace/my-project

# Commit changes
aider_commit "Fixed bug"

# Create new project
project_init my-app
```

---

## Other Scripts

### validate-docker.sh
Validates Docker configuration and setup (legacy validation)

### build-cli.sh
Builds the CLI components

### publish-nightly.mjs
Publishes nightly builds of the extension to marketplaces

## Script Permissions

All shell scripts should be executable:
```bash
chmod +x scripts/*.sh
```

To verify:
```bash
ls -la scripts/*.sh
```

## Adding New Scripts

When adding new scripts to this directory:

1. **Make it executable:**
   ```bash
   chmod +x scripts/your-script.sh
   ```

2. **Add a header comment:**
   ```bash
   #!/bin/bash
   # Your Script Name
   # Description of what it does
   ```

3. **Update this README:**
   - Add description
   - Add usage examples
   - Add to appropriate section

4. **Consider adding to Makefile:**
   If the script is commonly used, add a make target

## Documentation References

For more information about the Docker setup and extension packaging:

- **DOCKER_QUICK_START.md** - Quick reference for Docker commands
- **DOCKER_EXTENSION.md** - Detailed extension packaging guide
- **TESTING_GUIDE.md** - Testing procedures
- **IMPLEMENTATION_SUMMARY.md** - Technical implementation details

## Support

If you encounter issues with any script:

1. Check the script's help output (if available)
2. Review the relevant documentation
3. Run the validation script: `make validate`
4. Check the logs: `make logs` (for Docker-related issues)
