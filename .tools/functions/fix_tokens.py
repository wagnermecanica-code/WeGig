#!/usr/bin/env python3
"""Script para corrigir a lógica de tokens FCM no index.js"""

import re

with open('index.js', 'r') as f:
    content = f.read()

# Verificar se precisa de correção
if 'SIXTY_DAYS_MS' in content:
    print("Encontrado SIXTY_DAYS_MS - removendo lógica de expiração por idade...")
    
    # Padrão regex para encontrar e substituir o bloco
    old_pattern = r'''    // Filtrar tokens válidos \(não expirados\) e ordenar por updatedAt \(mais recente primeiro\)
    const now = Date\.now\(\);
    const SIXTY_DAYS_MS = 60 \* 24 \* 60 \* 60 \* 1000; // 60 dias
    const validTokens = \[\];

    tokensSnap\.docs\.forEach\(\(tokenDoc\) => \{
      const tokenData = tokenDoc\.data\(\);
      const token = tokenData\.token;
      const updatedAt = tokenData\.updatedAt\?\.toMillis\(\) \|\| 0;

      // Validar idade do token
      const tokenAgeMs = now - updatedAt;
      if \(tokenAgeMs > SIXTY_DAYS_MS\) \{
        const tokenAgeDays = Math\.floor\(tokenAgeMs / \(24 \* 60 \* 60 \* 1000\)\);
        console\.log\(`⏰ Token expirado \(\$\{tokenAgeDays\} dias\), pulando\.\.\.`\);
        return; // Skip
      \}

      validTokens\.push\(\{ token, updatedAt \}\);
    \}\);'''

    new_block = '''    // Filtrar tokens válidos e ordenar por updatedAt (mais recente primeiro)
    // NOTA: NÃO expiramos tokens por idade - FCM reporta tokens inválidos no envio
    const validTokens = [];

    tokensSnap.docs.forEach((tokenDoc) => {
      const tokenData = tokenDoc.data();
      const token = typeof tokenData.token === "string" ? tokenData.token.trim() : "";
      if (!token) return;

      const updatedAt = tokenData.updatedAt?.toMillis() ||
        tokenData.createdAt?.toMillis() || 0;

      validTokens.push({ token, updatedAt });
    });'''

    # Tentar substituição com regex
    new_content = re.sub(old_pattern, new_block, content, flags=re.DOTALL)
    
    if new_content != content:
        with open('index.js', 'w') as f:
            f.write(new_content)
        print("✅ Lógica de expiração removida com sucesso!")
    else:
        print("⚠️ Regex não casou - tentando abordagem alternativa...")
        
        # Abordagem alternativa: substituir linha por linha
        lines = content.split('\n')
        new_lines = []
        skip_until_close = False
        i = 0
        
        while i < len(lines):
            line = lines[i]
            
            # Detectar início do bloco a ser substituído
            if 'SIXTY_DAYS_MS' in line:
                # Pular linhas relacionadas à expiração
                while i < len(lines) and 'Token expirado' not in lines[i]:
                    i += 1
                # Pular a linha com 'Token expirado'
                if i < len(lines):
                    i += 1
                # Pular 'return; // Skip' e '}'
                while i < len(lines) and (lines[i].strip() == 'return; // Skip' or lines[i].strip() == '}'):
                    i += 1
            else:
                new_lines.append(line)
                i += 1
        
        # Escrever resultado
        with open('index.js', 'w') as f:
            f.write('\n'.join(new_lines))
        print("✅ Correção aplicada (abordagem alternativa)")
else:
    print("✅ SIXTY_DAYS_MS não encontrado - arquivo já corrigido ou não precisa de correção")

# Verificar resultado
with open('index.js', 'r') as f:
    final = f.read()
    
if 'slice(0, 5)' in final:
    print("✅ slice(0, 5) confirmado")
else:
    print("⚠️ slice(0, 5) NÃO encontrado!")
    
if 'SIXTY_DAYS_MS' in final:
    print("⚠️ SIXTY_DAYS_MS ainda presente!")
else:
    print("✅ SIXTY_DAYS_MS removido")
