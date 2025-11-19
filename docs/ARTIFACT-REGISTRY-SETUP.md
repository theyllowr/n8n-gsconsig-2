# 🎯 Setup Rápido - Artifact Registry via Interface GCP

## 📋 Passos para Criar o Repositório

### 1. Acessar o Console GCP

1. Vá para: https://console.cloud.google.com
2. Selecione seu projeto
3. No menu lateral, procure por **Artifact Registry**

### 2. Criar Repositório Docker

1. Click em **"+ CREATE REPOSITORY"**

2. Preencha as informações:

   | Campo | Valor | Observação |
   |-------|-------|------------|
   | **Name** | `n8n` | Pode usar outro nome, mas ajustar no workflow |
   | **Format** | `Docker` | Selecionar na lista |
   | **Mode** | `Standard` | Padrão |
   | **Location type** | `Region` | Mais barato que Multi-region |
   | **Region** | `us-central1` (Iowa) | Ou escolha a mais próxima:<br>• `southamerica-east1` (São Paulo)<br>• `us-east1` (Carolina do Sul)<br>• `us-central1` (Iowa) |
   | **Description** | `N8N custom builds with license bypass` | Opcional |
   | **Encryption** | `Google-managed` | Padrão |

3. Click **CREATE**

### 3. Confirmar Criação

Após criar, você verá:
```
✅ Repository n8n created
Location: us-central1
Format: Docker
```

A URL do repositório será:
```
us-central1-docker.pkg.dev/SEU_PROJECT_ID/n8n
```

### 4. Ajustar Workflow (Se Necessário)

Se você escolheu:
- **Nome diferente** de `n8n` → Ajustar `ARTIFACT_REGISTRY_REPO` no workflow
- **Região diferente** de `us-central1` → Ajustar `ARTIFACT_REGISTRY_REGION` no workflow

Edite `.github/workflows/build-and-push.yml`:

```yaml
env:
  GCP_PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
  ARTIFACT_REGISTRY_REGION: us-central1    # ← SUA REGIÃO
  ARTIFACT_REGISTRY_REPO: n8n              # ← SEU NOME DO REPO
  IMAGE_NAME: n8n-custom
```

## 🌎 Regiões Disponíveis

### América do Sul
- `southamerica-east1` (São Paulo, Brasil) 🇧🇷
- `southamerica-west1` (Santiago, Chile) 🇨🇱

### América do Norte
- `us-central1` (Iowa)
- `us-east1` (Carolina do Sul)
- `us-east4` (Virginia do Norte)
- `us-west1` (Oregon)

### Europa
- `europe-west1` (Bélgica)
- `europe-west4` (Holanda)
- `europe-southwest1` (Madrid, Espanha)

### Ásia
- `asia-east1` (Taiwan)
- `asia-southeast1` (Singapura)

[Lista completa de regiões](https://cloud.google.com/artifact-registry/docs/repositories/repo-locations)

## 💰 Custos

**Artifact Registry** é cobrado por:
- **Armazenamento**: ~$0.10/GB/mês (regional)
- **Tráfego de saída**: Depende da região/destino
- **Operações**: Geralmente dentro do free tier

**Estimativa para este projeto:**
- Imagem n8n: ~500MB
- 1 build por semana
- **Custo mensal**: ~$0.05 - $0.50/mês

> 💡 **Dica**: Use a região mais próxima do seu deploy para reduzir custos de egress!

## ✅ Verificar Criação

Via CLI:
```bash
gcloud artifacts repositories describe n8n \
  --location=us-central1 \
  --format="table(name,format,createTime)"
```

Via Interface:
1. Artifact Registry → Repositories
2. Deve aparecer seu repositório `n8n`

## 🔐 Permissões Necessárias

Para **criar** o repositório via interface, você precisa de uma dessas roles:

- `roles/artifactregistry.admin` (pode criar/deletar repos)
- `roles/owner` ou `roles/editor` do projeto

> ⚠️ A **Service Account** do GitHub Actions precisa apenas de `roles/artifactregistry.writer` (não precisa criar repos, só fazer push)

## ❓ Troubleshooting

### Erro: "Permission denied"
**Causa**: Usuário não tem permissão para criar repositórios

**Solução**:
```bash
# Dar permissão de admin do Artifact Registry para seu usuário
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:SEU_EMAIL@gmail.com" \
  --role="roles/artifactregistry.admin"
```

### Repositório não aparece
**Causa**: Pode estar em região diferente

**Solução**:
```bash
# Listar todos os repositórios
gcloud artifacts repositories list
```

### Workflow falha com "repository not found"
**Causa**: Nome ou região no workflow diferente do criado

**Solução**:
Verifique que as variáveis no workflow correspondem:
```yaml
ARTIFACT_REGISTRY_REGION: us-central1  # ← mesma região
ARTIFACT_REGISTRY_REPO: n8n            # ← mesmo nome
```

---

**Próximo passo**: Configurar Service Account → Ver [`GCP-PERMISSIONS.md`](GCP-PERMISSIONS.md)
