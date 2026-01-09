# ⚡ Quick Start - Levantar Rede Fabric

Guia rápido para levantar a rede Hyperledger Fabric quando tudo já está configurado.

## ✅ Pré-requisitos (devem estar prontos)

- Cluster Kubernetes rodando (k3s)
- Flux CD configurado
- Arquivo `build/network-test.yaml` com GitHub token atualizado
- Vault instalado

## 🚀 Comandos para Executar

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

Se o deploy falhar, limpe o ambiente primeiro:

```bash
# 1. Limpar namespaces
kubectl delete namespace supplychain-net org1-net org2-net

# 2. Limpar arquivos gerados (opcional)
cd /home/victor/bevel
rm -rf platforms/hyperledger-fabric/releases/dev/supplychain/
rm -rf platforms/hyperledger-fabric/releases/dev/org1/
rm -rf platforms/hyperledger-fabric/releases/dev/org2/
git add . && git commit -m "[ci skip] Clean up" && git push

# 3. Aguardar Flux sincronizar (30 segundos)
sleep 30

# 4. Executar deploy novamente
cd /home/victor/bevel
source .venv/bin/activate
ansible-playbook -i inventory.ini \
  platforms/hyperledger-fabric/configuration/deploy-network.yaml \
  --extra-vars "@/home/victor/bevel/build/network-test.yaml"
```

## 📝 Notas Rápidas

- **Vault rodando?** → `curl http://localhost:8200/v1/sys/health`
- **Ver logs do Ansible** → `tail -f /tmp/bevel-deploy-*.log`
- **Flux sincronizado?** → `flux get sources git`
- **Namespaces criados?** → `kubectl get ns | grep -E "supplychain|org1|org2"`

---

Para configuração detalhada, veja [GUIA-EXECUCAO.md](GUIA-EXECUCAO.md)
