# 🔐 Permissões Necessárias para a Service Account

## 📋 Resumo das Permissões Mínimas

A Service Account precisa das seguintes permissões para executar o workflow:

### ✅ Obrigatórias

| Role | Descrição | Por Que Precisa |
|------|-----------|-----------------|
| `roles/artifactregistry.writer` | Artifact Registry Writer | **ESSENCIAL**: Permite fazer push e pull de imagens Docker no Artifact Registry |

### 🔹 Recomendadas (Opcional)

| Role | Descrição | Por Que Precisa |
|------|-----------|-----------------|
| `roles/storage.objectViewer` | Storage Object Viewer | Permite ler objetos do GCS (backend do Artifact Registry em alguns casos) |

## 🚀 Setup Rápido (Automatizado)

Use o script fornecido para configurar tudo automaticamente:

```bash
./scripts/setup-gcp-sa.sh
```

O script vai:
1. ✅ Criar a Service Account
2. ✅ Atribuir as permissões mínimas necessárias
3. ✅ Gerar a chave JSON
4. ✅ Mostrar instruções para adicionar aos GitHub Secrets

## 🛠️ Setup Manual

Se preferir fazer manualmente:

### 1. Criar Service Account

```bash
export PROJECT_ID="seu-projeto-gcp"
export SA_NAME="n8n-builder"

gcloud iam service-accounts create $SA_NAME \
  --display-name="N8N Docker Builder" \
  --description="Service Account para build e push de imagens N8N" \
  --project=$PROJECT_ID
```

### 2. Atribuir Permissões

```bash
# OBRIGATÓRIO: Artifact Registry Writer
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# OPCIONAL: Storage Object Viewer
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"
```

### 3. Criar Chave JSON

```bash
gcloud iam service-accounts keys create n8n-builder-key.json \
  --iam-account="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project=$PROJECT_ID
```

### 4. Verificar Permissões

```bash
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:${SA_NAME}@*" \
  --format="table(bindings.role)"
```

## 🔍 Detalhamento das Permissões

### `roles/artifactregistry.writer`

**O que inclui:**
- `artifactregistry.repositories.downloadArtifacts` - Pull de imagens
- `artifactregistry.repositories.uploadArtifacts` - **Push de imagens** ⭐
- `artifactregistry.repositories.get` - Ler metadados do repositório
- `artifactregistry.repositories.list` - Listar repositórios
- `artifactregistry.tags.create` - Criar tags de imagem
- `artifactregistry.tags.update` - Atualizar tags
- `artifactregistry.tags.list` - Listar tags

**Por que é essencial:**
- Sem essa role, o `docker push` vai **falhar com erro 403 (Forbidden)**

### `roles/storage.objectViewer`

**O que inclui:**
- `storage.objects.get` - Ler objetos do Storage
- `storage.objects.list` - Listar objetos

**Por que é recomendada:**
- O Artifact Registry pode usar GCS como backend de armazenamento
- Melhora a compatibilidade em alguns casos edge
- É uma role de **leitura apenas** (sem risco)

## 🔐 Adicionar aos GitHub Secrets

Depois de criar a chave JSON:

1. Vá para: `https://github.com/gsconsig/n8n-bypass/settings/secrets/actions`

2. Adicione 2 secrets:

   **Secret 1:**
   ```
   Name: GCP_PROJECT_ID
   Value: seu-projeto-gcp
   ```

   **Secret 2:**
   ```
   Name: GCP_SA_KEY
   Value: (cole TODO o conteúdo de n8n-builder-key.json)
   ```

3. Copiar conteúdo da chave:
   ```bash
   # macOS
   cat n8n-builder-key.json | pbcopy
   
   # Linux
   cat n8n-builder-key.json | xclip -selection clipboard
   
   # Windows (PowerShell)
   Get-Content n8n-builder-key.json | Set-Clipboard
   ```

## ⚠️ Segurança

### ✅ Boas Práticas

- ✅ Use **permissões mínimas** (princípio do menor privilégio)
- ✅ **NÃO** commite a chave JSON no git
- ✅ Adicione `*.json` no `.gitignore` (já está!)
- ✅ Guarde a chave em local seguro (1Password, Vault, etc)
- ✅ Rotacione a chave periodicamente (a cada 90 dias)

### ❌ Evite

- ❌ **NUNCA** use roles com `*` (Owner, Editor)
- ❌ **NUNCA** exponha a chave JSON publicamente
- ❌ **NUNCA** compartilhe a chave por email/chat

### 🗑️ Revogar Acesso (Se Necessário)

Se a chave for comprometida:

```bash
# 1. Listar chaves
gcloud iam service-accounts keys list \
  --iam-account="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# 2. Deletar chave específica
gcloud iam service-accounts keys delete KEY_ID \
  --iam-account="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# 3. Ou deletar toda a Service Account
gcloud iam service-accounts delete \
  "${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project=$PROJECT_ID
```

## 🧪 Testar Permissões

Depois de configurar, teste localmente:

```bash
# 1. Autenticar com a chave
gcloud auth activate-service-account \
  --key-file=n8n-builder-key.json

# 2. Configurar Docker
gcloud auth configure-docker us-central1-docker.pkg.dev

# 3. Testar push de imagem dummy
docker pull hello-world
docker tag hello-world us-central1-docker.pkg.dev/$PROJECT_ID/n8n/test:latest
docker push us-central1-docker.pkg.dev/$PROJECT_ID/n8n/test:latest

# Se funcionou, as permissões estão corretas! ✅
```

## 📊 Comparação de Roles

| Role | Push | Pull | Delete | Admin |
|------|------|------|--------|-------|
| `artifactregistry.reader` | ❌ | ✅ | ❌ | ❌ |
| `artifactregistry.writer` | ✅ | ✅ | ✅ | ❌ |
| `artifactregistry.repoAdmin` | ✅ | ✅ | ✅ | ✅ |

**Para este projeto, use:** `artifactregistry.writer` ⭐

---

**🎯 Resumo:** A Service Account precisa de **apenas 1 role obrigatória** (`artifactregistry.writer`) para funcionar. Simples assim!
