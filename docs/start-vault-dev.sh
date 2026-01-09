#!/bin/bash
##############################################################################################
# Script para iniciar Vault em modo dev para testes do Bevel
##############################################################################################

echo "🔐 Iniciando HashiCorp Vault em modo dev..."
echo ""
echo "ATENÇÃO: Este é um servidor Vault em modo DESENVOLVIMENTO"
echo "NÃO USE EM PRODUÇÃO!"
echo ""

# Verificar se vault está instalado
if ! command -v vault &> /dev/null; then
    echo "❌ Vault não está instalado!"
    echo ""
    echo "Para instalar no Ubuntu/Debian:"
    echo "  wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg"
    echo "  echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com \$(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list"
    echo "  sudo apt update && sudo apt install vault"
    echo ""
    exit 1
fi

# Iniciar Vault em modo dev
echo "📦 Iniciando Vault server em modo dev..."
echo "   URL: http://127.0.0.1:8200"
echo "   Root Token: root"
echo ""
echo "Para parar: Ctrl+C"
echo ""

vault server -dev -dev-root-token-id="root" -dev-listen-address="0.0.0.0:8200"
