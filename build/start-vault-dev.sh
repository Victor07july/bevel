#!/bin/bash
# Script para iniciar HashiCorp Vault em modo dev
# Modo dev: NÃO usar em produção! Apenas para testes.

echo "🔐 Iniciando HashiCorp Vault em modo dev..."
echo "⚠️  ATENÇÃO: Este modo é APENAS para desenvolvimento/testes!"
echo ""
echo "Vault será iniciado em: http://localhost:8200"
echo "Root Token: root"
echo ""
echo "Para parar o Vault, pressione Ctrl+C"
echo "================================================"
echo ""

vault server -dev -dev-root-token-id=root -dev-listen-address=0.0.0.0:8200
