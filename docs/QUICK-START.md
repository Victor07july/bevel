# ⚡ Quick Start - Levantar Rede Fabric

Guia rápido para levantar a rede Hyperledger Fabric quando tudo já está configurado.

## ✅ Pré-requisitos (devem estar prontos)

- Cluster Kubernetes rodando (k3s)
- Flux CD configurado
- Arquivo `build/network-test.yaml` criado a partir do `.example` com GitHub token configurado
- Vault instalado

## 🚀 Comandos para Executar

### 0. Configurar network-test.yaml (primeira vez)

```bash
# Copiar arquivo de exemplo
cd /home/victor/bevel/build
cp network-test.yaml.example network-test.yaml

# Editar e substituir SEU_GITHUB_TOKEN_AQUI pelo token real
nano network-test.yaml  # ou use code/vim
```

> ⚠️ **Importante**: O arquivo `network-test.yaml` está no `.gitignore` para proteger seu token!

### 1. Iniciar o Vault (Terminal 1)

```bash
cd /home/victor/bevel/build
./start-vault-dev.sh
```

> Deixe este terminal aberto. O Vault roda em `http://localhost:8200`

### 2. Ativar Ambiente Python e Executar Deploy (Terminal 2)

```bash
cd /home/victor/bevel
source .venv/bin/activate

ansible-playbook -i inventory.ini \
  platforms/hyperledger-fabric/configuration/deploy-network.yaml \
  --extra-vars "@/home/victor/bevel/build/network-test.yaml" \
  2>&1 | tee /tmp/bevel-deploy-$(date +%H%M%S).log
```

> Tempo estimado: 15-30 minutos

### 3. Monitorar Pods (Terminal 3 - Opcional)

```bash
watch -n 3 'kubectl get pods --all-namespaces | grep -E "NAME|supplychain|org1|org2"'
```

## ✅ Verificar Rede Funcionando

```bash
# Ver todos os pods
kubectl get pods -n supplychain-net
kubectl get pods -n org1-net
kubectl get pods -n org2-net

# Verificar status do Flux
flux get kustomizations
```

Todos os pods devem estar com status `Running` e `READY 1/1` (ou 2/2 para peers).

## 🧹 Limpar Ambiente

```bash
# Deletar namespaces
kubectl delete namespace supplychain-net org1-net org2-net

# Parar Vault (Terminal 1)
# Pressione Ctrl+C

# Remover logs
rm -f /tmp/bevel-deploy-*.log
```

## 🔄 Reexecutar Deploy

### Opção 1: Limpeza Rápida (10-15 min) ⚡ RECOMENDADO

Mantém arquivos YAML gerados, deleta apenas os pods:

```bash
# 1. Deletar apenas namespaces (mantém arquivos gerados)
kubectl delete namespace supplychain-net org1-net org2-net

# 2. Aguardar Flux limpar (30 segundos)
sleep 30

# 3. Reexecutar deploy
cd /home/victor/bevel
source .venv/bin/activate
ansible-playbook -i inventory.ini \
  platforms/hyperledger-fabric/configuration/deploy-network.yaml \
  --extra-vars "@/home/victor/bevel/build/network-test.yaml"
```

> ⏱️ **Tempo**: ~10-15 min (Ansible pula geração de arquivos, mas ainda aguarda 6 min para CAs)

### Opção 2: Limpeza Completa (15-30 min)

Remove tudo e recria do zero:

```bash
# 1. Limpar namespaces
kubectl delete namespace supplychain-net org1-net org2-net

# 2. Limpar arquivos gerados
cd /home/victor/bevel
rm -rf platforms/hyperledger-fabric/releases/dev/supplychain/
rm -rf platforms/hyperledger-fabric/releases/dev/org1/
rm -rf platforms/hyperledger-fabric/releases/dev/org2/
git add . && git commit -m "[ci skip] Clean up" && git push

# 3. Aguardar Flux sincronizar (30 segundos)
sleep 30

# 4. Executar deploy novamente
source .venv/bin/activate
ansible-playbook -i inventory.ini \
  platforms/hyperledger-fabric/configuration/deploy-network.yaml \
  --extra-vars "@/home/victor/bevel/build/network-test.yaml"
```

> ⏱️ **Tempo**: 15-30 min (refaz tudo do zero)

## 📝 Notas Rápidas

- **Vault rodando?** → `curl http://localhost:8200/v1/sys/health`
- **Ver logs do Ansible** → `tail -f /tmp/bevel-deploy-*.log`
- **Flux sincronizado?** → `flux get sources git`
- **Namespaces criados?** → `kubectl get ns | grep -E "supplychain|org1|org2"`

---

Para configuração detalhada, veja [GUIA-EXECUCAO.md](GUIA-EXECUCAO.md)
