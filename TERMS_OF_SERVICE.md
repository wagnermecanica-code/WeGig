# Termos de Uso - WeGig (Tô Sem Banda)

**Última atualização:** 27 de novembro de 2025  
**Versão:** 1.0  
**URL:** https://tosembanda.com/termos

---

## 1. Aceitação dos Termos

Ao criar uma conta e utilizar o aplicativo WeGig ("App", "Plataforma", "Serviço"), você ("Usuário", "Você") concorda integralmente com estes Termos de Uso e com nossa [Política de Privacidade](https://tosembanda.com/privacidade). Se você não concorda com qualquer parte destes termos, não utilize o Serviço.

**IMPORTANTE:** Ao marcar a caixa "Aceito os termos de uso e política de privacidade" durante o cadastro, você declara que:

- Leu e compreendeu integralmente estes Termos
- Concorda com o uso de seus **dados de geolocalização** conforme descrito nestes Termos e na Política de Privacidade
- Concorda com o funcionamento do **sistema de múltiplos perfis** e suas implicações de privacidade
- Tem pelo menos 18 anos de idade ou possui consentimento dos responsáveis legais

---

## 2. Descrição do Serviço

O WeGig é uma plataforma social que conecta músicos e bandas através de:

- **Busca geolocalizada**: Encontre oportunidades musicais próximas a você
- **Sistema de múltiplos perfis**: Crie até 5 perfis independentes (músico ou banda)
- **Posts efêmeros**: Oportunidades expiram automaticamente após 30 dias
- **Chat em tempo real**: Comunicação direta entre perfis
- **Notificações de proximidade**: Alertas sobre posts próximos à sua localização
- **Sistema de interesses**: Demonstre interesse em posts de outros usuários

---

## 3. Sistema de Geolocalização

### 3.1. Como Funciona

O WeGig utiliza **dados de geolocalização em tempo real** para:

1. **Exibir sua localização em posts**: Quando você cria um post, armazenamos suas coordenadas geográficas (latitude/longitude) e cidade
2. **Busca por proximidade**: Outros usuários podem encontrar seus posts através de busca geográfica (raio de até 100km)
3. **Notificações baseadas em localização**: Enviar alertas quando posts relevantes são criados próximos a você
4. **Cálculo de distância**: Exibir a distância entre você e outros posts/perfis

### 3.2. Dados de Localização Armazenados

Para cada perfil que você criar, armazenamos:

- **Coordenadas GeoPoint** (latitude/longitude) com precisão de até 6 casas decimais (~11cm)
- **Cidade, bairro e estado** obtidos via geocodificação reversa
- **Histórico de localização de posts**: Cada post criado armazena a localização no momento da publicação

### 3.3. Consentimento e Controle

✅ **Você concorda que:**

- Seus dados de localização serão **visíveis publicamente** em seus posts
- Outros usuários poderão calcular a distância aproximada entre sua localização e a deles
- Suas coordenadas exatas não são exibidas na interface, apenas cidade e distância aproximada

✅ **Você pode:**

- Alterar a localização de cada perfil a qualquer momento
- Desativar notificações de proximidade nas Configurações
- Deletar posts contendo sua localização antiga
- Excluir perfis e seus dados de localização associados

❌ **Você NÃO pode:**

- Criar posts sem fornecer localização (campo obrigatório para funcionamento da busca)
- Ocultar completamente sua localização enquanto mantém posts ativos

### 3.4. Uso de Geolocalização por Terceiros

**Google Maps API:**

- Utilizamos Google Maps Platform para exibir mapas e calcular rotas
- Google pode coletar dados anônimos sobre uso de mapas (consulte [Termos do Google Maps](https://cloud.google.com/maps-platform/terms))
- Não compartilhamos suas coordenadas exatas com Google - apenas solicitamos renderização de mapas

**Firebase Firestore Geoqueries:**

- Suas coordenadas são armazenadas em Firebase Cloud Firestore (Google Cloud Platform)
- Utilizamos índices geoespaciais para buscas eficientes
- Google não tem acesso direto aos dados (criptografia em trânsito e em repouso)

---

## 4. Sistema de Múltiplos Perfis

### 4.1. Arquitetura Instagram-Style

O WeGig implementa um sistema de **perfis isolados** onde:

- Cada usuário (identificado por Firebase UID) pode ter até **5 perfis**
- Cada perfil funciona como uma **identidade independente** (músico ou banda)
- Todos os dados (posts, conversas, notificações, interesses) são **isolados por perfil**

### 4.2. Como Funciona

**Estrutura de Dados:**

```
users/{uid}:
  - email: seu@email.com
  - activeProfileId: profile_1
  - profiles: [summary de todos os perfis]

profiles/{profileId}:
  - uid: Firebase UID do dono
  - name: "João Silva"
  - isBand: false
  - location: GeoPoint(-23.5505, -46.6333)
  - city: "São Paulo"
  - instruments: ["Guitarra", "Baixo"]
  - genres: ["Rock", "Blues"]
  - photoUrl, bio, youtubeLink...
```

### 4.3. Isolamento de Privacidade

✅ **Garantias de Isolamento:**

- **Posts**: Cada post pertence a um perfil específico (authorProfileId)
- **Conversas**: Mensagens são trocadas entre perfis, não entre usuários
- **Notificações**: Enviadas para perfis específicos (recipientProfileId)
- **Interesses**: Registrados por perfil (interestedProfileId)
- **Badge counters**: Contadores de não lidos são isolados por perfil

✅ **Você concorda que:**

- Ao trocar de perfil, **não verá** posts/mensagens/notificações de outros perfis seus
- Outros usuários **não podem** descobrir que dois perfis pertencem ao mesmo usuário (a menos que você revele)
- Cada perfil tem sua própria **foto, nome, localização, bio** e histórico independente

✅ **Regras de Segurança (Firestore Rules):**

```javascript
// Exemplo: Posts só podem ser criados pelo dono do perfil
match /posts/{postId} {
  allow create: if request.auth.uid == request.resource.data.authorUid
                && request.resource.data.authorProfileId in getUserProfileIds();
}

// Exemplo: Perfis só podem ser editados pelo dono
match /profiles/{profileId} {
  allow update: if request.auth.uid == resource.data.uid;
}
```

### 4.4. Limites e Restrições

- **Máximo 5 perfis** por usuário (limite técnico para performance)
- **Impossível recuperar perfil deletado** (deleção permanente após confirmação)
- **Troca de perfil ativo**: Atualiza `activeProfileId` no documento `users/{uid}`
- **Posts órfãos**: Se deletar perfil com posts ativos, posts permanecem mas sem vínculo editável

---

## 5. Responsabilidades do Usuário

### 5.1. Você é Responsável Por:

✅ **Veracidade das Informações:**

- Fornecer dados verdadeiros sobre habilidades musicais, experiência e localização
- Não criar perfis falsos ou se passar por outras pessoas/bandas

✅ **Localização Precisa:**

- Informar localização real para garantir funcionalidade correta da busca
- Não usar coordenadas falsas para manipular resultados de busca

✅ **Conteúdo Publicado:**

- Garantir que posts, mensagens e fotos não violam direitos autorais
- Não publicar conteúdo ofensivo, discriminatório, ilegal ou pornográfico
- Respeitar propriedade intelectual de músicas, imagens e vídeos

✅ **Segurança da Conta:**

- Manter senha segura e não compartilhar credenciais
- Proteger dispositivo contra acesso não autorizado (seus perfis ficam logados)
- Notificar imediatamente sobre uso não autorizado

### 5.2. Proibições

❌ **É PROIBIDO:**

- Criar mais de 5 perfis por usuário (uso de múltiplas contas)
- Usar automação/bots para criar posts, enviar mensagens ou demonstrar interesse
- Fazer spam ou assédio através de mensagens/notificações
- Coletar dados de outros usuários (scraping)
- Tentar burlar sistema de geolocalização
- Usar o serviço para fins comerciais sem autorização (ex: recrutamento em massa)
- Fazer engenharia reversa do aplicativo

---

## 6. Propriedade Intelectual

### 6.1. Conteúdo do Usuário

Você mantém **todos os direitos** sobre conteúdo que publicar (fotos, textos, vídeos). Ao publicar, você concede ao WeGig uma **licença mundial, não exclusiva, gratuita e transferível** para:

- Armazenar, processar e exibir seu conteúdo na plataforma
- Criar cópias de backup e thumbnails
- Comprimir imagens para otimização de performance (85% qualidade JPEG)
- Exibir previews de links do YouTube incorporados

**Esta licença termina** quando você deleta o conteúdo ou perfil, exceto:

- Conteúdo compartilhado por outros usuários (screenshots, mensagens salvas)
- Backups de segurança (deletados em até 90 dias)

### 6.2. Propriedade do WeGig

O aplicativo, design, código-fonte, algoritmos, marca "WeGig" e "Tô Sem Banda" são propriedade exclusiva de Wagner Oliveira (desenvolvedor). É proibido:

- Copiar, modificar ou distribuir o aplicativo
- Usar marca "WeGig" ou "Tô Sem Banda" sem autorização
- Criar produtos derivados baseados no código/design

---

## 7. Privacidade e Proteção de Dados (LGPD/GDPR)

### 7.1. Conformidade Legal

O WeGig está em conformidade com:

- **Lei Geral de Proteção de Dados (LGPD)** - Brasil
- **General Data Protection Regulation (GDPR)** - União Europeia
- **California Consumer Privacy Act (CCPA)** - EUA

### 7.2. Seus Direitos (LGPD Art. 18)

Você tem direito a:

1. **Confirmação de tratamento**: Saber se processamos seus dados
2. **Acesso**: Solicitar cópia de todos os dados armazenados
3. **Correção**: Editar dados incorretos ou desatualizados
4. **Anonimização/Bloqueio**: Solicitar anonimização de dados não essenciais
5. **Eliminação**: Deletar todos os dados (exceto obrigações legais)
6. **Portabilidade**: Receber dados em formato estruturado (JSON)
7. **Revogação de consentimento**: Retirar consentimento a qualquer momento

**Para exercer seus direitos:** Entre em contato via email (privacidade@tosembanda.com) ou exclua sua conta nas Configurações do App.

### 7.3. Base Legal para Tratamento (LGPD Art. 7)

Processamos seus dados com base em:

- **Consentimento** (Art. 7, I): Você aceita estes Termos ao criar conta
- **Execução de contrato** (Art. 7, V): Necessário para fornecer o serviço
- **Legítimo interesse** (Art. 7, IX): Segurança, prevenção de fraudes, melhorias

---

## 8. Exclusão de Conta e Dados

### 8.1. Deleção Iniciada pelo Usuário

Você pode deletar sua conta a qualquer momento:

1. Acesse **Configurações** → **Excluir Conta**
2. Confirme exclusão (ação irreversível)
3. **Todos os perfis, posts, mensagens e notificações serão deletados permanentemente**

**O que é deletado:**

- ✅ Documento `users/{uid}` (email, activeProfileId, profiles summary)
- ✅ Todos os documentos `profiles/{profileId}` e dados associados
- ✅ Posts (collection `posts`)
- ✅ Conversas (collection `conversations` e sub-collection `messages`)
- ✅ Notificações (collection `notifications`)
- ✅ Interesses (collection `interests`)
- ✅ Fotos no Firebase Storage (`profiles/{profileId}/` e `posts/{postId}/`)

**O que NÃO é deletado:**

- ❌ Logs de auditoria (requerido por lei - 6 meses)
- ❌ Dados anonimizados para estatísticas (sem identificação pessoal)
- ❌ Mensagens enviadas para outros usuários (permanecem no histórico deles)

### 8.2. Suspensão/Banimento

O WeGig pode suspender ou banir sua conta se:

- Violar estes Termos de Uso
- Publicar conteúdo ilegal ou ofensivo
- Usar automação/bots
- Receber múltiplas denúncias de assédio
- Atividade suspeita de fraude

**Em caso de banimento:**

- Você será notificado via email
- Pode contestar decisão dentro de 15 dias
- Dados serão mantidos por 6 meses para investigação

---

## 9. Modificações do Serviço

### 9.1. Atualizações de Funcionalidades

Podemos adicionar, modificar ou remover funcionalidades a qualquer momento:

- Novos recursos (ex: videochamadas, stories)
- Mudanças em algoritmos de busca/recomendação
- Ajustes em limites (ex: número de perfis, tamanho de fotos)

**Você será notificado** sobre mudanças significativas via:

- Notificação in-app
- Email cadastrado
- Atualização destes Termos (com nova data)

### 9.2. Interrupção do Serviço

Nos reservamos o direito de:

- **Manutenção programada**: Notificada com 24h de antecedência
- **Emergências**: Interrupção imediata para correção de bugs críticos
- **Descontinuação**: Encerramento do serviço com aviso de 30 dias

---

## 10. Limitação de Responsabilidade

### 10.1. Uso Por Sua Conta e Risco

O WeGig é fornecido "como está" (AS IS), sem garantias de:

- ❌ Disponibilidade 24/7 (podem ocorrer falhas técnicas)
- ❌ Precisão absoluta de dados de geolocalização (margem de erro GPS)
- ❌ Qualidade ou veracidade de posts de outros usuários
- ❌ Compatibilidade com todos os dispositivos

### 10.2. Isenção de Responsabilidade

**Não somos responsáveis por:**

- ❌ Encontros presenciais arranjados através do app (use sempre locais públicos)
- ❌ Contratos ou acordos musicais firmados entre usuários
- ❌ Conteúdo publicado por terceiros (posts, mensagens, fotos)
- ❌ Perda de oportunidades ou rendimentos devido a bugs/falhas
- ❌ Vazamento de dados por negligência do usuário (senha fraca, dispositivo roubado)
- ❌ Uso indevido de dados de geolocalização por outros usuários

### 10.3. Limites Legais

Em nenhuma hipótese nossa responsabilidade excederá o valor de **R$ 500,00 (quinhentos reais)** por usuário, exceto em casos de dolo ou culpa grave comprovada.

---

## 11. Jurisdição e Legislação Aplicável

### 11.1. Lei Brasileira

Estes Termos são regidos pela legislação brasileira:

- Lei Geral de Proteção de Dados (LGPD) - Lei nº 13.709/2018
- Marco Civil da Internet - Lei nº 12.965/2014
- Código de Defesa do Consumidor - Lei nº 8.078/1990

### 11.2. Foro

Fica eleito o foro da Comarca de **São Paulo/SP** para dirimir quaisquer questões relacionadas a estes Termos, com exclusão de qualquer outro, por mais privilegiado que seja.

---

## 12. Contato

**Empresa:** WeGig - Conectando Músicos  
**Desenvolvedor:** Wagner Oliveira  
**Email:** suporte@tosembanda.com  
**Privacidade/LGPD:** privacidade@tosembanda.com  
**Endereço:** [A ser definido quando empresa for formalizada]

**Horário de Atendimento:** Segunda a Sexta, 9h às 18h (horário de Brasília)  
**Prazo de Resposta:** Até 72 horas úteis

---

## 13. Consentimento Específico para Geolocalização e Multi-Perfil

**AO ACEITAR ESTES TERMOS, VOCÊ DECLARA EXPRESSAMENTE QUE:**

✅ **Geolocalização:**

1. Compreendo que o WeGig utiliza minha localização GPS em tempo real
2. Autorizo o armazenamento de minhas coordenadas geográficas (GeoPoint) no Firebase Firestore
3. Estou ciente que minha localização (cidade e distância aproximada) será visível para outros usuários
4. Aceito receber notificações baseadas em proximidade geográfica
5. Entendo que posso desativar notificações de proximidade, mas não posso ocultar localização de posts ativos

✅ **Sistema de Múltiplos Perfis:**

1. Compreendo que posso criar até 5 perfis independentes (músico ou banda)
2. Estou ciente que cada perfil tem dados isolados (posts, mensagens, notificações)
3. Aceito que ao trocar de perfil, não visualizo dados de outros perfis meus
4. Entendo que outros usuários não podem descobrir que múltiplos perfis são meus (exceto se eu revelar)
5. Estou ciente que deletar perfil é permanente e irreversível

✅ **Processamento de Dados:**

1. Autorizo o tratamento de meus dados pessoais conforme Política de Privacidade
2. Concordo com armazenamento em servidores Firebase (Google Cloud Platform)
3. Aceito uso de Google Maps API para visualização de mapas
4. Estou ciente dos meus direitos sob LGPD (acesso, correção, eliminação, portabilidade)

---

**Ao clicar em "Aceito os termos de uso e política de privacidade" durante o cadastro, você confirma que leu, compreendeu e concorda com todos os itens acima.**

**Versão:** 1.0  
**Data:** 27 de novembro de 2025  
**Documento gerado para conformidade LGPD/GDPR**
