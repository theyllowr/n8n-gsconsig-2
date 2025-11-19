# 🚀 N8N Custom Build com License Bypass

Repositório automatizado para build do n8n com bypass de licença enterprise, publicando imagens customizadas no **Google Artifact Registry**.

## 📋 O Que Este Projeto Faz

Este projeto utiliza GitHub Actions para:

1. ✅ **Clonar** sempre a versão mais recente do n8n oficial
2. 🩹 **Aplicar patches** automáticos para bypass de licença enterprise
3. 🐳 **Buildar** imagem Docker customizada (linux/amd64)
4. 📦 **Publicar** automaticamente no **Google Artifact Registry**

> **Nota**: Build otimizado apenas para **linux/amd64** (arquitetura mais comum em servidores)

## 🎯 Funcionalidades Desbloqueadas

Após aplicar os patches, todas as funcionalidades enterprise ficam disponíveis:

### ✅ Autenticação Avançada
- LDAP Integration
- SAML SSO
- OpenID Connect (OIDC)
- Multi-Factor Authentication (MFA)

### ✅ Gestão de Workflows
- Workflow History (versionamento completo)
- Source Control (integração Git)
- Folders (organização hierárquica)
- Workflow Diffs (comparação visual)

### ✅ Inteligência Artificial
- AI Assistant
- Ask AI
- AI Credits (ilimitados)
- AI Builder

### ✅ Permissões & Segurança
- Advanced Permissions
- Custom Roles
- API Key Scopes
- External Secrets Manager

### ✅ Infraestrutura Enterprise
- S3 Binary Data Storage
- Multiple Main Instances (HA)
- Worker View
- Log Streaming

### ✅ Quotas Ilimitadas
- Workflows ativos: **ilimitado**
- Variáveis globais: **ilimitado**
- Usuários: **ilimitado**
- Projetos: **ilimitado**
- Créditos AI: **ilimitado**

## 🔧 Configuração Inicial

### 1. Secrets do GitHub

Configure os seguintes secrets no repositório:

```bash
GCP_PROJECT_ID      # ID do seu projeto GCP
GCP_SA_KEY          # JSON da Service Account com permissões no GCR
```

> **Arquitetura**: As imagens são buildadas apenas para **linux/amd64** (compatível com a maioria dos servidores x86_64)

#### Como obter o GCP_SA_KEY:

**Opção 1: Automatizado (Recomendado)**
```bash
# Execute o script de setup
./scripts/setup-gcp-sa.sh
```

**Opção 2: Manual**
```bash
# 1. Criar service account no GCP
gcloud iam service-accounts create n8n-builder \
  --display-name="N8N Builder"

# 2. Dar permissões necessárias (MÍNIMO: artifactregistry.writer)
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:n8n-builder@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# 3. Criar chave JSON
gcloud iam service-accounts keys create n8n-builder-key.json \
  --iam-account=n8n-builder@YOUR_PROJECT_ID.iam.gserviceaccount.com

# 4. Copiar o conteúdo completo para o secret GCP_SA_KEY
cat n8n-builder-key.json | pbcopy  # macOS
```

📖 **Detalhes completos sobre permissões:** Veja [`docs/GCP-PERMISSIONS.md`](docs/GCP-PERMISSIONS.md)

### 2. Criar Artifact Registry no GCP

**Opção 1: Via Interface (Recomendado se você está criando manualmente)**

1. Console GCP → **Artifact Registry** → **Create Repository**
2. Configurações:
   - **Name**: `n8n`
   - **Format**: `Docker`
   - **Location type**: `Region`
   - **Region**: `us-central1` (ou `southamerica-east1` para São Paulo)
3. Click **Create**

📖 **Guia detalhado com prints**: Veja [`docs/ARTIFACT-REGISTRY-SETUP.md`](docs/ARTIFACT-REGISTRY-SETUP.md)

**Opção 2: Via CLI**

```bash
gcloud artifacts repositories create n8n \
  --repository-format=docker \
  --location=us-central1 \
  --description="N8N custom builds"
```

> ⚠️ **IMPORTANTE**: Anote a região e nome do repositório para configurar no workflow!

### 3. Ajustar Configurações do Workflow

Edite `.github/workflows/build-and-push.yml` conforme sua configuração:

```yaml
env:
  ARTIFACT_REGISTRY_REGION: us-central1  # Região onde criou o repositório
  ARTIFACT_REGISTRY_REPO: n8n            # Nome do repositório criado
  IMAGE_NAME: n8n-custom                 # Nome da imagem final
```

> 💡 **Dica**: Se você criou o repositório com nome diferente de `n8n`, ajuste `ARTIFACT_REGISTRY_REPO`

## 🚀 Como Usar

### Build Automático (Push)

Toda vez que você fizer push na branch `main`, o workflow é executado automaticamente:

```bash
git add .
git commit -m "Update configuration"
git push origin main
```

### Build Manual (Workflow Dispatch)

Você pode executar o build manualmente via GitHub Actions UI ou CLI:

#### Via GitHub UI:
1. Vá em **Actions** → **Build and Push n8n Custom to GCR**
2. Clique em **Run workflow**
3. (Opcional) Especifique uma versão do n8n: `1.65.2` ou deixe em branco para `latest`

#### Via GitHub CLI:
```bash
# Build da versão latest
gh workflow run build-and-push.yml

# Build de versão específica
gh workflow run build-and-push.yml -f n8n_version=1.65.2
```

## 📦 Usando a Imagem

Após o build, a imagem estará disponível no Artifact Registry:

### Pull Manual

```bash
# Pull da imagem
docker pull us-central1-docker.pkg.dev/YOUR_PROJECT_ID/n8n/n8n-custom:latest

# Ou versão específica
docker pull us-central1-docker.pkg.dev/YOUR_PROJECT_ID/n8n/n8n-custom:n8n@1.65.2

# Executar localmente (simples)
docker run -d \
  --name n8n-custom \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  us-central1-docker.pkg.dev/YOUR_PROJECT_ID/n8n/n8n-custom:latest
```

### Docker Compose (Recomendado)

Use o arquivo `docker-compose.example.yml` como base:

```bash
# 1. Copiar exemplo
cp docker-compose.example.yml docker-compose.yml

# 2. Editar e ajustar:
#    - YOUR_PROJECT_ID
#    - Senhas
#    - Domínio/webhook URL
nano docker-compose.yml

# 3. Executar
docker-compose up -d

# 4. Ver logs
docker-compose logs -f n8n

# 5. Acessar: http://localhost:5678
```

O docker-compose inclui:
- ✅ PostgreSQL (banco recomendado)
- ✅ Volumes persistentes
- ✅ Health checks
- ✅ Resource limits
- ✅ (Opcional) Traefik para SSL automático

### Deploy no Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: n8n-custom
spec:
  replicas: 1
  selector:
    matchLabels:
      app: n8n
  template:
    metadata:
      labels:
        app: n8n
    spec:
      containers:
      - name: n8n
        image: us-central1-docker.pkg.dev/YOUR_PROJECT_ID/n8n/n8n-custom:latest
        ports:
        - containerPort: 5678
        env:
        - name: N8N_BASIC_AUTH_ACTIVE
          value: "true"
        - name: N8N_BASIC_AUTH_USER
          value: "admin"
        - name: N8N_BASIC_AUTH_PASSWORD
          valueFrom:
            secretKeyRef:
              name: n8n-secrets
              key: password
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "2000m"
```

## 🔍 Detalhes Técnicos

### Arquitetura

- **Plataforma**: `linux/amd64` (x86_64)
- **Base Image**: n8n oficial com patches aplicados
- **Build Tool**: Docker Buildx
- **Registry**: Google Artifact Registry

### Patches Aplicados

O workflow aplica os seguintes patches automaticamente:

#### 1. **License.ts** (`packages/cli/src/license.ts`)
- Método `isLicensed()` retorna sempre `true` (bypass global)
- Método `getValue()` retorna `-1` para quotas (ilimitado)

#### 2. **License-state.ts** (`packages/@n8n/backend-common/src/license-state.ts`)
- Método `isLicensed()` retorna sempre `true` (bypass adicional)

### Estrutura do Projeto

```
n8n-bypass/
├── .github/
│   └── workflows/
│       └── build-and-push.yml    # GitHub Actions workflow
├── scripts/
│   └── apply-patches.sh          # Script de aplicação de patches (para testes locais)
├── README.md                     # Este arquivo
└── PATCHES.md                    # Documentação técnica completa dos patches
```

## 🧪 Testando Localmente

Para testar o processo de patch localmente antes de commitar:

```bash
# 1. Clonar n8n
git clone https://github.com/n8n-io/n8n.git /tmp/n8n

# 2. Aplicar patches
./scripts/apply-patches.sh

# 3. Verificar modificações
cd /tmp/n8n
git diff packages/cli/src/license.ts
git diff packages/@n8n/backend-common/src/license-state.ts

# 4. Build local
pnpm install
pnpm build

# 5. Executar
pnpm start
```

## 📊 Monitoramento

O workflow gera um resumo completo após cada build:

- ✅ Versão do n8n buildada
- ✅ Tags da imagem criadas
- ✅ Patches aplicados
- ✅ Comando para pull da imagem

Acesse em: **Actions** → selecione o workflow run → **Summary**

## 🔄 Atualizações

### Atualizar para Nova Versão do n8n

O workflow sempre pega a versão mais recente do n8n por padrão. Para forçar um rebuild:

```bash
# Trigger manual via workflow dispatch
gh workflow run build-and-push.yml

# Ou fazer um push vazio
git commit --allow-empty -m "Trigger rebuild"
git push
```

### Modificar os Patches

Se precisar ajustar os patches aplicados:

1. Edite `.github/workflows/build-and-push.yml`
2. Localize o step **"Apply license bypass patches"**
3. Modifique os comandos `sed`/`awk` conforme necessário
4. Commit e push

## ⚠️ Avisos Importantes

### Uso Responsável
- ⚠️ Este projeto é para **uso educacional e pessoal**
- ⚠️ Respeite os termos de licença do n8n em ambientes comerciais
- ⚠️ Considere adquirir licença enterprise para uso em produção

### Segurança
- 🔒 **NUNCA** commite secrets ou credenciais
- 🔒 Use GitHub Secrets para informações sensíveis
- 🔒 Revise permissões da Service Account do GCP

### Custos
- 💰 Imagens no GCR geram custos de armazenamento
- 💰 Considere implementar política de retenção de imagens antigas
- 💰 Monitor o uso de recursos no GCP

### Exemplo de Política de Limpeza:

```bash
# Deletar imagens antigas (manter apenas últimas 5)
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/YOUR_PROJECT_ID/n8n/n8n-custom \
  --sort-by=~UPDATE_TIME \
  --format="get(version)" \
  | tail -n +6 \
  | while read version; do
      gcloud artifacts docker images delete \
        "us-central1-docker.pkg.dev/YOUR_PROJECT_ID/n8n/n8n-custom:$version" \
        --quiet
    done
```

## 🐛 Troubleshooting

### Build Falha

**Sintoma**: Workflow falha no step de build

**Solução**:
```bash
# Verificar logs do workflow no GitHub Actions
# Testar patches localmente com o script apply-patches.sh
./scripts/apply-patches.sh
```

### Imagem Não Aparece no GCR

**Sintoma**: Build completa mas imagem não está no registry

**Solução**:
```bash
# Verificar permissões da service account
gcloud projects get-iam-policy YOUR_PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:n8n-builder@*"

# Verificar se o repositório existe
gcloud artifacts repositories describe n8n --location=us-central1
```

### Features Não Aparecem Após Deploy

**Sintoma**: Deploy funciona mas features enterprise não estão disponíveis

**Solução**:
1. Verificar se a imagem correta foi deployada
2. Limpar cache do browser
3. Verificar logs do container n8n
4. Confirmar que os patches foram aplicados:

```bash
# Executar dentro do container
docker exec -it n8n-custom bash
grep -A 3 "BYPASS GLOBAL" /usr/local/lib/node_modules/n8n/dist/license.js
```

## 📚 Referências

- [N8N Official Repository](https://github.com/n8n-io/n8n)
- [Google Artifact Registry Documentation](https://cloud.google.com/artifact-registry/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 📄 Licença

Este projeto é fornecido "como está" para fins educacionais. 

⚠️ **O n8n é um software comercial com licença enterprise proprietária. Use este projeto de forma responsável e ética.**

---

**Criado para**: GSConsig  
**Data**: 2025-01-19  
**Última Atualização**: 2025-01-19
