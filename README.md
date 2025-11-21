# ToSemBandaRepo
Controle total do projeto: histórico completo

## Sobre o Projeto
Este repositório foi criado para armazenar todo o código e histórico de versões do projeto **To Sem Banda**, garantindo controle completo sobre todas as mudanças realizadas.

## Conectando com VS Code

### Primeira Vez (Clone do Repositório)
Se você ainda não tem o repositório localmente:

1. Abra o VS Code
2. Pressione `Ctrl+Shift+P` (ou `Cmd+Shift+P` no Mac)
3. Digite "Git: Clone" e selecione a opção
4. Cole a URL do repositório: `https://github.com/wagnermecanica-code/ToSemBandaRepo.git`
5. Escolha a pasta onde deseja salvar o projeto
6. Clique em "Open" quando o VS Code perguntar se deseja abrir o repositório clonado

### Projeto Existente (Conectar pasta local ao repositório)
Se você já tem o projeto em uma pasta local e quer conectar a este repositório:

1. Abra sua pasta do projeto no VS Code
2. Abra o terminal integrado (`Ctrl+` ou `Cmd+`)
3. Execute os seguintes comandos:

```bash
# Inicialize o Git (se ainda não estiver inicializado)
git init

# Adicione este repositório como origin
git remote add origin https://github.com/wagnermecanica-code/ToSemBandaRepo.git

# Baixe as atualizações do repositório
git fetch origin

# Configure a branch principal
git branch -M main
git branch --set-upstream-to=origin/main main

# Faça o merge das mudanças (se houver conflitos, resolva-os)
git pull origin main --allow-unrelated-histories

# Adicione seus arquivos
git add .

# Faça o primeiro commit
git commit -m "Conectando projeto local ao repositório"

# Envie para o GitHub
git push -u origin main
```

## Workflow Diário

### Salvando Mudanças
1. Faça suas alterações nos arquivos
2. No VS Code, vá para a aba "Source Control" (ícone de ramificação à esquerda)
3. Revise os arquivos modificados
4. Clique no "+" ao lado de cada arquivo para adicionar ao commit (ou clique no "+" no topo para adicionar todos)
5. Digite uma mensagem descritiva do commit
6. Clique no botão "✓ Commit"
7. Clique no botão "Sync Changes" ou use o menu "..." → "Push" para enviar ao GitHub

### Baixando Atualizações
1. No VS Code, clique no ícone de "Source Control"
2. Clique no menu "..." (três pontos)
3. Selecione "Pull" para baixar as últimas mudanças

## Extensões Recomendadas
O VS Code recomendará automaticamente as seguintes extensões ao abrir este projeto:
- **GitLens**: Visualização avançada do histórico Git
- **Git Graph**: Gráfico visual das branches e commits
- **Git History**: Histórico detalhado de arquivos e commits
- **GitHub Pull Requests**: Integração com GitHub
- **EditorConfig**: Mantém consistência no estilo do código

## Estrutura do Projeto
```
ToSemBandaRepo/
├── .vscode/              # Configurações do VS Code
├── .gitignore            # Arquivos ignorados pelo Git
├── .editorconfig         # Configurações de editor
└── README.md             # Este arquivo
```

## Boas Práticas
- Faça commits frequentes com mensagens claras
- Use mensagens de commit descritivas (ex: "Adiciona função de login", "Corrige bug na página inicial")
- Sempre faça Pull antes de começar a trabalhar para ter a versão mais recente
- Faça Push regularmente para não perder seu trabalho

## Suporte
Em caso de dúvidas ou problemas, consulte a [documentação do Git](https://git-scm.com/doc) ou a [documentação do GitHub](https://docs.github.com/).
