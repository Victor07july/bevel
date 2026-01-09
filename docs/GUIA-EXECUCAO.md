# 🚀 Guia para Levantar Rede de Teste Hyperledger Fabric com Bevel

Este guia vai ajudá-lo a levantar uma rede de teste do Hyperledger Fabric usando Ansible + Flux CD (GitOps).

## ✅ Status dos Pré-requisitos

- ✅ kubectl instalado (v1.34.3)
- ✅ Helm instalado (v3.18.4)
- ✅ Ansible instalado
- ✅ Flux CD instalado (v2.7.5)
- ✅ Cluster Kubernetes disponível (k3s)
- ✅ HashiCorp Vault configurado (dev mode)

## 📋 Passos para Execução

### 1. Ativar o Ambiente Virtual Python (se ainda não estiver ativo)

```bash
cd /home/victor/bevel
source .venv/bin/activate
```

### 2. Configurar Flux CD para GitOps

O Bevel usa GitOps via Flux CD. Você precisa configurar um fork do repositório Bevel no GitHub:

```bash
cd /home/victor/bevel

# Bootstrap do Flux no cluster (substituir com suas credenciais)
flux bootstrap github \
  --owner=<seu-usuario-github> \
  --repository=bevel \
  --branch=main \
  --path=platforms/hyperledger-fabric/releases/dev \
  --personal \
  --token-auth
```

Quando solicitado, forneça seu GitHub Personal Access Token.

### 3. Criar kustomization.yaml para Flux

Crie o arquivo que define os recursos Kubernetes:

```bash
cat > platforms/hyperledger-fabric/releases/dev/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - supplychain/namespace.yaml
  - org1/namespace.yaml
  - org2/namespace.yaml
EOF
```

Commit e push:

```bash
git add platforms/hyperledger-fabric/releases/dev/kustomization.yaml
git commit -m "Add kustomization for Flux"
git push
```

### 4. Instalar e Iniciar o Vault em Modo Dev

Abra um **novo terminal** e execute:

```bash
cd /home/victor/bevel/build
./start-vault-dev.sh
```

**Deixe este terminal aberto!** O Vault ficará rodando em `http://localhost:8200` com root token `root`.

### 5. Configurar network-test.yaml

Edite o arquivo de configuração da rede:

```yaml
# Seção docker - IMPORTANTE: Para imagens públicas, não precisa de credenciais!
docker:
  url: "ghcr.io/hyperledger"
  # NÃO adicione username/password para imagens públicas

# Seção gitops - Use suas credenciais do GitHub
gitops:
  git_protocol: "https"
  git_url: "https://github.com/<seu-usuario>/bevel.git"
  branch: "main"
  release_dir: "platforms/hyperledger-fabric/releases/dev"
  chart_source: "platforms/hyperledger-fabric/charts"
  username: "<seu-usuario-github>"
  password: "<seu-token-github>"
  email: "<seu-email@exemplo.com>"
  private_key: ""
```

**IMPORTANTE**: 
- Para imagens Docker públicas (como ghcr.io/hyperledger), **não adicione credenciais**
- O 7. Executar o Playbook Ansible

No terminal principal (dentro do ambiente virtual):

```bash
cd /home/victor/bevel

# Ativar ambiente virtual
source .venv/bin/activate

# Executar o deployment do Fabric com log
ansible-playbook -i inventory.ini \
  platforms/hyperledger-fabric/configuration/deploy-network.yaml \
  --extra-vars "@/home/victor/bevel/build/network-test.yaml" \
  2>&1 | tee /tmp/bevel-deploy-$(date +%H%M%S).log
```

Este processo pode levar de **15-30 minutos** dependendo da velocidade do seu cluster.

**O que acontece durante o deployment:**
1. **Criação de Namespaces** (~1 min) - Cria namespaces Kubernetes para cada organização
2. **Deploy de CAs** (~5 min) - Cria Certificate Authorities e aguarda 6 minutos para certificados serem válidos
3. **Deploy de Orderers** (~5 min) - Cria os nós orderer com RAFT consensus
4. **Deploy de Peers** (~5 min) - Cria os nós peer e CouchDB para cada organização
5. **Criação de Canal** (~2 min) - Cria e configura o canal testchannel
6. **Anchor Peers** (~2 min) - Configura anchor peers para descoberta de serviços
```bash
cd /home/victor/bevel

# Ativar ambiente virtual
source .venv/bin/activate
8. Monitorar o Progresso

Em outro terminal, você pode monitorar os pods sendo criados:

```bash
# Ver pods do Fabric especificamente
watch -n 3 'kubectl get pods --all-namespaces | grep -E "NAME|supplychain|org1|org2"'

# Verificar sincronização do Flux
flux get kustomizations

# Ver logs do Ansible
tail -f /tmp/bevel-deploy-*.log
```

**Verificações úteis:**
```bash
# Status dos namespaces
kubectl get namespaces | grep -E "supplychain|org1|org2"

# Verificar secrets do Vault
kubectl get secrets -n supplychain-net | grep vault

# Ver eventos em tempo real
kubectl get events -n org1-net --watch

Em outro terminal, você pode monitorar os pods sendo criados:

```bash
# Ver todos os pods
kubectl get pods --all-namespaces -w

# Ver pods do Fabric especificamente
watch kubectl get pods -A | grep -E "supplychain|org1|org2"
```

## 🔍 O Que Será Criado

A rede terá:
- **1 Organização Orderer** (supplychain) com:
  - 1 CA (Certificate Authority)
  - 1 Orderer node (RAFT consensus)
  
- **2 Organizações Peer** (org1 e org2), cada uma com:
  - 1 CA
  - 1 Peer node
  - 1 CouchDB (state database)
  - 1 CLI pod (para comandos fabric)
  
- **1 Canal**: testchannel

## 📦 Namespaces Kubernetes

Os componentes serão criados nos seguintes namespaces:
- `supplychain-net` - Orderer
- `org1-net` - Peer Org1
- `org2-net` - Peer Org2

## 🧪 Verificar a Instalação

Após a conclusão:

```bash
# Verificar pods
kubectl get pods -n supplychain-net
kubectl get pods -n org1-net
kubectl get pods -n org2-net
"Failed to create Docker secret" - Invalid JSON
**Problema**: Erro ao criar secret com credenciais Docker vazias  
**Solução**: Remova as linhas `username` e `password` da seção `docker` no network-test.yaml. Mantenha apenas `url`.

### Vault Connection Error
- Verifique se o Vault está rodando: `curl http://localhost:8200/v1/sys/health`
- Verifique se o token está correto no network-test.yaml (deve ser `root` em dev mode)

### Flux "no such file" Error
**Problema**: `kustomization.yaml` referencia arquivos inexistentes  
**Solução**: Certifique-se que os arquivos referenciados existem (ex: `namespace.yaml` não `supplychain-net.yaml`)

### Git Push Conflicts com Flux Bootstrap
**Problema**: Push rejeita por commits do Flux  
**Solução**: 
```bash
git pull --rebase=false
# ou
git reset --hard origin/main
```

### Pods em CrashLoopBackOff
- Verifique logs: `kubectl logs -n <namespace> <pod-name>`
- Verifique recursos do cluster: `kubectl top nodes`
- Verifique se CA está rodando antes de tentar criar peers

### Ansible "shared/configuration/roles" Missing
**Problema**: Arquivos aparecem como deleted no git  
**Solução**: `git checkout platforms/shared/`
kubectl delete namespace supplychain-net org1-net org2-net
```

## 🐛 Troubleshooting

### Vault Connection Error
- Verifique se o Vault está rodando: `curl http://localhost:8200/v1/sys/health`
- Verifique se o token está correto no network-test.yaml

### Pods em CrashLoopBackOff
- Verifique logs: `kubectl logs -n <namespace> <pod-name>`
- Verifique recursos do cluster: `kubectl top nodes`

### GitOps Errors
- Para testes, você pode desabilitar GitOps editando os roles do Ansible

## 🧹 Limpando o Ambiente

Para remover completamente a rede Fabric e liberar recursos:

### 1. Deletar os Namespaces Kubernetes

```bash
# Remove todos os namespaces da rede Fabric
kubectl delete namespace supplychain-net org1-net org2-net
```

Isso remove automaticamente:
- Todos os pods (CAs, orderers, peers, couchdb)
- Todos os services
- Todos os secrets e configmaps
- Todos os PVCs (Persistent Volume Claims)

### 2. Remover Kustomizations do Flux (Opcional)

```bash
# Remove a kustomization do Flux
flux delete kustomization flux-system --silent

# Ou para manter o Flux mas remover apenas os recursos da rede
flux suspend kustomization flux-system
```

### 3. Parar o Vault

```bash
# Parar o processo do Vault em dev mode
pkill -f "vault server"

# Ou se você iniciou em um terminal separado, pressione Ctrl+C
```

### 4. Limpar Arquivos Temporários

```bash
# Remover logs de deployment
rm -f /tmp/bevel-deploy-*.log

# Limpar token do Vault (se necessário)
rm -f ~/.vault-token
```

### 5. Limpar Arquivos Gerados pelo Ansible (Opcional)

Se você quiser remover os arquivos YAML gerados e fazer um deploy limpo:

```bash
cd /home/victor/bevel

# Remove os arquivos gerados nas pastas de releases
git clean -fd platforms/hyperledger-fabric/releases/dev/

# Ou manualmente
rm -rf platforms/hyperledger-fabric/releases/dev/supplychain/
rm -rf platforms/hyperledger-fabric/releases/dev/org1/
rm -rf platforms/hyperledger-fabric/releases/dev/org2/
```

### 6. Fazer Commit das Remoções (se usar GitOps)

```bash
cd /home/victor/bevel
git add platforms/hyperledger-fabric/releases/dev/
git commit -m "[ci skip] Clean up test deployment"
git push
```

**Nota**: O Flux detectará a remoção dos arquivos e automaticamente removerá os recursos correspondentes do cluster.

### Limpeza Completa (Reset Total)

Para voltar ao estado inicial completo:

```bash
# 1. Deletar namespaces
kubectl delete namespace supplychain-net org1-net org2-net

# 2. Remover Flux
flux uninstall --silent

# 3. Parar Vault
pkill -f "vault server"

# 4. Resetar repositório Git
cd /home/victor/bevel
git reset --hard HEAD
git clean -fd

# 5. Remover logs
rm -f /tmp/bevel-deploy-*.log
```

## 📚 Próximos Passos

Após a rede estar funcionando:
1. Instalar chaincode
2. Invocar transações
3. Consultar o ledger
4. Adicionar mais organizações

## 🔗 Recursos Úteis

- [Documentação Bevel](https://hyperledger-bevel.readthedocs.io/)
- [Fabric Documentation](https://hyperledger-fabric.readthedocs.io/)
- [Troubleshooting Guide](https://hyperledger-bevel.readthedocs.io/en/latest/references/troubleshooting.html)
