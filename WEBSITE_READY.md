# ✅ Website wegig.com.br - Pronto para Deploy!

## 📦 O que foi criado:

### 1. **Site Institucional** (`docs/`)
- ✅ `index.html` - Homepage com informações sobre o app
- ✅ `style.css` - Design moderno (Teal #00A699 + Coral #FF6B6B)
- ✅ `termos.html` - Termos de Uso (convertido de Markdown)
- ✅ `privacidade.html` - Política de Privacidade (convertido de Markdown)
- ✅ `CNAME` - Arquivo para custom domain (wegig.com.br)
- ✅ `_config.yml` - Configuração Jekyll para GitHub Pages

### 2. **Documentos Legais** (raiz do projeto)
- ✅ `TERMS_OF_SERVICE.md` - Termos completos (LGPD/GDPR compliance)
- ✅ `PRIVACY_POLICY.md` - Política completa com geolocalização e multi-perfil

### 3. **Scripts e Guias**
- ✅ `scripts/convert_markdown_to_html.py` - Converte MD → HTML
- ✅ `DEPLOY_GUIDE_WEGIG.md` - Guia passo a passo completo

### 4. **App Atualizado**
- ✅ `lib/pages/auth_page.dart` - URLs atualizadas para wegig.com.br

---

## 🚀 Próximos Passos (Você precisa fazer):

### **1. Commit e Push para GitHub** (5 minutos)
```bash
cd /Users/wagneroliveira/to_sem_banda

git add docs/ scripts/convert_markdown_to_html.py TERMS_OF_SERVICE.md PRIVACY_POLICY.md DEPLOY_GUIDE_WEGIG.md lib/pages/auth_page.dart

git commit -m "Add website files for wegig.com.br"

git push origin main
```

### **2. Ativar GitHub Pages** (2 minutos)
1. Acesse: https://github.com/wagnermecanica-code/ToSemBandaRepo/settings/pages
2. Source: `main` branch → `/docs` folder
3. Clique em **Save**
4. Site temporário: https://wagnermecanica-code.github.io/ToSemBandaRepo/

### **3. Configurar DNS no Registro.br** (10 minutos)
Acesse painel do Registro.br e adicione:

**Registros A (APEX):**
```
A  @  185.199.108.153
A  @  185.199.109.153
A  @  185.199.110.153
A  @  185.199.111.153
```

**Registro CNAME (WWW):**
```
CNAME  www  wagnermecanica-code.github.io.
```

### **4. Adicionar Custom Domain no GitHub** (1 minuto)
1. GitHub Pages settings → Custom domain
2. Digite: `wegig.com.br`
3. Save
4. Ative: ☑️ Enforce HTTPS

### **5. Aguardar Propagação DNS** (1-24 horas)
- Teste em: https://www.whatsmydns.net/#A/wegig.com.br
- Quando propagar: wegig.com.br estará online!

---

## 🎯 URLs Finais:

Após configuração completa:
- 🏠 **Homepage**: https://wegig.com.br
- 📄 **Termos**: https://wegig.com.br/termos.html
- 🔒 **Privacidade**: https://wegig.com.br/privacidade.html

---

## 📋 Estrutura Criada:

```
to_sem_banda/
├── docs/                          # 🆕 Site (GitHub Pages)
│   ├── index.html                 # Homepage
│   ├── termos.html                # Termos (gerado)
│   ├── privacidade.html           # Privacidade (gerado)
│   ├── style.css                  # CSS global
│   ├── CNAME                      # wegig.com.br
│   ├── _config.yml                # Jekyll config
│   └── README.md                  # Docs do site
│
├── scripts/
│   └── convert_markdown_to_html.py  # 🆕 Conversor MD→HTML
│
├── lib/pages/
│   └── auth_page.dart             # ✏️ URLs atualizadas
│
├── TERMS_OF_SERVICE.md            # ✅ Já existia
├── PRIVACY_POLICY.md              # ✅ Já existia
└── DEPLOY_GUIDE_WEGIG.md          # 🆕 Guia completo
```

---

## ✨ Destaques dos Documentos Legais:

### **Termos de Uso:**
- ✅ Seção específica de **Geolocalização** (3.1-3.4)
  - Como funciona (GPS, GeoPoint, geocodificação)
  - Dados armazenados (lat/lng, cidade, distância)
  - Consentimento expresso para uso público
  - Controles do usuário (alterar, deletar, desativar notificações)

- ✅ Seção específica de **Multi-Perfil** (4.1-4.4)
  - Arquitetura Instagram-Style (até 5 perfis)
  - Isolamento total de dados
  - Firestore Security Rules explicadas
  - Limites e restrições

- ✅ **Consentimento Expresso** (Seção 13)
  - Checkbox ao cadastrar = acordo com todos os termos
  - Lista explícita do que usuário concorda

### **Política de Privacidade:**
- ✅ Conformidade **LGPD/GDPR/CCPA**
- ✅ Tabela detalhada de dados de **Geolocalização** (Seção 3.3)
  - Precisão: ~11cm (6 casas decimais)
  - Visibilidade: Público vs Privado
  - Retenção: Enquanto perfil existir

- ✅ Seção **Multi-Perfil** com diagrama (Seção 6)
  - Estrutura de dados Firestore
  - Garantias de isolamento
  - Dados compartilhados vs isolados

- ✅ **Todos os 7 direitos LGPD** implementados (Seção 9)
  - Acesso, Correção, Eliminação, Portabilidade, etc.
  - Como exercer cada direito (via app ou email)

---

## 🎨 Design do Site:

**Cores:**
- Primary: `#00A699` (Teal - Musicians)
- Secondary: `#FF6B6B` (Coral - Bands)
- Dark: `#2C3E50`
- Light: `#ECF0F1`

**Seções da Homepage:**
1. Hero (gradiente Teal → Coral)
2. Sobre o WeGig
3. Funcionalidades (6 cards)
4. Download (App Store + Google Play)
5. Informações Legais (links para Termos/Privacidade)
6. Footer (4 colunas)

**Responsivo:** ✅ Mobile, Tablet, Desktop

---

## 🔄 Manutenção Futura:

Para atualizar documentos legais:
```bash
# 1. Edite Markdown
vim TERMS_OF_SERVICE.md

# 2. Reconverta
python3 scripts/convert_markdown_to_html.py

# 3. Push
git add . && git commit -m "Update terms" && git push
```

GitHub Pages atualiza automaticamente em ~1 minuto!

---

## 📞 Contato/Suporte:

**No site (após deploy):**
- Suporte: suporte@wegig.com.br
- Privacidade: privacidade@wegig.com.br
- DPO: dpo@wegig.com.br

**GitHub Pages:**
- Docs: https://docs.github.com/en/pages

**Registro.br:**
- Suporte: https://registro.br/suporte/
- Tel: (11) 5509-3500

---

## ✅ Status Atual:

- [x] Site criado (HTML/CSS)
- [x] Documentos legais convertidos (MD → HTML)
- [x] URLs no app atualizadas
- [x] CNAME configurado
- [x] Script de conversão criado
- [x] Guia de deploy escrito
- [ ] **Você precisa:** Commit + Push + Ativar GitHub Pages + DNS

---

**🎉 Tudo pronto! Siga o `DEPLOY_GUIDE_WEGIG.md` para colocar no ar.**

**Tempo estimado total:** 30 minutos (configuração) + até 24h (propagação DNS)
