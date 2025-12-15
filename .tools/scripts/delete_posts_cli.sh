#!/bin/bash

echo "🔥 Script para deletar posts antigos sem campo 'location'"
echo ""
echo "⚠️  IMPORTANTE: Este script usa Firebase CLI para deletar documentos."
echo ""

# Verifica se firebase-tools está instalado
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI não está instalado."
    echo "   Instale com: npm install -g firebase-tools"
    exit 1
fi

echo "🔍 Buscando posts sem campo 'location'..."
echo ""

# Lista os documentos da coleção posts
firebase firestore:get posts --limit 100 2>/dev/null | grep -B 5 "Document ID" | while read line; do
    if [[ $line == *"Document ID:"* ]]; then
        DOC_ID=$(echo $line | sed 's/Document ID: //')
        echo "Analisando documento: $DOC_ID"
        
        # Verifica se tem o campo location
        firebase firestore:get "posts/$DOC_ID" 2>/dev/null | grep -q "location:" 
        
        if [ $? -ne 0 ]; then
            echo "   ❌ Sem campo 'location' - marcado para deletar"
            echo "$DOC_ID" >> /tmp/posts_to_delete.txt
        else
            echo "   ✅ Tem campo 'location'"
        fi
        echo ""
    fi
done

if [ ! -f /tmp/posts_to_delete.txt ]; then
    echo "✨ Nenhum post antigo encontrado! Todos os posts têm o campo 'location'."
    exit 0
fi

POST_COUNT=$(wc -l < /tmp/posts_to_delete.txt)
echo ""
echo "📊 Total de posts a deletar: $POST_COUNT"
echo ""
echo "⚠️  Posts que serão deletados:"
cat /tmp/posts_to_delete.txt
echo ""

read -p "Deseja prosseguir com a deleção? (s/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Operação cancelada."
    rm /tmp/posts_to_delete.txt
    exit 0
fi

echo ""
echo "🗑️  Deletando posts..."

DELETED=0
while read -r DOC_ID; do
    firebase firestore:delete "posts/$DOC_ID" --force 2>/dev/null
    if [ $? -eq 0 ]; then
        ((DELETED++))
        echo "   ✅ Deletado: $DOC_ID"
    else
        echo "   ❌ Erro ao deletar: $DOC_ID"
    fi
done < /tmp/posts_to_delete.txt

rm /tmp/posts_to_delete.txt

echo ""
echo "✅ Processo concluído!"
echo "   Posts deletados: $DELETED"
echo ""
