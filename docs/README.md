# WeGig Website - wegig.com.br

Este diretório contém o site institucional do WeGig, incluindo:

- **index.html**: Homepage com informações sobre o app
- **termos.html**: Termos de Uso (gerado de TERMS_OF_SERVICE.md)
- **privacidade.html**: Política de Privacidade (gerado de PRIVACY_POLICY.md)
- **style.css**: Estilos CSS globais

## 🚀 Como Publicar no GitHub Pages

### 1. Converter Markdown para HTML

```bash
# Execute o script de conversão
python3 scripts/convert_markdown_to_html.py
```

### 2. Commit e Push

```bash
git add docs/
git commit -m "Add website files for wegig.com.br"
git push origin main
```

### 3. Configurar GitHub Pages

1. Acesse: `https://github.com/wagnermecanica-code/ToSemBandaRepo/settings/pages`
2. Em **Source**, selecione: `main` branch, `/docs` folder
3. Clique em **Save**
4. GitHub Pages estará disponível em: `https://wagnermecanica-code.github.io/ToSemBandaRepo/`

### 4. Configurar Domínio Customizado (wegig.com.br)

#### No Painel do Registro.br (ou provedor de DNS):

Adicione esses registros DNS:

```
# APEX domain (wegig.com.br)
A     @    185.199.108.153
A     @    185.199.109.153
A     @    185.199.110.153
A     @    185.199.111.153

# WWW subdomain
CNAME www  wagnermecanica-code.github.io
```

#### No GitHub:

1. Acesse: `https://github.com/wagnermecanica-code/ToSemBandaRepo/settings/pages`
2. Em **Custom domain**, digite: `wegig.com.br`
3. Aguarde verificação DNS (pode levar até 24h)
4. Ative **Enforce HTTPS** (recomendado)

### 5. Testar

Após propagação DNS (até 24h):
- ✅ https://wegig.com.br
- ✅ https://www.wegig.com.br
- ✅ https://wegig.com.br/termos.html
- ✅ https://wegig.com.br/privacidade.html

## 📝 Atualizar Documentos Legais

Quando alterar `TERMS_OF_SERVICE.md` ou `PRIVACY_POLICY.md`:

```bash
# 1. Edite os arquivos .md na raiz do projeto
# 2. Reconverta para HTML
python3 scripts/convert_markdown_to_html.py

# 3. Commit e push
git add docs/
git commit -m "Update legal documents"
git push origin main
```

GitHub Pages atualizará automaticamente em ~1 minuto.

## 🔧 Desenvolvimento Local

Para testar o site localmente:

```bash
# Navegue até a pasta docs
cd docs/

# Inicie um servidor HTTP simples
python3 -m http.server 8000

# Acesse no navegador
open http://localhost:8000
```

## 📁 Estrutura de Arquivos

```
docs/
├── _config.yml          # Configuração Jekyll (GitHub Pages)
├── index.html           # Homepage
├── termos.html          # Termos de Uso (gerado)
├── privacidade.html     # Política de Privacidade (gerado)
├── style.css            # Estilos CSS
├── favicon.png          # (opcional) Ícone do site
└── README.md            # Este arquivo
```

## 🎨 Personalização

Para modificar o design:
1. Edite `docs/style.css` (cores, fontes, espaçamento)
2. Edite `docs/index.html` (conteúdo, seções)
3. Commit e push

## 📱 Atualizar Links no App

Após configurar o domínio, atualize os links em `lib/pages/auth_page.dart`:

```dart
// Linha ~650
const url = 'https://wegig.com.br/termos';

// Linha ~669
const url = 'https://wegig.com.br/privacidade';
```

## ✅ Checklist de Deploy

- [ ] Executar `convert_markdown_to_html.py`
- [ ] Commit e push dos arquivos em `docs/`
- [ ] Configurar GitHub Pages (main branch, /docs folder)
- [ ] Adicionar registros DNS no Registro.br
- [ ] Configurar custom domain no GitHub
- [ ] Aguardar propagação DNS (até 24h)
- [ ] Ativar HTTPS no GitHub Pages
- [ ] Testar todos os links (home, termos, privacidade)
- [ ] Atualizar URLs em `auth_page.dart`
- [ ] Build e deploy do app com novos URLs

## 🆘 Troubleshooting

**Problema:** Site não carrega após configurar DNS  
**Solução:** Aguarde propagação DNS (até 24h). Teste com `dig wegig.com.br` ou `nslookup wegig.com.br`

**Problema:** CSS não carrega  
**Solução:** Verifique se `style.css` está em `docs/` e commit foi feito

**Problema:** Links quebrados  
**Solução:** Use paths relativos (`termos.html`, não `/termos.html`)

**Problema:** Erro "Domain's DNS record could not be retrieved"  
**Solução:** Verifique registros DNS. Use [whatsmydns.net](https://www.whatsmydns.net/#A/wegig.com.br) para checar propagação

## 📞 Contato

Dúvidas sobre o site: suporte@wegig.com.br
