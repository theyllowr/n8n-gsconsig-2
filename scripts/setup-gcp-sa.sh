#!/bin/bash
set -euo pipefail

# 🎨 Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# ============================================
# Configuração
# ============================================
read -p "Digite o ID do seu projeto GCP: " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    log_error "PROJECT_ID não pode ser vazio!"
    exit 1
fi

SA_NAME="n8n-builder"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
SA_DISPLAY_NAME="N8N Docker Builder"
KEY_FILE="n8n-builder-key.json"

log_info "Configurando Service Account para N8N Builder"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Project ID: $PROJECT_ID"
echo "SA Name: $SA_NAME"
echo "SA Email: $SA_EMAIL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "Continuar? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Operação cancelada pelo usuário"
    exit 0
fi

# ============================================
# 1. Criar Service Account
# ============================================
log_info "Criando Service Account..."

if gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" &>/dev/null; then
    log_warning "Service Account já existe: $SA_EMAIL"
else
    gcloud iam service-accounts create "$SA_NAME" \
        --display-name="$SA_DISPLAY_NAME" \
        --description="Service Account para build e push de imagens N8N customizadas no Artifact Registry" \
        --project="$PROJECT_ID"
    
    log_success "Service Account criada: $SA_EMAIL"
fi

# ============================================
# 2. Atribuir Permissões (Mínimo Necessário)
# ============================================
log_info "Atribuindo permissões mínimas necessárias..."

# Permissão 1: Artifact Registry Writer (ESSENCIAL)
# Permite: criar, ler, atualizar e deletar artefatos no registry
log_info "Adicionando roles/artifactregistry.writer..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/artifactregistry.writer" \
    --condition=None \
    --quiet

log_success "Role: artifactregistry.writer ✅"

# Permissão 2: Storage Object Viewer (OPCIONAL mas recomendado)
# Permite: ler objetos do Storage (caso o Artifact Registry use GCS como backend)
log_info "Adicionando roles/storage.objectViewer..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/storage.objectViewer" \
    --condition=None \
    --quiet

log_success "Role: storage.objectViewer ✅"

# ============================================
# 3. Criar Chave JSON
# ============================================
log_info "Criando chave JSON..."

if [ -f "$KEY_FILE" ]; then
    log_warning "Arquivo $KEY_FILE já existe!"
    read -p "Sobrescrever? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Pulando criação de chave"
        KEY_FILE=""
    else
        rm "$KEY_FILE"
    fi
fi

if [ -n "$KEY_FILE" ]; then
    gcloud iam service-accounts keys create "$KEY_FILE" \
        --iam-account="$SA_EMAIL" \
        --project="$PROJECT_ID"
    
    log_success "Chave JSON criada: $KEY_FILE"
    
    # Verificar se o arquivo foi criado
    if [ ! -f "$KEY_FILE" ]; then
        log_error "Falha ao criar arquivo de chave!"
        exit 1
    fi
    
    # Mostrar preview (primeiras linhas, sem dados sensíveis)
    echo ""
    log_info "Preview da chave (primeiras 3 linhas):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    head -3 "$KEY_FILE"
    echo "..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

# ============================================
# 4. Verificar Permissões
# ============================================
echo ""
log_info "Verificando permissões atribuídas..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

gcloud projects get-iam-policy "$PROJECT_ID" \
    --flatten="bindings[].members" \
    --filter="bindings.members:serviceAccount:$SA_EMAIL" \
    --format="table(bindings.role)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================
# 5. Resumo e Próximos Passos
# ============================================
echo ""
log_success "🎉 Service Account configurada com sucesso!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 RESUMO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Service Account: $SA_EMAIL"
echo ""
echo "✅ Permissões Atribuídas:"
echo "   • roles/artifactregistry.writer  (Push/Pull imagens)"
echo "   • roles/storage.objectViewer     (Leitura GCS)"
echo ""

if [ -f "$KEY_FILE" ]; then
    echo "📁 Arquivo de Chave: $KEY_FILE"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔐 PRÓXIMOS PASSOS - GitHub Secrets"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1️⃣  Vá para: https://github.com/gsconsig/n8n-bypass/settings/secrets/actions"
    echo ""
    echo "2️⃣  Adicione os seguintes secrets:"
    echo ""
    echo "    Secret Name: GCP_PROJECT_ID"
    echo "    Value: $PROJECT_ID"
    echo ""
    echo "    Secret Name: GCP_SA_KEY"
    echo "    Value: (cole o conteúdo completo de $KEY_FILE)"
    echo ""
    echo "3️⃣  Para copiar o conteúdo da chave:"
    echo ""
    echo "    cat $KEY_FILE | pbcopy   # macOS"
    echo "    cat $KEY_FILE | xclip     # Linux"
    echo ""
    log_warning "⚠️  IMPORTANTE: Guarde $KEY_FILE em local seguro e NÃO commite no git!"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗑️  Para deletar a Service Account (se necessário):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "gcloud iam service-accounts delete $SA_EMAIL --project=$PROJECT_ID"
echo ""
