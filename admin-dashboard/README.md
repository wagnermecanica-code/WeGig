# WeGig Admin Dashboard

Dashboard administrativo para gerenciar denúncias e moderar conteúdo do WeGig.

## 🚀 Funcionalidades

- **Visualização de Denúncias**: Lista todas as denúncias com filtros por status e prioridade
- **Notificações em Tempo Real**: Atualização automática quando novas denúncias chegam
- **Marcação como Lida**: Gerencie o status das denúncias
- **Estatísticas**: Visão geral de denúncias não lidas e de alta prioridade

## 📋 Pré-requisitos

- Node.js 18+
- Conta Firebase com acesso ao projeto `to-sem-banda-83e19`
- Conta SendGrid configurada (para notificações por email)

## 🛠️ Instalação

1. **Instalar dependências:**

   ```bash
   cd admin-dashboard
   npm install
   ```

2. **Configurar Firebase:**

   - Edite `src/firebase.js`
   - Substitua as credenciais do Firebase pelas reais do projeto

3. **Executar em desenvolvimento:**

   ```bash
   npm run dev
   ```

4. **Build para produção:**
   ```bash
   npm run build
   ```

## 🔐 Autenticação

O dashboard usa autenticação Firebase. Para acessar:

1. **Criar usuário admin no Firebase Console:**

   - Authentication > Users > Add User
   - Email: `admin@wegig.app`
   - Senha: (definir senha segura)

2. **Configurar regras de segurança:**
   - O dashboard lê apenas a coleção `adminNotifications`
   - Certifique-se de que o usuário admin tenha acesso de leitura

## 📧 Notificações por Email

As notificações por email são enviadas automaticamente via SendGrid quando:

- Uma nova denúncia é criada
- O total de denúncias para um item atinge 3 ou mais

### Configuração do SendGrid:

1. **Executar script de configuração:**

   ```bash
   bash .config/functions/setup_sendgrid.sh
   ```

2. **Verificar domínio no SendGrid:**
   - Adicionar `wegig.app` como domínio verificado
   - Configurar SPF/DKIM para melhor deliverability

## 📊 Estrutura dos Dados

### Coleção `adminNotifications`

```javascript
{
  type: "new_report",
  reportId: "...",
  targetType: "post" | "profile",
  targetId: "...",
  reason: "spam" | "harassment" | etc,
  description: "...",
  totalReports: 5,
  timestamp: Timestamp,
  read: false,
  priority: "high" | "normal"
}
```

## 🎯 Próximos Passos

- [ ] Adicionar filtros avançados (por data, tipo, etc.)
- [ ] Implementar ações de moderação (banir usuário, remover post)
- [ ] Adicionar gráficos e métricas
- [ ] Sistema de resolução de denúncias
- [ ] Notificações push para admins

## 🔧 Desenvolvimento

### Scripts Disponíveis

- `npm run dev` - Inicia servidor de desenvolvimento
- `npm run build` - Build para produção
- `npm run preview` - Preview do build
- `npm run lint` - Executa linter

### Estrutura do Projeto

```
admin-dashboard/
├── src/
│   ├── components/
│   │   ├── Login.jsx
│   │   └── Dashboard.jsx
│   ├── firebase.js
│   ├── App.jsx
│   └── main.jsx
├── index.html
├── package.json
└── vite.config.js
```

## 🚀 Deploy

Para fazer deploy do dashboard:

1. **Build da aplicação:**

   ```bash
   npm run build
   ```

2. **Hospedar os arquivos:**
   - Upload da pasta `dist/` para seu servidor web
   - Ou usar Firebase Hosting, Vercel, Netlify, etc.

## 📞 Suporte

Para dúvidas ou problemas, entre em contato com a equipe de desenvolvimento.
