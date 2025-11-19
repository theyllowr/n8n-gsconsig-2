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

# Verificar se o diretório n8n existe
if [ ! -d "/tmp/n8n" ]; then
    log_error "Diretório /tmp/n8n não encontrado!"
    log_info "Execute primeiro: git clone https://github.com/n8n-io/n8n.git /tmp/n8n"
    exit 1
fi

log_info "Aplicando patches de bypass de licença no n8n..."

# ============================================
# PATCH 1: License.ts - Bypass Global
# ============================================
LICENSE_FILE="/tmp/n8n/packages/cli/src/license.ts"

if [ -f "$LICENSE_FILE" ]; then
    log_info "Aplicando patch em: $LICENSE_FILE"
    
    # Backup do arquivo original
    cp "$LICENSE_FILE" "${LICENSE_FILE}.backup"
    log_success "Backup criado: ${LICENSE_FILE}.backup"
    
    # Patch do método isLicensed
    cat > /tmp/patch_license.ts << 'EOF'
	isLicensed(feature: BooleanLicenseFeature) {
		// 🔓 BYPASS GLOBAL - TODAS FUNCIONALIDADES PREMIUM LIBERADAS
		// Modificado por: n8n-bypass automation
		return true;
	}
EOF
    
    # Aplicar o patch usando awk para substituir o método completo
    awk '
    BEGIN { in_method = 0; skip = 0 }
    /isLicensed\(feature: BooleanLicenseFeature\) {/ {
        in_method = 1
        print "\tisLicensed(feature: BooleanLicenseFeature) {"
        print "\t\t// 🔓 BYPASS GLOBAL - TODAS FUNCIONALIDADES PREMIUM LIBERADAS"
        print "\t\t// Modificado por: n8n-bypass automation"
        print "\t\treturn true;"
        next
    }
    in_method && /^[[:space:]]*}[[:space:]]*$/ {
        if (!skip) {
            print "\t}"
            in_method = 0
            skip = 1
            next
        }
    }
    !in_method { skip = 0; print }
    ' "$LICENSE_FILE" > "${LICENSE_FILE}.tmp" && mv "${LICENSE_FILE}.tmp" "$LICENSE_FILE"
    
    log_success "Método isLicensed() modificado com bypass global"
    
    # Patch do método getValue para quotas ilimitadas
    awk '
    BEGIN { in_method = 0 }
    /getValue<T extends keyof FeatureReturnType>\(feature: T\): FeatureReturnType\[T\] {/ {
        in_method = 1
        print "\tgetValue<T extends keyof FeatureReturnType>(feature: T): FeatureReturnType[T] {"
        print "\t\t// 🔓 BYPASS QUOTAS - Valores ilimitados"
        print "\t\t// Modificado por: n8n-bypass automation"
        print "\t\tconst quotaFeatures = ["
        print "\t\t\t\"quota:activeWorkflows\","
        print "\t\t\t\"quota:maxVariables\","
        print "\t\t\t\"quota:users\","
        print "\t\t\t\"quota:workflowHistoryPrune\","
        print "\t\t\t\"quota:maxTeamProjects\","
        print "\t\t\t\"quota:aiCredits\""
        print "\t\t];"
        print "\t\t"
        print "\t\tif (quotaFeatures.some(q => feature.toString().includes(q))) {"
        print "\t\t\treturn -1 as FeatureReturnType[T]; // -1 = ilimitado"
        print "\t\t}"
        print ""
        next
    }
    !in_method { print }
    in_method && /return this\.manager/ { in_method = 0; print }
    ' "$LICENSE_FILE" > "${LICENSE_FILE}.tmp" && mv "${LICENSE_FILE}.tmp" "$LICENSE_FILE"
    
    log_success "Método getValue() modificado com quotas ilimitadas"
    
else
    log_error "Arquivo não encontrado: $LICENSE_FILE"
    exit 1
fi

# ============================================
# PATCH 2: License-state.ts - Bypass Adicional
# ============================================
LICENSE_STATE_FILE="/tmp/n8n/packages/@n8n/backend-common/src/license-state.ts"

if [ -f "$LICENSE_STATE_FILE" ]; then
    log_info "Aplicando patch em: $LICENSE_STATE_FILE"
    
    # Backup do arquivo original
    cp "$LICENSE_STATE_FILE" "${LICENSE_STATE_FILE}.backup"
    log_success "Backup criado: ${LICENSE_STATE_FILE}.backup"
    
    # Aplicar bypass adicional
    awk '
    BEGIN { in_method = 0 }
    /isLicensed\(feature: BooleanLicenseFeature\): boolean {/ {
        in_method = 1
        print "\tisLicensed(feature: BooleanLicenseFeature): boolean {"
        print "\t\t// 🔓 BYPASS ADICIONAL - Garantia de features liberadas"
        print "\t\t// Modificado por: n8n-bypass automation"
        print "\t\treturn true;"
        next
    }
    in_method && /^[[:space:]]*}[[:space:]]*$/ {
        print "\t}"
        in_method = 0
        next
    }
    !in_method { print }
    ' "$LICENSE_STATE_FILE" > "${LICENSE_STATE_FILE}.tmp" && mv "${LICENSE_STATE_FILE}.tmp" "$LICENSE_STATE_FILE"
    
    log_success "Método isLicensed() do license-state modificado"
    
else
    log_warning "Arquivo não encontrado: $LICENSE_STATE_FILE (pode não existir em algumas versões)"
fi

# ============================================
# VERIFICAÇÃO DOS PATCHES
# ============================================
log_info "Verificando patches aplicados..."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 License.ts - Método isLicensed()"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
grep -A 5 "isLicensed(feature: BooleanLicenseFeature)" "$LICENSE_FILE" | head -6 || log_warning "Método não encontrado"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 License.ts - Método getValue()"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
grep -A 10 "getValue<T extends keyof FeatureReturnType>" "$LICENSE_FILE" | head -11 || log_warning "Método não encontrado"

if [ -f "$LICENSE_STATE_FILE" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 License-state.ts - Método isLicensed()"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    grep -A 5 "isLicensed(feature: BooleanLicenseFeature)" "$LICENSE_STATE_FILE" | head -6 || log_warning "Método não encontrado"
fi

echo ""
log_success "🎉 Todos os patches foram aplicados com sucesso!"
echo ""
log_info "Próximos passos:"
echo "  1. cd /tmp/n8n"
echo "  2. pnpm install"
echo "  3. pnpm build"
echo "  4. Construir imagem Docker com as modificações"
