#!/usr/bin/env bash
################################################################################
# Script for installing Ollama on Ubuntu (20.04 / 22.04 / 24.04) and pulling
# a default LLM model so it's ready to use right after install.
#
# Usage:
#   sudo wget -O ollama_install.sh https://your-repo/ollama_install.sh
#   sudo bash ollama_install.sh
#
# Author: (your name here)
################################################################################

#--------------------------------------------------
# CONFIGURATION
#--------------------------------------------------
# The model that will be pulled automatically once Ollama is installed.
# Browse more models at https://ollama.com/library
OLLAMA_DEFAULT_MODEL="llama3.1:8b"

# Set to true if you want Ollama to listen on 0.0.0.0 (reachable from other
# machines on your network/LAN) instead of only localhost.
OLLAMA_EXPOSE_NETWORK=false

# Port Ollama listens on. 11434 is the default used by Ollama itself.
OLLAMA_PORT="11434"

# Set to true to enable + start the ollama systemd service automatically.
ENABLE_SERVICE=true

# Set to true to pull the default model defined above right after install.
PULL_DEFAULT_MODEL=true

#--------------------------------------------------
# COLORS / HELPERS
#--------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

#--------------------------------------------------
# PRE-FLIGHT CHECKS
#--------------------------------------------------
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run with sudo or as root. Try: sudo bash $0"
   exit 1
fi

if ! grep -qi ubuntu /etc/os-release 2>/dev/null; then
    log_warn "This doesn't look like Ubuntu. The script will continue, but it was written for Ubuntu."
fi

echo "================================================================"
echo " Ollama installer"
echo " Default model to pull : ${OLLAMA_DEFAULT_MODEL}"
echo " Expose to network     : ${OLLAMA_EXPOSE_NETWORK}"
echo " Enable systemd service: ${ENABLE_SERVICE}"
echo "================================================================"

#--------------------------------------------------
# STEP 1: Update system & install prerequisites
#--------------------------------------------------
log_info "Updating package lists..."
apt-get update -y

log_info "Installing prerequisites (curl, ca-certificates)..."
apt-get install -y curl ca-certificates

#--------------------------------------------------
# STEP 2: Install Ollama
#--------------------------------------------------
if command -v ollama >/dev/null 2>&1; then
    log_warn "Ollama is already installed ($(ollama --version 2>/dev/null | head -n1)). Skipping install step."
else
    log_info "Downloading and running the official Ollama install script..."
    curl -fsSL https://ollama.com/install.sh | sh

    if ! command -v ollama >/dev/null 2>&1; then
        log_error "Ollama installation seems to have failed. Aborting."
        exit 1
    fi
    log_info "Ollama installed successfully: $(ollama --version 2>/dev/null | head -n1)"
fi

#--------------------------------------------------
# STEP 3: Configure the systemd service (host/port, network exposure)
#--------------------------------------------------
SERVICE_FILE="/etc/systemd/system/ollama.service"

if [[ -f "$SERVICE_FILE" ]]; then
    if [[ "$OLLAMA_EXPOSE_NETWORK" == "true" ]]; then
        log_info "Configuring Ollama to listen on 0.0.0.0:${OLLAMA_PORT} (network-exposed)..."
        OLLAMA_HOST_VALUE="0.0.0.0:${OLLAMA_PORT}"
    else
        log_info "Configuring Ollama to listen on 127.0.0.1:${OLLAMA_PORT} (localhost only)..."
        OLLAMA_HOST_VALUE="127.0.0.1:${OLLAMA_PORT}"
    fi

    mkdir -p /etc/systemd/system/ollama.service.d
    cat > /etc/systemd/system/ollama.service.d/override.conf <<EOF
[Service]
Environment="OLLAMA_HOST=${OLLAMA_HOST_VALUE}"
EOF

    systemctl daemon-reload

    if [[ "$ENABLE_SERVICE" == "true" ]]; then
        log_info "Enabling and starting the ollama service..."
        systemctl enable ollama
        systemctl restart ollama
    fi
else
    log_warn "No systemd service file found at $SERVICE_FILE — skipping service configuration. (Is systemd available on this machine?)"
fi

#--------------------------------------------------
# STEP 4: Wait for the API to come up
#--------------------------------------------------
log_info "Waiting for the Ollama API to become available..."
for i in {1..15}; do
    if curl -fsS "http://127.0.0.1:${OLLAMA_PORT}/api/version" >/dev/null 2>&1; then
        log_info "Ollama API is up."
        break
    fi
    sleep 2
    if [[ $i -eq 15 ]]; then
        log_warn "Ollama API did not respond in time. Continuing anyway — check 'systemctl status ollama'."
    fi
done

#--------------------------------------------------
# STEP 5: Pull the default model
#--------------------------------------------------
if [[ "$PULL_DEFAULT_MODEL" == "true" ]]; then
    log_info "Pulling default model: ${OLLAMA_DEFAULT_MODEL} (this can take a while depending on model size)..."
    if ollama pull "${OLLAMA_DEFAULT_MODEL}"; then
        log_info "Model ${OLLAMA_DEFAULT_MODEL} pulled successfully."
    else
        log_error "Failed to pull ${OLLAMA_DEFAULT_MODEL}. You can retry manually with: ollama pull ${OLLAMA_DEFAULT_MODEL}"
    fi
else
    log_warn "PULL_DEFAULT_MODEL is set to false, skipping model download."
fi

#--------------------------------------------------
# DONE
#--------------------------------------------------
echo "================================================================"
log_info "Installation complete!"
echo " - Check service status : systemctl status ollama"
echo " - Run the model        : ollama run ${OLLAMA_DEFAULT_MODEL}"
echo " - List installed models: ollama list"
echo " - API endpoint         : http://127.0.0.1:${OLLAMA_PORT}"
echo "================================================================"
