#!/usr/bin/env bash
# ============================================
#  INSTALADOR AUTOMÁTICO - MINECRAFT + CRAFTY + PLAYIT
# ============================================

set -e
set -o pipefail

INSTALL_BASE="${HOME}/Minecraft"
CRAFTY_REPO="https://gitlab.com/crafty-controller/crafty-installer-4.0.git"
PLAYIT_URL="https://playit.gg/downloads/playit-linux-amd64"
SERVICE_NAME="crafty"

echo "=== Atualizando pacotes do sistema ==="
sudo apt update -y && sudo apt upgrade -y

echo "=== Instalando dependências ==="
sudo apt install -y git curl wget screen unzip

echo "=== Criando diretório base: ${INSTALL_BASE} ==="
mkdir -p "${INSTALL_BASE}"
cd "${INSTALL_BASE}"

# -------------------------------
# Instalar Crafty Controller
# -------------------------------
echo "=== Baixando e instalando Crafty Controller ==="
git clone "${CRAFTY_REPO}" crafty-installer
cd crafty-installer
sudo ./install_crafty.sh

# -------------------------------
# Instalar Playit.gg
# -------------------------------
echo "=== Instalando Playit.gg (túnel de rede) ==="
cd "${INSTALL_BASE}"
mkdir -p playit && cd playit
wget -O playit "${PLAYIT_URL}"
chmod +x playit

# Cria um serviço systemd para iniciar Playit
sudo tee /etc/systemd/system/playit.service >/dev/null <<EOF
[Unit]
Description=Playit.gg Tunnel
After=network.target

[Service]
ExecStart=${INSTALL_BASE}/playit/playit
WorkingDirectory=${INSTALL_BASE}/playit
Restart=always
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable playit
sudo systemctl start playit

# -------------------------------
# Criar serviço systemd para Crafty Controller
# -------------------------------
echo "=== Criando serviço systemd para o Crafty Controller ==="
sudo tee /etc/systemd/system/${SERVICE_NAME}.service >/dev/null <<EOF
[Unit]
Description=Crafty Controller Minecraft Manager
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=/srv/crafty
ExecStart=/srv/crafty/venv/bin/python3 /srv/crafty/app/main.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME}
sudo systemctl start ${SERVICE_NAME}

# -------------------------------
# Finalização
# -------------------------------
echo "==============================================="
echo "✅ Instalação concluída com sucesso!"
echo "📂 Crafty Controller instalado em: /srv/crafty"
echo "🌍 Painel Web: http://127.0.0.1:8000"
echo "⚙️  Playit.gg já está ativo (use o token no painel Playit)"
echo "📁 Base Minecraft: ${INSTALL_BASE}"
echo "==============================================="
