# Aider with Ollama

This repository contains scripts to help use [Aider](https://aider.chat/) with local [Ollama](https://ollama.ai/) models for AI-assisted coding.

## Features

- Interactive model selection from installed Ollama models
- Automatic dependency checking
- Proper context window configuration
- Seamless integration with Aider

## Installation

1. First install the prerequisites:
   ```bash
   # Install Ollama
   curl -fsSL https://ollama.ai/install.sh | sh

   # Install Aider and Python dependencies
   python -m pip install aider-install
   aider-install
   ```

2. Make the model picker script executable:
   ```bash
   chmod +x aider_model_picker.sh
   ```

3. (Optional) Add to your PATH for global access:
   ```bash
   sudo cp aider_model_picker.sh /usr/local/bin/aider-pick
   ```

## Usage

### Basic Usage

1. Pull your desired coding model:
   ```bash
   ollama pull codellama:7b-code
   ```

2. Run the model picker:
   ```bash
   ./aider_model_picker.sh
   ```

### Advanced Options

Run with a specific model:
```bash
aider --model ollama_chat/deepseek-coder:6.7b-instruct
```

Increase context window (recommended):
```bash
OLLAMA_CONTEXT_LENGTH=16384 ollama serve & ./aider_model_picker.sh
```

## Recommended Coding Models

| Model | Size | Notes |
|-------|------|-------|
| `codellama:7b-code` | 7B | Good balance of speed and quality |
| `deepseek-coder:6.7b-instruct` | 6.7B | Excellent for Python |
| `mistral:7b-instruct` | 7B | General purpose with good coding skills |
| `llama3:8b-instruct` | 8B | Newer model with strong performance |

## Troubleshooting

- **Model not found**: Ensure you've pulled the model with `ollama pull <name>`
- **Context window too small**: Use `OLLAMA_CONTEXT_LENGTH=16384`
- **Performance issues**: Try smaller models or better hardware

## Documentation

- [Aider Ollama Integration](https://aider.chat/docs/llms/ollama.html)
- [Ollama Model Library](https://ollama.ai/library)
- [Aider Command Reference](https://aider.chat/docs/usage/commands.html)

## Best Practices

1. Start with smaller models (7B) for faster iteration
2. Increase context window for complex projects
3. Use `ollama_chat/` prefix for best results
4. Monitor RAM/GPU usage with `nvidia-smi` or `htop`
