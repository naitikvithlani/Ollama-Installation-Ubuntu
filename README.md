# Ollama-Installation-Ubuntu
Ollama Installation Script for Ubuntu

A simple bash script to install [Ollama](https://ollama.com) on Ubuntu (20.04 / 22.04 / 24.04) and automatically pull a default LLM model, so it's ready to use right after installation.

## Usage

Download the script:
```bash
sudo wget https://raw.githubusercontent.com/naitikvithlani/Ollama-Installation-Ubuntu/main/ollama_install.sh
```

Run it:
```bash
sudo bash ollama_install.sh
```

That's it — Ollama will be installed, the systemd service will be enabled and started, and the default model will be pulled automatically.

## Configuration

There are a few things you can configure at the top of the script before running it:

- `OLLAMA_DEFAULT_MODEL` — the model pulled automatically once Ollama is installed. Defaults to `llama3.1:8b`. Browse more models at [ollama.com/library](https://ollama.com/library).
- `OLLAMA_EXPOSE_NETWORK` — set to `true` if you want Ollama reachable from other machines on your network, or `false` (default) to keep it on localhost only.
- `OLLAMA_PORT` — the port Ollama listens on. Defaults to `11434`.
- `ENABLE_SERVICE` — set to `true` (default) to enable and start the `ollama` systemd service automatically.
- `PULL_DEFAULT_MODEL` — set to `true` (default) to pull `OLLAMA_DEFAULT_MODEL` right after install, or `false` to skip.

## Requirements

- Ubuntu 20.04, 22.04, or 24.04 (other Debian-based distros may work but aren't officially tested)
- Root or sudo access
- A reasonable amount of RAM/disk — model size requirements vary; check the model's page on [ollama.com/library](https://ollama.com/library) before pulling large models

## ⚠️ Security note

If you set `OLLAMA_EXPOSE_NETWORK` to `true`, keep in mind Ollama's API has **no built-in authentication**. Anyone who can reach the configured host/port can query your model. If you expose it beyond localhost, put it behind a firewall (e.g. `ufw`) or a reverse proxy with authentication.

## Disclaimer

As with any install script, please review it before running it with `sudo` on your system.
