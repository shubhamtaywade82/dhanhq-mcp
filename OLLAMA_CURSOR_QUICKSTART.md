# Quick Start: Ollama + Cursor (Docker Setup)

## Your Current Setup ✅

- **Ollama Container**: Running on `localhost:11434`
- **Ollama Router**: Running on `localhost:8080` (OpenAI-compatible API)
- **Available Models**: `nemesis-coder`, `nemesis-options-analyst`, `llama3.1:8b`, etc.

## Option 1: Use OpenAI-Compatible Router (Easiest)

Your `ollama-router` already provides an OpenAI-compatible API.

### Configure in Cursor:

1. **Open Cursor Settings** → **AI** (or **Features** → **AI Config**)
2. Set these values:
   - **API Base URL**: `http://localhost:8080/v1`
   - **API Key**: (leave empty or use `ollama`)
   - **Model**: Choose from your models (e.g., `nemesis-coder`)

### Test It:

```bash
# Verify router is working
curl http://localhost:8080/v1/models | python3 -m json.tool
```

This should work immediately for Cursor's chat interface.

## Option 2: Add Ollama MCP Server (For Composer Tools)

This enables MCP tools in Cursor's Composer Agent.

### Install Node.js MCP Server:

```bash
# Install the Ollama MCP server
npm install -g @modelcontextprotocol/server-ollama

# Or if that doesn't exist, try:
npm install -g ollama-mcp-server
```

### Configure in Cursor:

1. **Open Cursor Settings** → **Features** → **MCP**
2. Click **"+ Add New MCP Server"**
3. Configure:
   - **Name**: `ollama`
   - **Type**: `stdio`
   - **Command**: 
     ```bash
     npx @modelcontextprotocol/server-ollama --ollama-url http://localhost:11434
     ```
     Or if using a different package:
     ```bash
     ollama-mcp-server --host localhost --port 11434
     ```

### Available MCP Tools:

Once connected, Composer will have access to:
- `list_models` - List all Ollama models
- `show_model` - Get model information
- `ask_model` - Query a model

## Option 3: Python MCP Server

If you prefer Python:

```bash
# Install Python MCP server
pip3 install ollama-mcp-bridge

# Then configure in Cursor with command:
python3 -m ollama_mcp_bridge --ollama-url http://localhost:11434
```

## Quick Verification

### Test Ollama Directly:
```bash
curl http://localhost:11434/api/tags | python3 -m json.tool | head -30
```

### Test Router:
```bash
curl http://localhost:8080/v1/models | python3 -m json.tool
```

### Test Router Chat:
```bash
curl -X POST http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nemesis-coder",
    "messages": [{"role": "user", "content": "Hello"}],
    "stream": false
  }' | python3 -m json.tool
```

## Recommended Setup

**For best experience, use both:**

1. **Router (Option 1)** - For regular chat in Cursor
2. **MCP Server (Option 2 or 3)** - For Composer Agent with tools

## Troubleshooting

### Router not responding?
```bash
docker logs ollama-router
docker restart ollama-router
```

### Ollama not accessible?
```bash
docker ps | grep ollama
docker logs ollama-server
```

### MCP not connecting?
- Check the command path in Cursor settings
- Verify the package is installed globally (`npm list -g` or `pip3 list`)
- Check Cursor's MCP logs in developer console

## Your Models

You have these models ready to use:
- `nemesis-coder` - For coding tasks
- `nemesis-options-analyst` - For options analysis
- `llama3.1:8b` - General purpose
- `mistral:7b-instruct` - Instruction following
- `codellama:7b-instruct` - Code generation
- `qwen2.5-coder:7b` - Code completion
- And more...

Choose the model that best fits your task!
