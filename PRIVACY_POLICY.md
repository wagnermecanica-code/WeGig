# Política de Privacidade - WeGig (Tô Sem Banda)

**Última atualização:** 27 de novembro de 2025  
**Versão:** 1.0  
**URL:** https://tosembanda.com/privacidade

---

## 1. Introdução

Esta Política de Privacidade descreve como o WeGig ("nós", "nosso", "Plataforma") coleta, usa, armazena e protege os dados pessoais de nossos usuários ("você", "seu"), em conformidade com:

- **Lei Geral de Proteção de Dados (LGPD)** - Lei nº 13.709/2018 (Brasil)
- **General Data Protection Regulation (GDPR)** - Regulamento (UE) 2016/679 (União Europeia)
- **California Consumer Privacy Act (CCPA)** - EUA

**Ao criar uma conta no WeGig, você consente expressamente com:**

1. Coleta e processamento de seus **dados de geolocalização em tempo real**
2. Funcionamento do **sistema de múltiplos perfis** e isolamento de dados
3. Armazenamento de dados em Firebase Cloud Firestore (Google Cloud Platform)
4. Uso de Google Maps API para visualização de mapas e cálculo de distâncias

---

## 2. Controlador de Dados e Encarregado (DPO)

**Controlador de Dados:**  
Wagner Oliveira  
Email: privacidade@tosembanda.com  
Endereço: [A ser definido quando empresa for formalizada]

**Encarregado de Dados (DPO/Responsável LGPD):**  
Wagner Oliveira  
Email: dpo@tosembanda.com  
Telefone: [A ser definido]

**Para exercer seus direitos:** Entre em contato via email acima ou exclua sua conta através das Configurações do App.

---

## 3. Dados Coletados

### 3.1. Dados de Cadastro (Obrigatórios)

Ao criar uma conta, coletamos:

| Dado                | Finalidade                                       | Base Legal (LGPD)                |
| ------------------- | ------------------------------------------------ | -------------------------------- |
| **Email**           | Autenticação, recuperação de senha, comunicações | Execução de contrato (Art. 7, V) |
| **Senha** (hash)    | Segurança da conta                               | Execução de contrato (Art. 7, V) |
| **UID Firebase**    | Identificação única do usuário                   | Execução de contrato (Art. 7, V) |
| **Data de criação** | Auditoria, análise de crescimento                | Legítimo interesse (Art. 7, IX)  |

**Autenticação Opcional (OAuth2):**

- **Google Sign-In**: Nome, email, foto (se autorizado)
- **Sign In with Apple**: Email (pode ser oculto/anônimo), nome

### 3.2. Dados de Perfil (Sistema Multi-Perfil)

Cada usuário pode criar até **5 perfis** independentes. Para cada perfil, coletamos:

| Dado                           | Obrigatório | Finalidade                                    | Base Legal                             |
| ------------------------------ | ----------- | --------------------------------------------- | -------------------------------------- |
| **Nome do perfil**             | ✅ Sim      | Identificação pública                         | Consentimento (Art. 7, I)              |
| **Tipo** (Músico/Banda)        | ✅ Sim      | Categorização, busca                          | Consentimento (Art. 7, I)              |
| **Localização (GeoPoint)**     | ✅ Sim      | Busca geográfica, notificações de proximidade | **Consentimento expresso** (Art. 7, I) |
| **Cidade**                     | ✅ Sim      | Exibição pública, filtros                     | Consentimento (Art. 7, I)              |
| **Bairro**                     | ❌ Não      | Precisão de localização                       | Consentimento (Art. 7, I)              |
| **Estado**                     | ❌ Não      | Estatísticas regionais                        | Consentimento (Art. 7, I)              |
| **Foto do perfil**             | ❌ Não      | Identificação visual                          | Consentimento (Art. 7, I)              |
| **Instrumentos** (array)       | ✅ Sim      | Busca por habilidade                          | Consentimento (Art. 7, I)              |
| **Gêneros musicais** (array)   | ✅ Sim      | Busca por estilo                              | Consentimento (Art. 7, I)              |
| **Nível** (iniciante/avançado) | ❌ Não      | Compatibilidade                               | Consentimento (Art. 7, I)              |
| **Bio** (110 chars)            | ❌ Não      | Descrição pessoal                             | Consentimento (Art. 7, I)              |
| **Idade**                      | ❌ Não      | Estatísticas                                  | Consentimento (Art. 7, I)              |
| **YouTube link**               | ❌ Não      | Portfolio                                     | Consentimento (Art. 7, I)              |
| **Instagram**                  | ❌ Não      | Redes sociais                                 | Consentimento (Art. 7, I)              |
| **TikTok**                     | ❌ Não      | Redes sociais                                 | Consentimento (Art. 7, I)              |

**Estrutura de Armazenamento (Firebase Firestore):**

```
users/{uid}:
  email: "usuario@email.com"
  createdAt: Timestamp
  activeProfileId: "profile_123"
  profiles: [
    { profileId: "profile_123", name: "João Silva", photo: "url", type: "musician", city: "São Paulo" }
  ]

profiles/{profileId}:
  uid: "firebase_uid_xyz"
  name: "João Silva"
  isBand: false
  location: GeoPoint(-23.5505199, -46.6333094)  # ⚠️ DADO SENSÍVEL
  city: "São Paulo"
  neighborhood: "Vila Mariana"
  state: "SP"
  photoUrl: "https://storage.googleapis.com/..."
  instruments: ["Guitarra", "Baixo"]
  genres: ["Rock", "Blues"]
  level: "Avançado"
  bio: "Guitarrista com 10 anos de experiência..."
  age: 28
  youtubeLink: "https://youtube.com/..."
  instagramHandle: "@joaosilva"
  tiktokHandle: "@joaosilva"
  createdAt: Timestamp
  updatedAt: Timestamp
```

### 3.3. Dados de Geolocalização (⚠️ CRÍTICO)

**Como Coletamos:**

1. **Permissão do dispositivo**: Solicitamos acesso a GPS/Location Services
2. **Google Places API**: Autocomplete de endereços durante cadastro/edição
3. **Geocodificação reversa**: Convertemos coordenadas em cidade/bairro
4. **Armazenamento**: Salvamos GeoPoint (latitude/longitude) no Firestore

**Dados de Localização Armazenados:**

| Dado                                  | Precisão                 | Visibilidade              | Retenção                  |
| ------------------------------------- | ------------------------ | ------------------------- | ------------------------- |
| **GeoPoint (lat/lng)**                | ~11cm (6 casas decimais) | 🔒 Privado (backend only) | Enquanto perfil existir   |
| **Cidade**                            | Municipal                | 🌐 Público                | Enquanto perfil existir   |
| **Bairro**                            | ~1km                     | 🌐 Público                | Enquanto perfil existir   |
| **Distância calculada**               | ~100m                    | 🌐 Público (ex: "2.5km")  | Calculado em tempo real   |
| **Histórico de localização de posts** | Por post                 | 🌐 Público                | 30 dias (expira com post) |

**⚠️ IMPORTANTE:**

- Suas coordenadas **exatas** não são exibidas na interface do app
- Outros usuários veem apenas: **"São Paulo, Vila Mariana - 2.5km"**
- Não rastreamos seu movimento (apenas localização estática de perfil/post)
- Você pode alterar localização a qualquer momento editando o perfil

**Finalidades de Uso:**

1. **Busca geográfica**: Encontrar posts/perfis dentro de raio de X km
2. **Notificações de proximidade**: Alertar sobre posts próximos (se ativado)
3. **Cálculo de distância**: Exibir "João Silva - 2.5km" nos cards
4. **Estatísticas regionais**: Análise de densidade de usuários por cidade (dados anonimizados)
5. **Prevenção de fraude**: Detectar perfis com localizações suspeitas (ex: 0,0)

### 3.4. Dados de Uso (Posts, Mensagens, Interações)

**Posts (Efêmeros - 30 dias):**

- authorUid, authorProfileId, authorName, authorPhotoUrl
- type: 'musician' | 'band'
- location: GeoPoint ⚠️
- city, neighborhood, state
- instruments, genres, level, description (max 1000 chars)
- seekingMusicians (para bandas): array de tipos procurados
- photoUrl (opcional)
- youtubeLink (opcional)
- expiresAt: Timestamp (createdAt + 30 dias)
- createdAt, updatedAt

**Mensagens (Chat):**

- conversationId (entre 2 profileIds)
- senderId, recipientId (profileIds)
- text, timestamp
- read: boolean
- Retenção: Enquanto conversa não for deletada por ambos os participantes

**Interesses:**

- postId, interestedUid, interestedProfileId
- createdAt
- Retenção: 30 dias (expira com post) ou até deleção manual

**Notificações:**

- type: 'interest', 'newMessage', 'nearbyPost', etc.
- recipientProfileId ⚠️
- senderProfileId, postId (quando aplicável)
- message, createdAt, expiresAt
- read: boolean
- Retenção: 30 dias (alguns tipos) ou permanente (outros)

### 3.5. Dados Técnicos e Metadados

Coletamos automaticamente:

- **Endereço IP**: Segurança, prevenção de fraude (não armazenado permanentemente)
- **User-Agent**: Tipo de dispositivo, SO, versão do app
- **Logs de acesso**: Timestamp, ação realizada (criação de post, login, etc.)
- **Firebase Analytics**: Eventos de uso (não identifica usuário individual)
- **Crashlytics**: Relatórios de erros (anonimizados)

**Retenção de Logs:** 90 dias (exceto logs de auditoria obrigatórios: 6 meses)

### 3.6. Dados NÃO Coletados

❌ **Não coletamos:**

- Números de telefone (não é obrigatório)
- Documentos (CPF, RG, passaporte)
- Dados biométricos (impressões digitais, reconhecimento facial)
- Rastreamento contínuo de localização (apenas estático em perfil/post)
- Gravações de áudio/vídeo sem consentimento explícito
- Dados de pagamento (app é gratuito, sem in-app purchases)

---

## 4. Como Usamos Seus Dados

### 4.1. Finalidades Específicas

| Finalidade                      | Dados Usados                                 | Base Legal LGPD                  |
| ------------------------------- | -------------------------------------------- | -------------------------------- |
| **Autenticação**                | Email, senha (hash), UID                     | Execução de contrato (Art. 7, V) |
| **Busca geográfica**            | GeoPoint, city, instruments, genres          | Consentimento (Art. 7, I)        |
| **Notificações de proximidade** | GeoPoint, notification settings              | Consentimento (Art. 7, I)        |
| **Sistema de múltiplos perfis** | activeProfileId, profiles summary            | Execução de contrato (Art. 7, V) |
| **Chat em tempo real**          | conversationId, messages, profileIds         | Execução de contrato (Art. 7, V) |
| **Demonstração de interesse**   | postId, interestedProfileId                  | Consentimento (Art. 7, I)        |
| **Recomendações**               | Histórico de interesses, genres, instruments | Legítimo interesse (Art. 7, IX)  |
| **Prevenção de fraude**         | IP, logs de acesso, padrões de uso           | Legítimo interesse (Art. 7, IX)  |
| **Melhoria do serviço**         | Firebase Analytics (anonimizado)             | Legítimo interesse (Art. 7, IX)  |
| **Suporte técnico**             | Email, logs de erro (Crashlytics)            | Execução de contrato (Art. 7, V) |

### 4.2. Processamento Automatizado

**Algoritmos de Busca:**

- Cálculo de distância Haversine (lat/lng → km)
- Filtros combinados (instrumentos AND gêneros AND raio)
- Ordenação por proximidade (distância crescente)

**Notificações Inteligentes:**

- Cloud Function `notifyNearbyPosts`: Dispara ao criar post
- Verifica perfis dentro do raio configurado (0-100km)
- Filtra por interesses compatíveis (instruments/genres match)
- Envia notificação apenas se match > 50%

**Você NÃO está sujeito a decisões automatizadas que produzam efeitos jurídicos** (LGPD Art. 20). Todas as conexões/interações dependem de ação humana (você decide demonstrar interesse, enviar mensagem, etc).

---

## 5. Compartilhamento de Dados

### 5.1. Com Terceiros (Subprocessadores)

**Firebase (Google Cloud Platform):**

- **Finalidade**: Armazenamento de dados, autenticação, notificações push
- **Dados compartilhados**: Todos os dados descritos na seção 3
- **Localização**: Servidores em `southamerica-east1` (São Paulo, Brasil)
- **Contrato**: DPA (Data Processing Agreement) assinado com Google
- **Conformidade**: LGPD, GDPR, ISO 27001, SOC 2

**Google Maps Platform:**

- **Finalidade**: Autocomplete de endereços, visualização de mapas
- **Dados compartilhados**: Cidade/endereço digitado (não coordenadas exatas)
- **Privacidade**: [Termos do Google Maps](https://cloud.google.com/maps-platform/terms)

**Firebase Cloud Messaging (FCM):**

- **Finalidade**: Envio de notificações push
- **Dados compartilhados**: FCM token (identificador anônimo), profileId
- **Não compartilhamos**: Conteúdo de mensagens/posts

### 5.2. NÃO Compartilhamos com Terceiros

❌ **Não vendemos, alugamos ou compartilhamos seus dados com:**

- Anunciantes (app não tem anúncios)
- Data brokers (corretores de dados)
- Redes sociais (exceto se você usar OAuth2 para login)
- Empresas de marketing

### 5.3. Divulgação Legal

Podemos divulgar dados se **legalmente obrigados**:

- Ordem judicial (mandado de busca e apreensão)
- Requisição de autoridade policial (com processo formal)
- Cumprimento de lei federal/estadual
- Proteção de direitos, segurança e propriedade (ex: investigação de fraude)

**Notificaremos você** sempre que possível, exceto se proibido por lei.

---

## 6. Sistema de Múltiplos Perfis (Isolamento de Dados)

### 6.1. Como Funciona

O WeGig implementa **isolamento de dados por perfil**, semelhante ao Instagram:

```
Usuário A (uid: user_123)
├─ Perfil 1: "João Silva" (musician)
│  ├─ Posts: 5 posts ativos
│  ├─ Conversas: 3 chats
│  ├─ Notificações: 12 não lidas
│  └─ Localização: São Paulo, Vila Mariana
│
├─ Perfil 2: "The Rock Band" (band)
│  ├─ Posts: 2 posts ativos
│  ├─ Conversas: 1 chat
│  ├─ Notificações: 5 não lidas
│  └─ Localização: São Paulo, Centro
│
└─ Perfil 3: "Maria Santos" (musician)
   ├─ Posts: 0 posts
   ├─ Conversas: 0 chats
   ├─ Notificações: 0
   └─ Localização: Rio de Janeiro, Copacabana
```

### 6.2. Privacidade e Isolamento

✅ **Garantias de Privacidade:**

1. **Isolamento total**: Dados de um perfil não são visíveis em outro
2. **activeProfileId**: Apenas 1 perfil ativo por vez (armazenado em `users/{uid}`)
3. **Troca de contexto**: Ao trocar perfil, app recarrega dados do novo perfil
4. **Firestore Security Rules**: Validam propriedade por `authorProfileId`
5. **Anonimato**: Impossível descobrir que 2 perfis pertencem ao mesmo usuário (a menos que você revele)

✅ **Dados Isolados por Perfil:**

- Posts criados (authorProfileId)
- Conversas (participantProfileIds)
- Notificações recebidas (recipientProfileId)
- Interesses demonstrados (interestedProfileId)
- Badge counters (unread counts)

✅ **Dados Compartilhados (Nível de Usuário):**

- Email de cadastro (único para todos os perfis)
- UID Firebase (identificador global)
- Histórico de login/logout (auditoria)
- Configurações gerais (idioma, tema - futuro)

### 6.3. Implicações de Privacidade

⚠️ **IMPORTANTE:**

- Ao trocar de perfil, você **não pode** acessar mensagens/posts de outros perfis seus
- Se você revelar publicamente que "João Silva" e "The Rock Band" são seus, não podemos impedir outros de fazerem essa conexão
- Deletar perfil é **permanente** - posts órfãos permanecem mas sem vínculo editável
- Outros usuários podem salvar screenshots de conversas antes de você deletar

---

## 7. Segurança de Dados

### 7.1. Medidas Técnicas

**Criptografia:**

- 🔒 **Em trânsito**: TLS 1.3 (HTTPS) para todas as comunicações
- 🔒 **Em repouso**: AES-256 (Firebase Firestore padrão)
- 🔒 **Senhas**: Bcrypt hash com salt (Firebase Auth)

**Controles de Acesso:**

- Firestore Security Rules (profile-level ownership validation)
- Firebase Auth tokens (JWT) com expiração de 1 hora
- Rate limiting: 3 tentativas de login por minuto (client-side)
- Cloud Functions rate limiting: 20 posts/dia, 50 interesses/dia

**Backup e Recuperação:**

- Backup automático diário (Firebase Firestore)
- Ponto de restauração: até 7 dias anteriores
- Dados deletados: backups retidos por 90 dias (recuperação de emergência)

### 7.2. Medidas Organizacionais

**Acesso Interno:**

- Apenas desenvolvedor (Wagner Oliveira) tem acesso a dados de produção
- Acesso via Firebase Console (logs auditados)
- Sem acesso direto a senhas (apenas hashes)
- Acesso a dados reais apenas para debugging crítico (com consentimento)

**Auditoria:**

- Logs de acesso administrativo (Firebase Audit Logs)
- Revisão mensal de Security Rules
- Testes de segurança trimestrais (penetration testing)

### 7.3. Incidentes de Segurança

**Em caso de vazamento de dados:**

1. Notificação à ANPD (Autoridade Nacional de Proteção de Dados) em **72 horas**
2. Notificação a usuários afetados via email/notificação in-app
3. Descrição do incidente, dados comprometidos e medidas tomadas
4. Assistência gratuita (ex: monitoramento de crédito se CPF vazado)

**Histórico:** Nenhum incidente de segurança registrado até 27/11/2025.

---

## 8. Retenção de Dados

### 8.1. Período de Armazenamento

| Tipo de Dado                     | Período de Retenção | Motivo                                                 |
| -------------------------------- | ------------------- | ------------------------------------------------------ |
| **Conta ativa**                  | Indefinido          | Enquanto você usar o serviço                           |
| **Posts**                        | 30 dias             | Auto-expiração (expiresAt)                             |
| **Mensagens**                    | Indefinido          | Até deleção manual por ambos os participantes          |
| **Notificações**                 | 7-30 dias           | Varia por tipo (nearbyPost: 7 dias, interest: 30 dias) |
| **Logs de acesso**               | 90 dias             | Segurança e debugging                                  |
| **Logs de auditoria**            | 6 meses             | Obrigação legal (LGPD Art. 46)                         |
| **Dados após exclusão de conta** | 90 dias (backup)    | Recuperação de emergência                              |
| **Dados anonimizados**           | 5 anos              | Estatísticas agregadas (sem identificação pessoal)     |

### 8.2. Deleção Automática

**Posts Efêmeros:**

- Cloud Function `cleanupExpiredPosts` executa diariamente às 3h BRT
- Deleta posts com `expiresAt < now()`
- Deleta fotos associadas no Firebase Storage
- Deleta notificações de interesse relacionadas

**Notificações Expiradas:**

- Cloud Function `cleanupExpiredNotifications` executa diariamente
- Deleta notificações com `expiresAt < now()`

---

## 9. Seus Direitos (LGPD Art. 18)

### 9.1. Direito de Acesso (Art. 18, I e II)

Você tem direito a:

- Confirmar se processamos seus dados
- Solicitar cópia completa de todos os dados armazenados

**Como exercer:**

1. Acesse **Configurações** → **Meus Dados** → **Baixar Meus Dados**
2. Ou envie email para `privacidade@tosembanda.com`
3. Receberá arquivo JSON com todos os dados em até **15 dias úteis**

**Formato do arquivo (exemplo):**

```json
{
  "user": {
    "uid": "user_123",
    "email": "usuario@email.com",
    "createdAt": "2025-01-15T10:30:00Z"
  },
  "profiles": [
    {
      "profileId": "profile_123",
      "name": "João Silva",
      "isBand": false,
      "location": {"latitude": -23.5505, "longitude": -46.6333},
      "city": "São Paulo",
      "instruments": ["Guitarra", "Baixo"],
      "genres": ["Rock", "Blues"]
    }
  ],
  "posts": [...],
  "messages": [...],
  "notifications": [...]
}
```

### 9.2. Direito de Correção (Art. 18, III)

Você pode **editar dados incorretos** a qualquer momento:

- **Perfil**: Configurações → Editar Perfil
- **Localização**: Altere cidade/coordenadas
- **Email**: Entre em contato (requer verificação)

### 9.3. Direito de Eliminação (Art. 18, VI)

**Deleção de Perfil Específico:**

1. Acesse perfil desejado → Menu → **Excluir Perfil**
2. Confirme exclusão (ação irreversível)
3. Dados deletados: posts, conversas, notificações desse perfil

**Deleção de Conta Completa:**

1. Configurações → **Excluir Conta**
2. Confirme exclusão (ação irreversível)
3. **Todos os perfis, posts, mensagens e fotos serão deletados permanentemente**
4. Backups retidos por 90 dias (recuperação de emergência)

**Exceções (não deletamos):**

- Logs de auditoria (obrigação legal - 6 meses)
- Dados anonimizados para estatísticas
- Mensagens enviadas para outros usuários (permanecem no histórico deles)

### 9.4. Direito de Portabilidade (Art. 18, V)

Você pode **exportar seus dados** em formato estruturado (JSON):

1. Configurações → **Baixar Meus Dados**
2. Arquivo ZIP contém: perfis, posts, mensagens, notificações
3. Pode importar para outro serviço (se compatível)

### 9.5. Direito de Revogação de Consentimento (Art. 18, IX)

Você pode **retirar consentimento** a qualquer momento:

- **Geolocalização**: Edite perfil e altere para localização genérica (desativa notificações de proximidade)
- **Notificações de proximidade**: Configurações → Notificações → Desativar "Posts Próximos"
- **Compartilhamento de dados**: Exclua conta (única forma de revogar completamente)

**⚠️ Consequência:** Revogar consentimento de geolocalização impede funcionamento correto da busca (campo obrigatório). Recomendamos deletar perfil se não quiser fornecer localização.

### 9.6. Direito de Oposição (Art. 18, VIII)

Você pode **se opor a tratamentos** baseados em legítimo interesse:

- **Análise de perfil** (recomendações): Não implementado ainda
- **Marketing**: Não fazemos marketing (app sem anúncios)

### 9.7. Direito de Revisão de Decisões Automatizadas (Art. 20)

Você tem direito a **solicitar revisão humana** de decisões automatizadas.  
**⚠️ Não aplicável:** App não toma decisões automatizadas que produzam efeitos jurídicos. Todas as conexões dependem de ação humana.

---

## 10. Transferência Internacional de Dados

### 10.1. Localização dos Dados

**Servidores Primários:**

- **Firebase Firestore**: `southamerica-east1` (São Paulo, Brasil)
- **Firebase Storage**: `southamerica-east1` (São Paulo, Brasil)
- **Cloud Functions**: `southamerica-east1` (São Paulo, Brasil)

**Servidores de Backup (Google Cloud):**

- Multi-region: `us`, `eu` (backup redundante)

### 10.2. Conformidade GDPR (União Europeia)

Se você é residente da UE, seus dados podem ser transferidos para Brasil.  
**Garantias de Proteção:**

- Google Cloud Platform possui **Standard Contractual Clauses (SCCs)**
- Firebase certificado: ISO 27001, SOC 2, ISO 27017, ISO 27018
- GDPR Compliance: [Firebase GDPR](https://firebase.google.com/support/privacy)

### 10.3. Conformidade CCPA (Califórnia, EUA)

Se você é residente da Califórnia:

- Tem direito de saber quais dados coletamos (seção 3)
- Pode solicitar deleção (seção 9.3)
- Não vendemos seus dados (seção 5.2)

---

## 11. Cookies e Tecnologias de Rastreamento

### 11.1. Uso de Cookies

❌ **Não usamos cookies** (app nativo, não é website).

### 11.2. Identificadores de Dispositivo

Usamos identificadores anônimos:

- **Firebase Instance ID**: Token único do dispositivo (FCM)
- **Firebase Analytics ID**: Identificador anônimo para eventos
- **UUID de sessão**: Temporário (resetado a cada login)

**Você pode resetar:**

1. Desinstale e reinstale o app
2. Ou revogue permissões no Android/iOS (Settings → Apps → WeGig → Reset)

---

## 12. Privacidade de Crianças (Menores de 18 anos)

### 12.1. Idade Mínima

O WeGig **não é destinado a menores de 18 anos**. Não coletamos intencionalmente dados de crianças.

**Se descobrirmos que coletamos dados de menor de 18 anos sem consentimento parental:**

1. Deletaremos conta imediatamente
2. Notificaremos responsável legal (se identificável)
3. Removeremos todos os dados associados

**Se você é pai/mãe** e descobriu que seu filho criou conta, entre em contato: `privacidade@tosembanda.com`

---

## 13. Alterações nesta Política

### 13.1. Notificação de Mudanças

Podemos atualizar esta Política de Privacidade periodicamente. Você será notificado:

- **Mudanças substanciais**: Email + notificação in-app + banner no app
- **Mudanças menores**: Apenas atualização da data no topo

### 13.2. Histórico de Versões

| Versão | Data       | Mudanças                               |
| ------ | ---------- | -------------------------------------- |
| 1.0    | 27/11/2025 | Primeira versão - LGPD/GDPR compliance |

Versões anteriores disponíveis em: `https://tosembanda.com/privacidade/historico`

---

## 14. Contato e Exercício de Direitos

### 14.1. Encarregado de Dados (DPO)

**Nome:** Wagner Oliveira  
**Email:** dpo@tosembanda.com  
**Privacidade:** privacidade@tosembanda.com  
**Suporte:** suporte@tosembanda.com

**Horário de Atendimento:** Segunda a Sexta, 9h às 18h (horário de Brasília)  
**Prazo de Resposta:**

- Solicitações simples: Até 72 horas úteis
- Exportação de dados: Até 15 dias úteis
- Deleção de conta: Imediata (via app) ou até 5 dias úteis (via email)

### 14.2. Como Exercer Seus Direitos

**Via App (recomendado):**

1. Acesse **Configurações** → **Privacidade e Dados**
2. Escolha ação desejada:
   - Baixar Meus Dados (portabilidade)
   - Editar Dados (correção)
   - Excluir Conta (eliminação)

**Via Email:**

1. Envie mensagem para `privacidade@tosembanda.com`
2. Assunto: [LGPD] Solicitação de [Acesso/Correção/Eliminação/Portabilidade]
3. Inclua: Nome, email cadastrado, descrição da solicitação
4. Responderemos em até 72 horas úteis

### 14.3. Autoridade de Proteção de Dados

**Brasil - ANPD (Autoridade Nacional de Proteção de Dados):**

- Website: https://www.gov.br/anpd
- Email: atendimento@anpd.gov.br
- Telefone: 0800 071 2003

**União Europeia - EDPB (European Data Protection Board):**

- Website: https://edpb.europa.eu
- Contato: Supervisory Authority do seu país

---

## 15. Glossário de Termos Técnicos

- **GeoPoint**: Par de coordenadas geográficas (latitude/longitude)
- **UID**: User Identifier (identificador único do Firebase Auth)
- **profileId**: Identificador único de perfil (ex: `profile_123`)
- **authorProfileId**: Perfil que criou um post/mensagem
- **recipientProfileId**: Perfil que recebe notificação/mensagem
- **Firebase Firestore**: Banco de dados NoSQL em nuvem do Google
- **Firebase Storage**: Armazenamento de arquivos (fotos) do Google
- **Cloud Functions**: Código backend executado em servidores Google
- **OAuth2**: Protocolo de autenticação (Google/Apple Sign-In)
- **JWT**: JSON Web Token (token de autenticação criptografado)
- **TLS**: Transport Layer Security (criptografia HTTPS)
- **AES-256**: Padrão de criptografia de dados em repouso

---

## 16. Consentimento Expresso

**AO ACEITAR ESTA POLÍTICA DE PRIVACIDADE, VOCÊ DECLARA EXPRESSAMENTE QUE:**

✅ **Compreendo e Concordo com:**

1. Coleta e armazenamento de meus **dados de geolocalização (GeoPoint, cidade, bairro)**
2. Exibição pública de minha **localização aproximada** (cidade e distância)
3. Uso de minha localização para **notificações de proximidade** (posso desativar)
4. Funcionamento do **sistema de múltiplos perfis** e isolamento de dados
5. Armazenamento de dados em **servidores Firebase (Google Cloud Platform)**
6. Uso de **Google Maps API** para visualização de mapas
7. Processamento de dados conforme descrito nesta Política

✅ **Estou Ciente Que:**

1. Posso **revogar consentimento** a qualquer momento (impacta funcionalidade)
2. Tenho direito a **acessar, corrigir, deletar e exportar** meus dados
3. Posso **desativar notificações de proximidade** nas Configurações
4. **Deletar perfil/conta é permanente** (não há recuperação após 90 dias)
5. Outros usuários podem **salvar screenshots** de conversas antes de eu deletar

✅ **Declaro Que:**

1. Tenho pelo menos **18 anos de idade** ou consentimento dos responsáveis
2. Li e compreendi integralmente esta Política de Privacidade
3. Concordo com todos os termos descritos acima

---

**Ao clicar em "Aceito os termos de uso e política de privacidade" durante o cadastro, você confirma que leu, compreendeu e concorda com esta Política.**

**Versão:** 1.0  
**Data:** 27 de novembro de 2025  
**Documento gerado para conformidade LGPD/GDPR/CCPA**

---

**Para dúvidas ou exercício de direitos, entre em contato:**  
📧 **privacidade@tosembanda.com**  
🕒 **Prazo de resposta: 72 horas úteis**
