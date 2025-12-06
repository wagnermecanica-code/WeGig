#!/bin/bash

# Script de testes end-to-end para Push Notifications
# Executar após configurar dispositivo/emulador

echo "🧪 WeGig - Testes End-to-End Push Notifications"
echo "================================================"
echo ""

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contadores
PASSED=0
FAILED=0
SKIPPED=0

# Função para executar teste
run_test() {
    local test_name="$1"
    local test_description="$2"
    
    echo -e "${YELLOW}📝 Teste: ${test_name}${NC}"
    echo "   Descrição: ${test_description}"
    echo "   Pressione ENTER após validar manualmente..."
    read
    
    echo "   ✅ Passou | ❌ Falhou | ⏭️  Pular?"
    read -n 1 result
    echo ""
    
    case $result in
        y|Y|s|S)
            echo -e "   ${GREEN}✅ PASSOU${NC}"
            ((PASSED++))
            ;;
        n|N)
            echo -e "   ${RED}❌ FALHOU${NC}"
            ((FAILED++))
            ;;
        *)
            echo -e "   ${YELLOW}⏭️  PULADO${NC}"
            ((SKIPPED++))
            ;;
    esac
    echo ""
}

echo "Certifique-se de que:"
echo "1. App está rodando em dispositivo/emulador"
echo "2. Firebase Console está aberto em outra aba"
echo "3. Usuário de teste está logado com 2+ perfis"
echo ""
echo "Pressione ENTER para começar..."
read

echo ""
echo "=== GRUPO 1: Permissões ==="
echo ""

run_test "1.1 - Permissão Inicial" \
    "Abrir app pela primeira vez → Configurações → Solicitar Permissão → Verificar pop-up aparece"

run_test "1.2 - Token FCM Gerado" \
    "Após conceder permissão → Verificar logs: '🔑 PushNotificationService: Token obtained'"

run_test "1.3 - Token Salvo Firestore" \
    "Firebase Console → Firestore → profiles/{profileId}/fcmTokens → Verificar documento criado com token, platform, createdAt"

echo ""
echo "=== GRUPO 2: Notificações Foreground ==="
echo ""

run_test "2.1 - Foreground - Recebimento" \
    "App aberto → Firebase Console → Cloud Messaging → Send test message (cole token FCM) → Enviar → Verificar notificação aparece no topo do app"

run_test "2.2 - Foreground - Logs" \
    "Verificar logs: '📩 PushNotificationService: Message received (foreground)' com título e corpo"

echo ""
echo "=== GRUPO 3: Notificações Background ==="
echo ""

run_test "3.1 - Background - Recebimento" \
    "Minimizar app (botão Home) → Enviar notificação via Firebase Console → Verificar notificação aparece na barra de status do sistema"

run_test "3.2 - Background - Tap Notificação" \
    "Clicar na notificação → App volta para foreground → Verificar logs: '👆 PushNotificationService: Notification tapped (background)'"

echo ""
echo "=== GRUPO 4: Notificações Terminated ==="
echo ""

run_test "4.1 - Terminated - Recebimento" \
    "Fechar app completamente (swipe up) → Enviar notificação → Verificar notificação aparece na barra de status"

run_test "4.2 - Terminated - Tap Notificação" \
    "Clicar na notificação → App abre do zero → Verificar logs: '👆 PushNotificationService: Notification tapped (terminated)'"

echo ""
echo "=== GRUPO 5: Multi-Perfil ==="
echo ""

run_test "5.1 - Troca de Perfil - Token Movido" \
    "Firestore Console → Perfil A tem token → Trocar para Perfil B no app → Verificar Perfil A não tem mais token E Perfil B tem token"

run_test "5.2 - Notificação Isolada por Perfil" \
    "Enviar notificação para Perfil B via Cloud Functions (criar post próximo) → Verificar Perfil B recebe, Perfil A não recebe"

echo ""
echo "=== GRUPO 6: Paginação ==="
echo ""

run_test "6.1 - Paginação - Loading Indicator" \
    "Criar 60+ notificações de teste → Abrir app → Notificações → Scroll até 80% → Verificar CircularProgressIndicator aparece no final"

run_test "6.2 - Paginação - Mais Notificações" \
    "Continuar scroll → Verificar mais 20 notificações carregadas → Logs: '📄 Paginação: Carregadas 20 notificações'"

run_test "6.3 - Paginação - Fim da Lista" \
    "Continuar scroll até fim → Verificar loading desaparece quando não há mais notificações"

run_test "6.4 - Paginação - Cursor Real" \
    "Verificar que notificações não são duplicadas (cursor startAfter funcionando)"

echo ""
echo "=== GRUPO 7: Background Handler ==="
echo ""

run_test "7.1 - Background Handler - Logs" \
    "App fechado → Enviar notificação → Verificar logs: '📩 Background Message: {messageId}' ANTES de app abrir"

echo ""
echo "================================================"
echo "📊 RESUMO DOS TESTES"
echo "================================================"
echo -e "${GREEN}✅ Passaram: $PASSED${NC}"
echo -e "${RED}❌ Falharam: $FAILED${NC}"
echo -e "${YELLOW}⏭️  Pulados: $SKIPPED${NC}"
echo "Total: $((PASSED + FAILED + SKIPPED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 Todos os testes passaram!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Alguns testes falharam. Revisar implementação.${NC}"
    exit 1
fi
