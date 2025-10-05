# Docker-based AI development environment for Aider with Cline and Code Server
# This image provides a turnkey environment for modifying and running Aider directly from source

FROM node:20-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    CODE_SERVER_AUTH=none \
    AIDER_PATH=/opt/aider \
    WORKSPACE=/workspace \
    PATH="/opt/aider:${PATH}"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Essential build tools
    build-essential \
    # Version control and utilities
    git \
    curl \
    bash \
    wget \
    ca-certificates \
    # Python 3.11+
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    # GitHub CLI repository setup
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Code Server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install Cline globally
RUN npm install -g cline

# Clone and install Aider from source
RUN git clone https://github.com/paul-gauthier/aider.git ${AIDER_PATH} \
    && cd ${AIDER_PATH} \
    && pip3 install --break-system-packages -e ${AIDER_PATH}[dev]

# Install Supabase CLI
RUN SUPABASE_VERSION=$(curl -s https://api.github.com/repos/supabase/cli/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/') \
    && ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "amd64" ]; then ARCH="linux-amd64"; elif [ "$ARCH" = "arm64" ]; then ARCH="linux-arm64"; fi \
    && curl -LO "https://github.com/supabase/cli/releases/download/v${SUPABASE_VERSION}/supabase_${SUPABASE_VERSION}_${ARCH}.tar.gz" \
    && tar -xzf "supabase_${SUPABASE_VERSION}_${ARCH}.tar.gz" \
    && mv supabase /usr/local/bin/supabase \
    && rm "supabase_${SUPABASE_VERSION}_${ARCH}.tar.gz" \
    && chmod +x /usr/local/bin/supabase

# Optional: Uncomment to install Ollama for local models
# RUN curl -fsSL https://ollama.com/install.sh | sh

# Create workspace directory
RUN mkdir -p ${WORKSPACE}

# Symlink Aider source to workspace for easy editing
RUN ln -s ${AIDER_PATH} ${WORKSPACE}/aider

# Set workspace as working directory
WORKDIR ${WORKSPACE}

# Copy Cline integration helper script
COPY scripts/cline-integration.sh /usr/local/bin/cline-integration.sh
RUN chmod +x /usr/local/bin/cline-integration.sh

# Create bashrc additions for automatic loading
RUN echo "" >> /root/.bashrc && \
    echo "# Cline Integration Helpers" >> /root/.bashrc && \
    echo "source /usr/local/bin/cline-integration.sh" >> /root/.bashrc

# Expose Code Server port
EXPOSE 8080

# Set the default command to start Code Server
CMD ["/bin/bash", "-c", "source /usr/local/bin/cline-integration.sh && code-server --bind-addr 0.0.0.0:8080 --auth none /workspace"]
