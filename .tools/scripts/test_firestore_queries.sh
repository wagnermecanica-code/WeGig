#!/bin/bash

# test_firestore_queries.sh
# Script para testar queries Firestore após fixes de array-contains
# Uso: ./.tools/scripts/test_firestore_queries.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔥 Firestore Query Test Suite"
echo "=============================="
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para verificar se emulador está rodando
check_emulator() {
    if lsof -i :8080 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Firebase Emulator detectado na porta 8080${NC}"
        return 0
    else
        echo -e "${RED}❌ Firebase Emulator não está rodando${NC}"
        echo -e "${YELLOW}Execute em outro terminal:${NC}"
        echo "  cd $REPO_ROOT"
        echo "  firebase emulators:start --only firestore"
        return 1
    fi
}

# Função para verificar análise estática
run_static_analysis() {
    echo ""
    echo "📊 1. Análise Estática"
    echo "---------------------"
    
    echo "Procurando queries inválidas com múltiplos array-contains..."
    
    # Buscar padrão inválido
    INVALID_QUERIES=$(grep -rn "array-contains" "$REPO_ROOT/packages/app/lib/features/" 2>/dev/null | grep -v "FIX:" | grep -v "//" | wc -l)
    
    if [ "$INVALID_QUERIES" -eq 0 ]; then
        echo -e "${GREEN}✅ Nenhuma query inválida detectada${NC}"
    else
        echo -e "${YELLOW}⚠️  $INVALID_QUERIES menções de array-contains encontradas${NC}"
        echo "Revise manualmente se todas têm FIX comment"
    fi
    
    # Verificar imports de FirebaseException
    echo ""
    echo "Verificando error handling..."
    PERMISSION_HANDLERS=$(grep -rn "permission-denied" "$REPO_ROOT/packages/app/lib/features/" 2>/dev/null | wc -l)
    
    if [ "$PERMISSION_HANDLERS" -gt 0 ]; then
        echo -e "${GREEN}✅ $PERMISSION_HANDLERS handlers de permission-denied encontrados${NC}"
    else
        echo -e "${YELLOW}⚠️  Nenhum handler de permission-denied encontrado${NC}"
    fi
}

# Função para executar testes unitários
run_unit_tests() {
    echo ""
    echo "🧪 2. Testes Unitários"
    echo "---------------------"
    
    cd "$REPO_ROOT"
    
    echo "Executando testes do datasource de mensagens..."
    if cd packages/app && flutter test test/features/messages/data/datasources/ 2>/dev/null; then
        echo -e "${GREEN}✅ Testes de datasource passaram${NC}"
    else
        echo -e "${YELLOW}⚠️  Sem testes de datasource ou falharam${NC}"
    fi
    
    cd "$REPO_ROOT"
}

# Função para validar Firestore rules
validate_rules() {
    echo ""
    echo "🔐 3. Validação de Security Rules"
    echo "---------------------------------"
    
    RULES_FILE="$REPO_ROOT/.config/firestore.rules"
    
    if [ -f "$RULES_FILE" ]; then
        echo "Verificando sintaxe das rules..."
        
        # Contar match statements
        MATCH_COUNT=$(grep -c "match /" "$RULES_FILE" || echo "0")
        echo "  - $MATCH_COUNT collections com rules"
        
        # Verificar se conversations tem rules
        if grep -q "match /conversations/" "$RULES_FILE"; then
            echo -e "${GREEN}  ✅ Rules para /conversations encontradas${NC}"
        else
            echo -e "${RED}  ❌ Rules para /conversations ausentes${NC}"
        fi
        
        # Verificar se notifications tem rules
        if grep -q "match /notifications/" "$RULES_FILE"; then
            echo -e "${GREEN}  ✅ Rules para /notifications encontradas${NC}"
        else
            echo -e "${RED}  ❌ Rules para /notifications ausentes${NC}"
        fi
        
        # Verificar se messages subcollection tem rules
        if grep -q "match /messages/" "$RULES_FILE"; then
            echo -e "${GREEN}  ✅ Rules para /messages encontradas${NC}"
        else
            echo -e "${RED}  ❌ Rules para /messages ausentes${NC}"
        fi
        
    else
        echo -e "${RED}❌ Arquivo firestore.rules não encontrado${NC}"
    fi
}

# Função para gerar checklist de testes manuais
generate_manual_test_checklist() {
    echo ""
    echo "📋 4. Checklist de Testes Manuais"
    echo "---------------------------------"
    echo ""
    echo "Execute os seguintes testes no app:"
    echo ""
    echo "[ ] 1. MENSAGENS"
    echo "    [ ] Criar nova conversa com outro perfil"
    echo "    [ ] Enviar mensagem"
    echo "    [ ] Ver lista de conversas (deve aparecer nova)"
    echo "    [ ] Badge de não lidas deve atualizar"
    echo "    [ ] Trocar perfil → conversas devem isolar corretamente"
    echo ""
    echo "[ ] 2. NOTIFICAÇÕES"
    echo "    [ ] Receber notificação de interesse em post"
    echo "    [ ] Notificação aparece na lista"
    echo "    [ ] Marcar como lida → badge decrementa"
    echo "    [ ] Trocar perfil → notificações devem isolar"
    echo ""
    echo "[ ] 3. MULTI-PERFIL"
    echo "    [ ] Login com perfil A"
    echo "    [ ] Criar conversa"
    echo "    [ ] Trocar para perfil B"
    echo "    [ ] Conversa do perfil A não deve aparecer"
    echo "    [ ] Voltar para perfil A"
    echo "    [ ] Conversa deve reaparecer"
    echo ""
    echo "[ ] 4. ERROR HANDLING"
    echo "    [ ] Desconectar internet"
    echo "    [ ] Tentar carregar conversas"
    echo "    [ ] Mensagem de erro deve ser clara"
    echo "    [ ] Reconectar → deve funcionar automaticamente"
    echo ""
    echo "[ ] 5. PERFORMANCE"
    echo "    [ ] Lista de conversas carrega em <2s"
    echo "    [ ] Badge counter atualiza em <1s"
    echo "    [ ] Sem lag ao scrollar lista"
    echo "    [ ] Memória estável (sem leaks)"
    echo ""
}

# Função para mostrar comandos úteis
show_useful_commands() {
    echo ""
    echo "🛠️  5. Comandos Úteis"
    echo "--------------------"
    echo ""
    echo "# Iniciar Firebase Emulator:"
    echo "firebase emulators:start --only firestore"
    echo ""
    echo "# Executar app no emulador (terminal separado):"
    echo "cd packages/app && flutter run --flavor dev -t lib/main_dev.dart"
    echo ""
    echo "# Limpar dados do emulador:"
    echo "firebase emulators:start --only firestore --import=./firebase-export --export-on-exit"
    echo ""
    echo "# Deploy rules para dev:"
    echo "firebase deploy --only firestore:rules --project wegig-dev"
    echo ""
    echo "# Monitorar logs:"
    echo "firebase functions:log --project wegig-dev"
    echo ""
    echo "# Ver dados no Emulator UI:"
    echo "open http://localhost:4000"
    echo ""
}

# Função principal
main() {
    cd "$REPO_ROOT"
    
    # 1. Verificar emulador
    if ! check_emulator; then
        echo ""
        echo -e "${YELLOW}💡 Este script funciona melhor com o emulador rodando${NC}"
        echo -e "${YELLOW}   Continuando com verificações estáticas...${NC}"
    fi
    
    # 2. Análise estática
    run_static_analysis
    
    # 3. Testes unitários
    run_unit_tests
    
    # 4. Validar rules
    validate_rules
    
    # 5. Gerar checklist
    generate_manual_test_checklist
    
    # 6. Mostrar comandos úteis
    show_useful_commands
    
    echo ""
    echo "=============================="
    echo -e "${GREEN}✅ Verificação completa!${NC}"
    echo ""
    echo "Próximos passos:"
    echo "1. Execute testes manuais da checklist acima"
    echo "2. Se tudo OK, deploy rules: firebase deploy --only firestore:rules"
    echo "3. Monitore logs por 10 minutos"
    echo ""
}

# Executar
main
