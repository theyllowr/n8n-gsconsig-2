# 🔐 Como Adicionar Secrets no GitHub

## 📍 Passo a Passo

### 1. Acessar o Repositório

Vá para: `https://github.com/gsconsig/n8n-bypass`

### 2. Abrir Configurações de Secrets

**Caminho completo:**
```
Settings → Secrets and variables → Actions → New repository secret
```

**Passo-a-passo visual:**
1. Click em **"Settings"** (aba no topo do repo)
2. No menu lateral esquerdo, procure **"Secrets and variables"**
3. Click em **"Actions"**
4. Click no botão verde **"New repository secret"**

### 3. Adicionar o Primeiro Secret (GCP_PROJECT_ID)

1. Click em **"New repository secret"**
2. Preencha:
   - **Name**: `GCP_PROJECT_ID`
   - **Secret**: `seu-projeto-gcp-id` (exemplo: `gsconsig-prod-123456`)
3. Click em **"Add secret"**

### 4. Adicionar o Segundo Secret (GCP_SA_KEY)

1. Click em **"New repository secret"** novamente
2. Preencha:
   - **Name**: `GCP_SA_KEY`
   - **Secret**: Cole **TODO** o conteúdo do arquivo JSON

**Como copiar o JSON:**

**macOS:**
```bash
cat n8n-builder-key.json | pbcopy
```

**Linux:**
```bash
cat n8n-builder-key.json | xclip -selection clipboard
```

**Windows (PowerShell):**
```powershell
Get-Content n8n-builder-key.json | Set-Clipboard
```

**Ou manualmente:**
```bash
cat n8n-builder-key.json
# Copiar todo o output (incluindo as chaves { })
```

3. Click em **"Add secret"**

### 5. Verificar

Após adicionar os 2 secrets, você deve ver na lista:

```
Repository secrets
├── GCP_PROJECT_ID        Updated now by você
└── GCP_SA_KEY           Updated now by você
```

## 📋 Checklist Final

Antes de executar o workflow, confirme:

- ✅ Secret `GCP_PROJECT_ID` adicionado
- ✅ Secret `GCP_SA_KEY` adicionado (JSON completo)
- ✅ Artifact Registry criado no GCP
- ✅ Service Account tem role `artifactregistry.writer`
- ✅ Workflow ajustado com região/repo corretos

## 🚀 Executar o Workflow

Após adicionar os secrets:

**Opção 1: Via Push**
```bash
git add .
git commit -m "Setup complete"
git push origin main
```

**Opção 2: Manualmente**
1. Vá em **Actions**
2. Selecione **"Build and Push n8n Custom to Artifact Registry"**
3. Click **"Run workflow"**
4. Escolha branch: `main`
5. Click **"Run workflow"**

## ⚠️ Importante

### O JSON deve estar COMPLETO

O conteúdo deve ser algo assim:
```json
{
  "type": "service_account",
  "project_id": "seu-projeto",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n",
  "client_email": "n8n-builder@seu-projeto.iam.gserviceaccount.com",
  "client_id": "123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

### Não funciona se:
- ❌ Faltou copiar alguma parte do JSON
- ❌ Copiou só uma parte (precisa copiar TUDO)
- ❌ JSON está inválido/corrompido
- ❌ Nome do secret está errado (tem que ser exatamente `GCP_SA_KEY`)

## 🔍 Verificar se Funcionou

Após executar o workflow:

1. Vá em **Actions**
2. Click no workflow em execução
3. Acompanhe os steps:
   - ✅ Authenticate to Google Cloud (se passar aqui, o JSON está correto!)
   - ✅ Build Docker image
   - ✅ Push to Artifact Registry

Se o step **"Authenticate to Google Cloud"** falhar:
- ❌ JSON está incompleto/inválido
- ❌ Service Account não existe
- ❌ Project ID está errado

## 📸 Screenshots Resumidos

```
GitHub Repo
  └─ Settings
      └─ Secrets and variables
          └─ Actions
              └─ New repository secret
                  ├─ Name: GCP_PROJECT_ID
                  └─ Secret: seu-projeto-id

              └─ New repository secret
                  ├─ Name: GCP_SA_KEY
                  └─ Secret: { todo o JSON }
```

## 🆘 Problemas Comuns

### "Secret not found"
**Causa**: Nome do secret está diferente no workflow

**Solução**: Confirme que usou exatamente:
- `GCP_PROJECT_ID`
- `GCP_SA_KEY`

### "Invalid credentials"
**Causa**: JSON incompleto ou inválido

**Solução**: 
1. Deletar o secret
2. Recriar copiando o JSON completo novamente
3. Verificar que não tem espaços/quebras extras

### "Permission denied"
**Causa**: Service Account não tem a role necessária

**Solução**:
```bash
gcloud projects add-iam-policy-binding SEU_PROJECT_ID \
  --member="serviceAccount:n8n-builder@SEU_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"
```

---

**Link direto** (substitua `gsconsig` e `n8n-bypass` pelo seu repo):
```
https://github.com/gsconsig/n8n-bypass/settings/secrets/actions
```
