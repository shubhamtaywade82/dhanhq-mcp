# Setting Up Ollama with Cursor (Docker Edition)

This guide will help you configure Ollama running in Docker to work with Cursor IDE.

## Current Setup

Your Ollama is running in Docker:
- **Container**: `ollama-server` (ID: 149cb3619109)
- **Image**: `ollama/ollama:latest`
- **Port**: `11434` (mapped to `0.0.0.0:11434->11434/tcp`)
- **Router**: `ollama-router` on port `8080` (OpenAI-compatible API)

## Available Models

Based on your setup, you have these models available:
- `nemesis-coder:latest`
- `nemesis-options-analyst:latest`
- `llama3.1:8b`
- `mistral:7b-instruct`
- `codellama:7b-instruct`
- `qwen2.5-coder:7b`
- `deepseek-coder:6.7b`
- And more...

## Configuration Options

### Option A: Using Ollama MCP Server (Recommended for Composer)

This allows Cursor's Composer Agent to use Ollama models with MCP tools.

#### Step 1: Install Ollama MCP Server

```bash
# Install the MCP client for Ollama
pip3 install mcp-client-for-ollama

# Or install ollama-mcp-server if available
# pip3 install ollama-mcp-server
```

#### Step 2: Configure in Cursor

1. Open **Cursor Settings** → **Features** → **MCP**
2. Click **"+ Add New MCP Server"**
3. Configure:
   - **Name**: `ollama` (or any nickname)
   - **Type**: `stdio`
   - **Command**: 
     ```bash
     mcp-ollama --ollama-url http://localhost:11434
     ```
     Or if using a different package:
     ```bash
     python3 -m ollama_mcp --host localhost --port 11434
     ```

#### Step 3: Verify Connection

- Check Cursor's MCP logs for "Found X tools" message
- Available tools should include:
  - `list_models` - List all Ollama models
  - `show_model` - Get model details
  - `ask_model` - Query a model

### Option B: Using OpenAI-Compatible Router (For AI Chat)

Your `ollama-router` on port 8080 provides an OpenAI-compatible API.

#### Step 1: Verify Router is Working

```bash
# List available models
curl http://localhost:8080/v1/models

# Test chat completion
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nemesis-coder",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

#### Step 2: Configure Cursor AI Settings

1. Open **Cursor Settings** → **AI** (or **Features** → **AI Config**)
2. Set:
   - **API Base URL**: `http://localhost:8080/v1`
   - **API Key**: (leave empty or use any placeholder)
   - **Model**: Select from available models (e.g., `nemesis-coder`, `llama3.1:8b`)

#### Step 3: Test in Cursor Chat

Ask a question in Cursor's chat and verify it uses your local Ollama model.

### Option C: Direct Docker Connection

If you want to connect directly to the Ollama container:

```bash
# Access Ollama CLI inside container
docker exec -it ollama-server ollama list

# Pull a new model
docker exec -it ollama-server ollama pull <model-name>

# Test API
curl http://localhost:11434/api/tags
```

## Recommended Configuration

For best results, use **both**:
- **MCP Server** (Option A) - For Composer Agent with tools
- **OpenAI Router** (Option B) - For regular chat interface

## Troubleshooting

### Ollama Container Issues

```bash
# Check container status
docker ps | grep ollama

# View container logs
docker logs ollama-server

# Restart if needed
docker restart ollama-server
```

### Router Issues

```bash
# Check router health
curl http://localhost:8080/healthz

# View router logs
docker logs ollama-router
```

### Cursor Connection Issues

- **MCP not connecting**: Check the command path and ensure Python packages are installed
- **Models not appearing**: Verify Ollama is accessible at `http://localhost:11434`
- **Router not working**: Ensure `ollama-router` container is running on port 8080
- **Check Cursor logs**: Look for MCP connection errors in Cursor's developer console

## Quick Test Commands

```bash
# Test Ollama directly
curl http://localhost:11434/api/tags

# Test router models endpoint
curl http://localhost:8080/v1/models

# Test router chat endpoint
curl -X POST http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nemesis-coder",
    "messages": [{"role": "user", "content": "Write hello world in Ruby"}],
    "stream": false
  }'
```
