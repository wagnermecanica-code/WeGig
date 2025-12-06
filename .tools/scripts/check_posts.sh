#!/bin/bash

echo "🔍 Verificando configuração do projeto To Sem Banda..."
echo ""

echo "1️⃣ Verificando conexão com Firebase..."
firebase projects:list 2>&1 | grep "to-sem-banda-83e19" && echo "✅ Projeto Firebase conectado" || echo "❌ Erro ao conectar com Firebase"
echo ""

echo "2️⃣ Verificando índices do Firestore..."
firebase firestore:indexes 2>&1 | grep -c "posts" && echo "✅ Índices para 'posts' encontrados" || echo "⚠️  Nenhum índice para 'posts'"
echo ""

echo "3️⃣ Verificando arquivos críticos..."
[ -f "lib/pages/home_page.dart" ] && echo "✅ home_page.dart encontrado" || echo "❌ home_page.dart não encontrado"
[ -f "lib/pages/view_profile_page.dart" ] && echo "✅ view_profile_page.dart encontrado" || echo "❌ view_profile_page.dart não encontrado"
[ -f "lib/pages/post_page.dart" ] && echo "✅ post_page.dart encontrado" || echo "❌ post_page.dart não encontrado"
echo ""

echo "4️⃣ Verificando campo 'location' no código de posts..."
grep -q "location.*userLocation" lib/pages/post_page.dart && echo "✅ Campo 'location' está sendo salvo nos posts" || echo "❌ Campo 'location' não encontrado no código"
echo ""

echo "5️⃣ Verificando estrutura de queries no código..."
grep -c "\.where('expiresAt'" lib/pages/home_page.dart && echo "✅ Filtro expiresAt encontrado em home_page.dart"
grep -c "\.where('authorUid'" lib/pages/view_profile_page.dart && echo "✅ Filtro authorUid encontrado em view_profile_page.dart"
echo ""

echo "✨ Diagnóstico concluído!"
echo ""
echo "📝 Próximos passos:"
echo "   1. Execute 'flutter run' para testar"
echo "   2. Crie um novo post no app"
echo "   3. Verifique se o post aparece na HomePage e no perfil"
echo "   4. Se ainda não aparecer, verifique os logs do Flutter com 'flutter logs'"
