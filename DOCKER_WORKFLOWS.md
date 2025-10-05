# Docker Environment - Example Workflows

This document provides example workflows for using the Docker-based AI development environment.

## Workflow 1: Developing Aider Features

### Scenario
You want to add a new feature to Aider and test it with your projects.

### Steps

1. **Start the environment:**
   ```bash
   make up
   # or: docker compose up -d
   ```

2. **Access Code Server at http://localhost:8080**

3. **Navigate to Aider source:**
   - Open `/workspace/aider` in Code Server
   - This is a symlink to `/opt/aider` where Aider is installed in editable mode

4. **Make your changes:**
   - Edit files in the Aider codebase
   - Changes are immediately active due to `pip install -e`

5. **Test your changes:**
   In the Code Server terminal:
   ```bash
   # Test Aider with your changes
   aider_run /workspace/test-project
   
   # Or run with specific options
   python3 /opt/aider/aider/main.py /workspace/test-project --help
   ```

6. **Run tests:**
   ```bash
   aider_test
   ```

7. **Commit your changes:**
   ```bash
   cd /workspace/aider
   git checkout -b my-feature-branch
   git add .
   git commit -m "Add new feature"
   
   # Add your fork as a remote
   git remote add myfork https://github.com/YOUR_USERNAME/aider.git
   git push myfork my-feature-branch
   ```

## Workflow 2: Using Cline for AI-Assisted Development

### Scenario
You want to use Cline to develop with AI assistance while having Aider available.

### Steps

1. **Start the environment:**
   ```bash
   make up
   ```

2. **Access Code Server at http://localhost:8080**

3. **Create a new project:**
   In the terminal:
   ```bash
   project_init my-ai-app
   cd my-ai-app
   ```

4. **Use Cline with natural language:**
   In the Code Server interface, use Cline to:
   - "Create a Flask web application with user authentication"
   - "Add unit tests for the authentication module"
   - "Run aider on this project to refactor the code"

5. **Run Aider on the project:**
   ```bash
   aider_run /workspace/my-ai-app
   ```

6. **Commit and push:**
   ```bash
   aider_commit "Initial Flask app with authentication"
   ```

## Workflow 3: Testing Aider with Different Models

### Scenario
You want to test how Aider works with different AI models.

### Steps

1. **Set up environment variables:**
   Create a `.env` file with your API keys:
   ```bash
   cp .env.example .env
   # Edit .env to add API keys
   ```

2. **Start the environment:**
   ```bash
   make up
   ```

3. **Test with different models:**
   In the Code Server terminal:
   ```bash
   # Test with GPT-4
   python3 /opt/aider/aider/main.py --model gpt-4 /workspace/test-project
   
   # Test with Claude
   python3 /opt/aider/aider/main.py --model claude-3-opus-20240229 /workspace/test-project
   
   # Test with local Ollama (if configured)
   python3 /opt/aider/aider/main.py --model ollama/codellama /workspace/test-project
   ```

## Workflow 4: Contributing to Multiple Projects

### Scenario
You're working on both Aider and your own projects, switching between them.

### Steps

1. **Start the environment:**
   ```bash
   make up
   ```

2. **Access Code Server at http://localhost:8080**

3. **Set up your projects:**
   ```bash
   # Clone your project
   cd /workspace
   git clone https://github.com/YOUR_USERNAME/your-project.git
   
   # Aider is already available at /workspace/aider
   ```

4. **Work on Aider:**
   ```bash
   cd /workspace/aider
   # Make changes to Aider
   # Test immediately
   ```

5. **Use modified Aider on your project:**
   ```bash
   aider_run /workspace/your-project
   ```

6. **Commit to both repos:**
   ```bash
   # Commit Aider changes
   cd /workspace/aider
   aider_commit "Fix prompt handling"
   
   # Commit your project
   cd /workspace/your-project
   git add .
   git commit -m "Update based on new Aider features"
   git push
   ```

## Workflow 5: Local Supabase Development

### Scenario
You're building a full-stack application with Supabase backend.

### Steps

1. **Start the environment:**
   ```bash
   make up
   ```

2. **Access Code Server at http://localhost:8080**

3. **Initialize Supabase:**
   In the terminal:
   ```bash
   cd /workspace
   project_init my-supabase-app
   cd my-supabase-app
   
   supabase init
   ```

4. **Start Supabase locally:**
   ```bash
   supabase_start
   ```

5. **Use Aider to develop:**
   ```bash
   aider_run /workspace/my-supabase-app
   ```

6. **Use Cline for natural language development:**
   - "Create database migrations for user profiles"
   - "Add API endpoints for user data"
   - "Write tests for the API"

## Workflow 6: Debugging Aider Issues

### Scenario
You encounter a bug in Aider and want to debug it.

### Steps

1. **Start the environment:**
   ```bash
   make up
   ```

2. **Access Code Server at http://localhost:8080**

3. **Add debug logging:**
   Edit Aider source at `/workspace/aider`:
   ```python
   # Add print statements or logging
   import logging
   logging.basicConfig(level=logging.DEBUG)
   ```

4. **Test with verbose output:**
   ```bash
   python3 /opt/aider/aider/main.py --verbose /workspace/test-project
   ```

5. **Check logs:**
   - View terminal output in Code Server
   - Aider logs are displayed in the terminal

6. **Fix the issue:**
   - Edit the Aider source code
   - Test immediately (no reinstall needed)

7. **Contribute the fix:**
   ```bash
   cd /workspace/aider
   git checkout -b fix-issue-123
   aider_commit "Fix issue #123: Describe the fix"
   git push myfork fix-issue-123
   # Create PR on GitHub
   ```

## Workflow 7: Using with CI/CD

### Scenario
You want to use the Docker environment in CI/CD pipelines.

### Example GitHub Actions Workflow

```yaml
name: Test with Aider Docker Environment

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Build Docker environment
        run: docker compose build
      
      - name: Start environment
        run: docker compose up -d
      
      - name: Run tests
        run: |
          docker compose exec -T cline-aider-dev bash -c "
            cd /workspace
            aider_test
          "
      
      - name: Cleanup
        run: docker compose down
```

## Tips for All Workflows

### Performance
- The workspace directory is mounted as a volume, so files persist between restarts
- Aider is installed in editable mode, so code changes are immediate

### Collaboration
- Share your .env.example with team members
- Use consistent workspace structure across team
- Document project-specific setup in workspace README

### Backup
- The workspace directory is on your host machine
- Regular git commits protect your work
- Consider backing up the entire workspace directory

### Customization
- Modify the Dockerfile to add more tools
- Update cline-integration.sh to add custom commands
- Extend docker-compose.yml for additional services

## Common Commands Reference

```bash
# Environment management
make up              # Start environment
make down            # Stop environment
make restart         # Restart environment
make logs            # View logs
make shell           # Open shell in container

# Aider commands
aider_run [path]     # Run Aider on a project
aider_test           # Run Aider tests
aider_update         # Update Aider from upstream
aider_commit [msg]   # Commit and push changes

# Project commands
project_init <name>  # Initialize new project
cline_help           # Show all available commands

# Supabase commands
supabase_start       # Start local Supabase
```

## Getting Help

- Run `cline_help` in the terminal for available commands
- Check `DOCKER.md` for detailed documentation
- Review the Makefile for available make targets
- Visit the main README for general information
