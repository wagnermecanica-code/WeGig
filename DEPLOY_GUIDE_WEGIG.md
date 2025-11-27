# Guia de Deploy: wegig.com.br com GitHub Pages

**Data:** 27 de novembro de 2025  
**Domínio:** wegig.com.br  
**Objetivo:** Hospedar site institucional + documentos legais

---

## 📋 Checklist Rápido

- [ ] 1. Executar script de conversão Markdown → HTML
- [ ] 2. Commit e push dos arquivos `docs/`
- [ ] 3. Ativar GitHub Pages
- [ ] 4. Configurar DNS no Registro.br
- [ ] 5. Adicionar custom domain no GitHub
- [ ] 6. Aguardar propagação DNS (24h)
- [ ] 7. Ativar HTTPS
- [ ] 8. Testar todos os links
- [ ] 9. Atualizar app (opcional)

---

## 🚀 Passo a Passo Detalhado

### **Passo 1: Gerar Arquivos HTML** ✅ FEITO

```bash
cd /Users/wagneroliveira/to_sem_banda
python3 scripts/convert_markdown_to_html.py
```

**Resultado:**
- ✅ `docs/termos.html` criado
- ✅ `docs/privacidade.html` criado

---

### **Passo 2: Commit e Push para GitHub**

```bash
# Verificar arquivos criados
ls -la docs/

# Adicionar ao Git
git add docs/
git add lib/pages/auth_page.dart
git add TERMS_OF_SERVICE.md
git add PRIVACY_POLICY.md

# Commit
git commit -m "Add website files for wegig.com.br

- Created docs/ folder with website files
- Converted TERMS_OF_SERVICE.md and PRIVACY_POLICY.md to HTML
- Updated auth_page.dart URLs to wegig.com.br
- Added CNAME file for custom domain
- Ready for GitHub Pages deployment"

# Push para GitHub
git push origin main
```

---

### **Passo 3: Ativar GitHub Pages**

1. **Acesse o repositório no GitHub:**
   ```
   https://github.com/wagnermecanica-code/ToSemBandaRepo
   ```

2. **Vá em Settings → Pages:**
   ```
   https://github.com/wagnermecanica-code/ToSemBandaRepo/settings/pages
   ```

3. **Configure Source:**
   - **Branch:** `main`
   - **Folder:** `/docs`
   - Clique em **Save**

4. **Aguarde build (1-2 minutos)**

5. **Site estará disponível em:**
   ```
   https://wagnermecanica-code.github.io/ToSemBandaRepo/
   ```

---

### **Passo 4: Configurar DNS no Registro.br**

#### **Acesse o painel do Registro.br:**
```
https://registro.br/
```

#### **Adicione os seguintes registros DNS:**

**A. Registros A (APEX domain - wegig.com.br):**
```
Tipo  | Host | Valor
------|------|------------------
A     | @    | 185.199.108.153
A     | @    | 185.199.109.153
A     | @    | 185.199.110.153
A     | @    | 185.199.111.153
```

**B. Registro CNAME (WWW subdomain):**
```
Tipo  | Host | Valor
------|------|--------------------------------
CNAME | www  | wagnermecanica-code.github.io
```

**C. Registro TXT (Verificação - opcional):**
```
Tipo | Host | Valor
-----|------|--------------------------------
TXT  | @    | github-pages-verification=xxx
```
(Código será fornecido pelo GitHub após configurar custom domain)

#### **Comandos para verificar DNS (após configurar):**

```bash
# Verificar registros A
dig wegig.com.br +short

# Verificar CNAME
dig www.wegig.com.br +short

# Verificar propagação global
# https://www.whatsmydns.net/#A/wegig.com.br
```

---

### **Passo 5: Adicionar Custom Domain no GitHub**

1. **Acesse GitHub Pages settings:**
   ```
   https://github.com/wagnermecanica-code/ToSemBandaRepo/settings/pages
   ```

2. **Em "Custom domain", digite:**
   ```
   wegig.com.br
   ```

3. **Clique em "Save"**

4. **Aguarde verificação DNS:**
   - ✅ Símbolo verde: DNS configurado corretamente
   - ⚠️ Amarelo: Aguardando propagação (pode levar até 24h)
   - ❌ Vermelho: Erro na configuração

5. **Após verificação bem-sucedida, ative:**
   - ☑️ **Enforce HTTPS** (altamente recomendado)

---

### **Passo 6: Aguardar Propagação DNS**

**Tempo estimado:** 1 minuto a 24 horas (geralmente 1-4 horas)

**Ferramentas para monitorar:**

1. **WhatsMyDNS (global):**
   ```
   https://www.whatsmydns.net/#A/wegig.com.br
   ```

2. **DNS Checker:**
   ```
   https://dnschecker.org/all-dns-records-of-domain.php?query=wegig.com.br
   ```

3. **Terminal (local):**
   ```bash
   # Mac/Linux
   dig wegig.com.br
   nslookup wegig.com.br
   
   # Limpar cache DNS local
   sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
   ```

---

### **Passo 7: Testar o Site**

Após propagação DNS completa, teste:

**A. Homepage:**
```
✅ https://wegig.com.br
✅ https://www.wegig.com.br
✅ http://wegig.com.br (redireciona para HTTPS)
```

**B. Documentos Legais:**
```
✅ https://wegig.com.br/termos.html
✅ https://wegig.com.br/privacidade.html
```

**C. Links no App:**
- Abra o app WeGig
- Vá para tela de cadastro
- Clique em "termos de uso" → Deve abrir `https://wegig.com.br/termos.html`
- Clique em "política de privacidade" → Deve abrir `https://wegig.com.br/privacidade.html`

**D. Responsividade:**
```
✅ Desktop (Chrome, Safari, Firefox)
✅ Mobile (iOS Safari, Android Chrome)
✅ Tablet (iPad, Android)
```

---

## 🔧 Configuração DNS Detalhada (Registro.br)

### **Interface Registro.br - Passo a Passo:**

1. **Login no Registro.br:**
   ```
   https://registro.br/
   → Entrar
   → Email/senha ou conta gov.br
   ```

2. **Selecionar domínio:**
   ```
   → Meus domínios
   → wegig.com.br
   → Gerenciar
   ```

3. **Acessar configurações DNS:**
   ```
   → DNS
   → Editar Zona
   ```

4. **Adicionar registros A (4 registros):**
   ```
   Tipo: A
   Nome: @ (ou deixe vazio)
   Valor: 185.199.108.153
   TTL: 3600 (ou padrão)
   
   Repetir para:
   - 185.199.109.153
   - 185.199.110.153
   - 185.199.111.153
   ```

5. **Adicionar registro CNAME:**
   ```
   Tipo: CNAME
   Nome: www
   Valor: wagnermecanica-code.github.io.
   TTL: 3600
   ```
   
   **⚠️ IMPORTANTE:** Note o ponto final (`.`) no final do valor CNAME!

6. **Salvar alterações:**
   ```
   → Salvar
   → Confirmar
   ```

7. **Aguardar propagação:**
   ```
   Tempo: 1-24 horas
   Verifique com: dig wegig.com.br
   ```

---

## 🛠️ Troubleshooting

### **Problema 1: Site não carrega após 24h**

**Diagnóstico:**
```bash
dig wegig.com.br +short
# Esperado: 185.199.108.153, 185.199.109.153, 185.199.110.153, 185.199.111.153
```

**Soluções:**
1. Verifique se registros A foram salvos no Registro.br
2. Aguarde mais tempo (às vezes leva 48h)
3. Limpe cache DNS local: `sudo dscacheutil -flushcache`
4. Tente em modo anônimo ou outro dispositivo

---

### **Problema 2: "Domain's DNS record could not be retrieved" no GitHub**

**Diagnóstico:**
```bash
dig wegig.com.br
# Se retornar vazio ou IP antigo, DNS não configurado corretamente
```

**Soluções:**
1. Verifique se registros A apontam para IPs corretos (185.199.108-111.153)
2. Remova registros DNS antigos/conflitantes no Registro.br
3. Aguarde propagação (24h)
4. Tente remover e re-adicionar custom domain no GitHub

---

### **Problema 3: CSS/imagens não carregam**

**Diagnóstico:**
- Abra Developer Tools (F12)
- Verifique Console para erros 404

**Soluções:**
1. Verifique se `docs/style.css` existe no repositório
2. Use paths relativos (`style.css`, não `/style.css`)
3. Force refresh: Ctrl+Shift+R (Windows) ou Cmd+Shift+R (Mac)
4. Limpe cache do navegador

---

### **Problema 4: HTTPS não funciona**

**Diagnóstico:**
- Tentativa de acesso via HTTPS retorna erro de certificado

**Soluções:**
1. Aguarde até 24h após ativar "Enforce HTTPS" no GitHub
2. Verifique se DNS propagou corretamente
3. Desative e reative "Enforce HTTPS" no GitHub
4. Se persistir, remova e re-adicione custom domain

---

### **Problema 5: WWW não funciona**

**Diagnóstico:**
```bash
dig www.wegig.com.br +short
# Esperado: wagnermecanica-code.github.io.
```

**Soluções:**
1. Verifique registro CNAME no Registro.br
2. Certifique-se que valor é `wagnermecanica-code.github.io.` (com ponto final)
3. Aguarde propagação DNS

---

## 📱 Atualizar App (Opcional)

Se quiser atualizar o app para usar novos URLs:

```bash
# Já foi feito automaticamente, mas para confirmar:
grep -n "wegig.com.br" lib/pages/auth_page.dart

# Linhas ~650 e ~669 devem conter:
# https://wegig.com.br/termos.html
# https://wegig.com.br/privacidade.html
```

**Rebuild do app:**
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🔄 Atualizar Documentos Legais no Futuro

Quando precisar atualizar Termos ou Política de Privacidade:

```bash
# 1. Edite os arquivos Markdown na raiz
vim TERMS_OF_SERVICE.md
vim PRIVACY_POLICY.md

# 2. Reconverta para HTML
python3 scripts/convert_markdown_to_html.py

# 3. Commit e push
git add TERMS_OF_SERVICE.md PRIVACY_POLICY.md docs/
git commit -m "Update legal documents - [descrição da mudança]"
git push origin main

# 4. GitHub Pages atualiza automaticamente em ~1 minuto
```

---

## ✅ Checklist Final

Após deploy completo, verifique:

- [ ] ✅ `https://wegig.com.br` carrega homepage
- [ ] ✅ `https://www.wegig.com.br` redireciona para `https://wegig.com.br`
- [ ] ✅ `https://wegig.com.br/termos.html` carrega Termos de Uso
- [ ] ✅ `https://wegig.com.br/privacidade.html` carrega Política de Privacidade
- [ ] ✅ Links no app (`auth_page.dart`) abrem documentos corretos
- [ ] ✅ HTTPS ativado (cadeado verde no navegador)
- [ ] ✅ CSS carrega corretamente (site estilizado)
- [ ] ✅ Site responsivo (teste em mobile)
- [ ] ✅ DNS propagado globalmente (teste em whatsmydns.net)
- [ ] ✅ Certificado SSL válido (não expira nos próximos 90 dias)

---

## 📞 Suporte

**Problemas com GitHub Pages:**
- Documentação: https://docs.github.com/en/pages
- Community: https://github.community/

**Problemas com Registro.br:**
- Suporte: https://registro.br/suporte/
- Telefone: (11) 5509-3500

**Problemas com o site:**
- Email: suporte@wegig.com.br

---

**✨ Deploy completo! Site estará no ar em até 24 horas após configuração DNS.**
