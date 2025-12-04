#!/bin/bash

# Gerar UUIDs únicos para as novas configurações
DEBUG_DEV_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:lower:]' '[:upper:]')
RELEASE_DEV_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:upper:]' '[:upper:]')
PROFILE_DEV_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:upper:]' '[:upper:]')
DEBUG_STAGING_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:upper:]' '[:upper:]')
RELEASE_STAGING_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:upper:]' '[:upper:]')
PROFILE_STAGING_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:upper:]' '[:upper:]')

echo "Generated UUIDs:"
echo "Debug-dev: $DEBUG_DEV_UUID"
echo "Release-dev: $RELEASE_DEV_UUID"
echo "Profile-dev: $PROFILE_DEV_UUID"
echo "Debug-staging: $DEBUG_STAGING_UUID"
echo "Release-staging: $RELEASE_STAGING_UUID"
echo "Profile-staging: $PROFILE_STAGING_UUID"

# Backup
cp Runner.xcodeproj/project.pbxproj Runner.xcodeproj/project.pbxproj.backup

# Script Python para adicionar as configurações
python3 << PYTHON_EOF
import re

# Ler o arquivo
with open('Runner.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Encontrar a configuração Debug do Runner (97C147061CF9000F007C117D)
debug_config_match = re.search(
    r'(97C147061CF9000F007C117D /\* Debug \*/ = \{.*?name = Debug;.*?\};)',
    content,
    re.DOTALL
)

if not debug_config_match:
    print("❌ Não encontrou configuração Debug do Runner")
    exit(1)

debug_config = debug_config_match.group(1)

# Criar Debug-dev
debug_dev = debug_config.replace('97C147061CF9000F007C117D', '$DEBUG_DEV_UUID')
debug_dev = debug_dev.replace('name = Debug;', 'name = "Debug-dev";')
debug_dev = debug_dev.replace('/* Debug */', '/* Debug-dev */')

# Inserir após a configuração Debug
insert_pos = debug_config_match.end()
content = content[:insert_pos] + '\n\t\t' + debug_dev + content[insert_pos:]

print("✅ Configurações adicionadas!")

# Salvar
with open('Runner.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

PYTHON_EOF

echo "✅ Configurações do Runner criadas!"
