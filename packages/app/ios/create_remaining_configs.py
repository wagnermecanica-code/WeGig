#!/usr/bin/env python3
"""
Script para criar as configurações restantes do Runner target no Xcode.
Cria: Release-dev, Profile-dev, Debug-staging, Release-staging, Profile-staging
"""

import re
import uuid

def generate_xcode_uuid():
    """Gera um UUID no formato do Xcode (24 caracteres uppercase hex)"""
    return uuid.uuid4().hex[:24].upper()

def main():
    pbxproj_path = 'Runner.xcodeproj/project.pbxproj'
    
    # Ler o arquivo
    print("📖 Lendo project.pbxproj...")
    with open(pbxproj_path, 'r') as f:
        content = f.read()
    
    # Backup
    backup_path = pbxproj_path + '.backup2'
    with open(backup_path, 'w') as f:
        f.write(content)
    print(f"✅ Backup criado: {backup_path}")
    
    # Encontrar as configurações base do Runner target
    configs = {}
    
    # Debug já foi criado como Debug-dev, vamos buscar Release e Profile
    release_match = re.search(
        r'(97C147071CF9000F007C117D /\* Release \*/ = \{.*?name = Release;.*?\};)',
        content,
        re.DOTALL
    )
    
    profile_match = re.search(
        r'(249021D4217E4FDB00AE95B9 /\* Profile \*/ = \{.*?name = Profile;.*?\};)',
        content,
        re.DOTALL
    )
    
    if not release_match or not profile_match:
        print("❌ Erro: Não encontrou configurações Release ou Profile do Runner")
        return
    
    configs['Release'] = release_match.group(1)
    configs['Profile'] = profile_match.group(1)
    
    print("✅ Configurações base encontradas")
    
    # Definir quais configurações criar
    new_configs = [
        ('Release', 'Release-dev', 'dev'),
        ('Profile', 'Profile-dev', 'dev'),
        ('Release', 'Debug-staging', 'staging'),  # Usar Release como base para Debug
        ('Release', 'Release-staging', 'staging'),
        ('Profile', 'Profile-staging', 'staging'),
    ]
    
    # UUIDs gerados
    uuids = {
        'Release-dev': generate_xcode_uuid(),
        'Profile-dev': generate_xcode_uuid(),
        'Debug-staging': generate_xcode_uuid(),
        'Release-staging': generate_xcode_uuid(),
        'Profile-staging': generate_xcode_uuid(),
    }
    
    print("\n🆔 UUIDs gerados:")
    for name, uuid_val in uuids.items():
        print(f"  {name}: {uuid_val}")
    
    # Criar as novas configurações
    new_config_blocks = []
    
    for base_name, new_name, flavor in new_configs:
        base_config = configs[base_name]
        new_uuid = uuids[new_name]
        
        # Criar nova configuração
        new_config = base_config
        
        # Substituir UUID
        old_uuid = re.search(r'([A-F0-9]{24})', base_config).group(1)
        new_config = new_config.replace(old_uuid, new_uuid)
        
        # Substituir nome
        new_config = re.sub(
            r'/\* ' + base_name + r' \*/',
            '/* ' + new_name + ' */',
            new_config
        )
        new_config = re.sub(
            r'name = ' + base_name + ';',
            'name = "' + new_name + '";',
            new_config
        )
        
        # Ajustar baseConfigurationReference para Debug-staging
        if new_name == 'Debug-staging':
            # Usar Debug.xcconfig ao invés de Release.xcconfig
            new_config = re.sub(
                r'7AFA3C8E1D35360C0083082E /\* Release\.xcconfig \*/',
                '9740EEB21CF90195004384FC /* Debug.xcconfig */',
                new_config
            )
        
        new_config_blocks.append((new_uuid, new_name, new_config))
        print(f"✅ Criada configuração: {new_name}")
    
    # Inserir as novas configurações após Profile
    profile_end = profile_match.end()
    
    insert_text = ''
    for uuid_val, name, config_block in new_config_blocks:
        insert_text += '\n\t\t' + config_block
    
    content = content[:profile_end] + insert_text + content[profile_end:]
    
    # Atualizar a lista de configurações do Runner target
    # Encontrar: 97C147051CF9000F007C117D /* Build configuration list for PBXNativeTarget "Runner" */
    config_list_match = re.search(
        r'(97C147051CF9000F007C117D /\* Build configuration list for PBXNativeTarget "Runner" \*/ = \{.*?buildConfigurations = \()(.*?)(\);)',
        content,
        re.DOTALL
    )
    
    if not config_list_match:
        print("❌ Erro: Não encontrou lista de configurações do Runner target")
        return
    
    # Adicionar os novos UUIDs à lista
    current_list = config_list_match.group(2)
    
    new_entries = ''
    for uuid_val, name, _ in new_config_blocks:
        new_entries += f'\n\t\t\t\t{uuid_val} /* {name} */,'
    
    updated_list = config_list_match.group(1) + current_list + new_entries + config_list_match.group(3)
    
    content = content[:config_list_match.start()] + updated_list + content[config_list_match.end():]
    
    print("✅ Lista de configurações do Runner atualizada")
    
    # Salvar
    with open(pbxproj_path, 'w') as f:
        f.write(content)
    
    print(f"\n🎉 Concluído! Configurações criadas:")
    for uuid_val, name, _ in new_config_blocks:
        print(f"  ✅ {name} ({uuid_val})")
    
    print(f"\n📝 Backup salvo em: {backup_path}")
    print("\n🚀 Agora você pode rodar: flutter run --flavor dev -t lib/main_dev.dart")

if __name__ == '__main__':
    main()
