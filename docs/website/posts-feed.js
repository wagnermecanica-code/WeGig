/**
 * WeGig - Posts Feed Component
 * Integração com Firebase Firestore para renderização dos cards do site
 *
 * Cores do Design System:
 * - Primary (Músico): #37475A
 * - Accent (Banda): #E47911
 * - SalesBlue (Espaço): #683FFF
 */

// Configurações
const CONFIG = {
  MAX_VISIBLE_POSTS: 120,
  FETCH_DOC_LIMIT: 150,
  COLORS: {
    musician: "#37475A",
    band: "#E47911",
    sales: "#683FFF",
    hiring: "#000000",
  },
  TYPE_LABELS: {
    musician: "Busca banda",
    band: "Busca músico",
    sales: "Anúncio",
    hiring: "Oportunidade",
  },
  TYPE_ICONS: {
    musician: "music",
    band: "people",
    sales: "shop",
    hiring: "briefcase",
  },
};

// Estado global
let posts = [];

// Aguardar Firebase estar pronto. O mapa é inicializado sob demanda.
function waitForDependencies() {
  return new Promise((resolve, reject) => {
    console.log("Aguardando Firebase...");

    // Polling approach - mais confiável que eventos
    let attempts = 0;
    const maxAttempts = 100; // 10 segundos (100 * 100ms)

    const checkDependencies = () => {
      attempts++;

      const firebaseOk = window.firebaseReady === true && window.firebaseDb;
      console.log(`Tentativa ${attempts} - Firebase: ${firebaseOk}`);

      if (firebaseOk) {
        console.log("Firebase pronto!");
        resolve();
        return;
      }

      if (attempts >= maxAttempts) {
        console.error("Timeout esperando dependências");
        console.error("Firebase:", {
          ready: window.firebaseReady,
          db: !!window.firebaseDb,
        });
        reject(new Error(`Timeout: Firebase=${firebaseOk}`));
        return;
      }

      // Verificar novamente em 100ms
      setTimeout(checkDependencies, 100);
    };

    // Também ouvir eventos como backup
    window.addEventListener("firebase-ready", () => {
      console.log("Evento firebase-ready recebido");
    });

    // Iniciar verificação
    checkDependencies();
  });
}

// Inicialização
async function init() {
  console.log("WeGig Posts Feed: Iniciando...");

  try {
    await waitForDependencies();
    console.log("Dependências carregadas");

    // Carregar posts do Firebase
    await loadPosts();
    console.log("Posts carregados:", posts.length);

    // Renderizar posts
    renderPosts();
    console.log("Posts renderizados");

    console.log("Posts Feed inicializado com sucesso");
  } catch (error) {
    console.error("Erro ao inicializar Posts Feed:", error);
    console.error("Stack:", error.stack);
    showError(error.message);
  }
}

// Carregar posts do Firebase
async function loadPosts() {
  console.log("Iniciando carregamento de posts...");

  const db = window.firebaseDb;
  const q = window.firebaseQuery;
  const coll = window.firebaseCollection;
  const orderByClause = window.firebaseOrderBy;
  const whereClause = window.firebaseWhere;
  const limitClause = window.firebaseLimit;
  const getDocs = window.firebaseGetDocs;
  const Timestamp = window.firebaseTimestamp;

  console.log("Firebase refs:", {
    db: !!db,
    q: !!q,
    coll: !!coll,
    getDocs: !!getDocs,
  });

  if (!db || !q || !coll || !whereClause || !getDocs || !Timestamp) {
    throw new Error("Firebase não inicializado corretamente");
  }

  const postsRef = coll(db, "posts");
  const postsQuery = q(
    postsRef,
    whereClause("expiresAt", ">", Timestamp.now()),
    orderByClause("expiresAt", "desc"),
    limitClause(CONFIG.FETCH_DOC_LIMIT),
  );

  console.log("Executando query...");
  const snapshot = await getDocs(postsQuery);
  console.log("Query retornou:", snapshot.size, "documentos");

  const rawPosts = snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));

  posts = rawPosts
    .map((post) => ({
      ...post,
      type: normalizePostType(post.type),
    }))
    .filter((post) => isPostActive(post))
    .sort(comparePostsByCreatedAtDesc)
    .slice(0, CONFIG.MAX_VISIBLE_POSTS);

  console.log(
    `${posts.length} posts ativos carregados (de ${rawPosts.length} consultados)`,
  );
  console.log("Distribuição por tipo:", getTypeDistribution(posts));
  if (posts.length > 0) {
    console.log(
      "Primeiro post:",
      posts[0].id,
      posts[0].authorName,
      posts[0].type,
    );
  }
}

// Renderizar posts no carrossel
function renderPosts() {
  const carousel = document.getElementById("posts-carousel");
  if (!carousel) return;

  if (posts.length === 0) {
    carousel.innerHTML = `
      <div class="no-posts-message">
        <div class="icon"><i class="iconsax" data-icon="box"></i></div>
        <h3>Nenhum post disponível</h3>
        <p>Seja o primeiro a publicar! Baixe o app e comece a conectar-se com músicos.</p>
        <a href="#download" class="btn btn-primary">Baixar App</a>
      </div>
    `;
    return;
  }

  carousel.innerHTML = posts.map((post) => createPostCard(post)).join("");

  carousel.querySelectorAll(".post-card").forEach((card) => {
    card.addEventListener("mouseenter", () => {
      card.classList.add("post-card--hovered");
    });

    card.addEventListener("mouseleave", () => {
      card.classList.remove("post-card--hovered");
    });
  });
}

// Criar HTML do card de post
function createPostCard(post) {
  const type = normalizePostType(post.type);
  const color = CONFIG.COLORS[type];
  const typeLabel = CONFIG.TYPE_LABELS[type];
  const typeIcon = CONFIG.TYPE_ICONS[type];

  const authorName = post.authorName || "Perfil";
  const authorPhoto = post.authorPhotoUrl || post.activeProfilePhotoUrl;
  const postPhoto = post.photoUrls?.[0] || null;
  const locationLabel = formatLocationLabel(post);
  const createdAt = post.createdAt?.toDate?.() || new Date();
  const timeAgo = formatTimeAgo(createdAt);
  const postedLabel = formatPostDate(createdAt);

  const content = post.content || "";
  const truncatedContent =
    content.length > 170 ? content.substring(0, 170) + "..." : content;

  let subtitle = typeLabel;
  let primaryInfo = "";

  if (type === "sales") {
    const title = post.title || "Anúncio";
    const price = post.price || 0;
    const discountValue = post.discountValue || 0;
    const hasDiscount = discountValue > 0;
    const finalPrice = hasDiscount
      ? post.discountMode === "percentage"
        ? price * (1 - discountValue / 100)
        : price - discountValue
      : price;

    subtitle = title;
    primaryInfo = `<span class="pc-price">${formatCurrency(finalPrice)}${
      hasDiscount
        ? ` <small class="pc-discount">-${discountValue}${
            post.discountMode === "percentage" ? "%" : ""
          }</small>`
        : ""
    }</span>`;
  } else if (type === "hiring") {
    const eventType = post.eventType || "Evento";
    const budget = post.budgetRange || "";
    const guestCount =
      typeof post.guestCount === "number"
        ? `${post.guestCount} convidados`
        : "";

    subtitle = eventType;

    const metaParts = [budget, guestCount].filter(Boolean);
    if (metaParts.length) {
      primaryInfo = `<span class="pc-price pc-price--soft">${escapeHtml(
        metaParts.join(" · "),
      )}</span>`;
    }
  } else {
    const items =
      type === "musician"
        ? (post.instruments || []).slice(0, 3).join(" · ")
        : (post.seekingMusicians || []).slice(0, 3).join(" · ");
    if (items)
      primaryInfo = `<span class="pc-price pc-price--soft">${escapeHtml(items)}</span>`;
  }

  const detailChips = buildPostDetailChips(post, type);
  const detailMarkup = detailChips.length
    ? `<div class="pc-detail-grid">${detailChips
        .map(
          (chip) =>
            `<span class="pc-detail-chip"><i class="iconsax" data-icon="${chip.icon}"></i>${escapeHtml(
              chip.label,
            )}</span>`,
        )
        .join("")}</div>`
    : "";

  const media = postPhoto
    ? `<img src="${postPhoto}" alt="" class="pc-cover" loading="lazy" />`
    : "";

  const authorMarkup = `
    <div class="pc-author-block">
      ${
        authorPhoto
          ? `<img src="${authorPhoto}" alt="" class="pc-avatar" loading="lazy" />`
          : `<span class="pc-avatar pc-avatar--placeholder" style="background:${color}">${escapeHtml(
              authorName.charAt(0),
            )}</span>`
      }
      <div class="pc-author-copy">
        <span class="pc-kicker"><i class="iconsax" data-icon="location"></i>${escapeHtml(locationLabel)}</span>
        <span class="pc-name">${escapeHtml(authorName)}</span>
      </div>
    </div>
  `;

  const noPhotoHeader = `
    <div class="pc-inline-header">
      ${authorMarkup}
      <span class="pc-time">${timeAgo}</span>
    </div>
  `;

  return `
    <article class="post-card pc ${postPhoto ? "" : "post-card--no-photo"}" data-post-id="${post.id}" style="--pc-accent:${color}">
      ${
        postPhoto
          ? `<div class="pc-media">
              ${media}
              <div class="pc-media-header">
                <span class="pc-type-chip"><i class="iconsax" data-icon="${typeIcon}"></i>${escapeHtml(typeLabel)}</span>
                <span class="pc-time">${timeAgo}</span>
              </div>
              ${authorMarkup}
            </div>`
          : ""
      }
      <div class="pc-content">
        ${postPhoto ? "" : noPhotoHeader}
        ${postPhoto ? "" : `<span class="pc-type-chip pc-type-chip--inline"><i class="iconsax" data-icon="${typeIcon}"></i>${escapeHtml(typeLabel)}</span>`}
        <div class="pc-title-row">
          <h3 class="pc-title">${escapeHtml(subtitle)}</h3>
          ${primaryInfo}
        </div>
        ${
          truncatedContent
            ? `<p class="pc-message">${escapeHtml(truncatedContent)}</p>`
            : ""
        }
        ${detailMarkup}
        <div class="pc-meta-row">
          <span class="pc-meta-chip"><i class="iconsax" data-icon="calendar-1"></i>${postedLabel}</span>
        </div>
      </div>
    </article>
  `;
}

// Mostrar erro
function showError(errorMessage) {
  const carousel = document.getElementById("posts-carousel");
  if (carousel) {
    carousel.innerHTML = `
      <div class="error-message">
        <div class="icon"><i class="iconsax" data-icon="warning-2"></i></div>
        <h3>Não foi possível carregar os posts</h3>
        <p>Tente novamente mais tarde ou baixe o app para a experiência completa.</p>
        ${
          errorMessage
            ? `<p class="error-detail" style="font-size: 12px; color: #999; margin-top: 8px;">Erro: ${errorMessage}</p>`
            : ""
        }
        <a href="#download" class="btn btn-primary">Baixar App</a>
      </div>
    `;
  }
}

// Utilitários
function formatTimeAgo(date) {
  const now = new Date();
  const diff = now - date;

  const minutes = Math.floor(diff / 60000);
  const hours = Math.floor(diff / 3600000);
  const days = Math.floor(diff / 86400000);

  if (days > 0) return `${days}d`;
  if (hours > 0) return `${hours}h`;
  if (minutes > 0) return `${minutes}m`;
  return "agora";
}

function formatPostDate(date) {
  return new Intl.DateTimeFormat("pt-BR", {
    day: "2-digit",
    month: "short",
  }).format(date);
}

function formatLocationLabel(post) {
  const city = firstAvailable(post, ["city", "cidade"]);
  const state = firstAvailable(post, ["state", "uf", "estado", "region"]);
  const normalizedState =
    state && String(state).length <= 3 ? String(state).toUpperCase() : state;

  if (city && normalizedState) return `${city} · ${normalizedState}`;
  if (city) return city;
  if (normalizedState) return normalizedState;
  return "Brasil";
}

function formatCurrency(value) {
  const amount = Number(value) || 0;
  return new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
    maximumFractionDigits: 0,
  }).format(amount);
}

function normalizeList(value) {
  if (Array.isArray(value)) return value.filter(Boolean).map(String);
  if (typeof value === "string") {
    return value
      .split(/[,;·]/)
      .map((item) => item.trim())
      .filter(Boolean);
  }
  return [];
}

function firstAvailable(post, keys) {
  for (const key of keys) {
    const value = post[key];
    if (Array.isArray(value) && value.length) return value;
    if (typeof value === "number" && Number.isFinite(value)) return value;
    if (typeof value === "string" && value.trim()) return value.trim();
  }
  return null;
}

function buildPostDetailChips(post, type) {
  const chips = [];

  const addChip = (icon, value) => {
    if (!value || chips.length >= 4) return;
    chips.push({ icon, label: value });
  };

  if (type === "sales") {
    addChip(
      "shop",
      firstAvailable(post, ["category", "productCategory", "itemCategory"]),
    );
    addChip(
      "tag",
      firstAvailable(post, ["condition", "itemCondition", "productCondition"]),
    );
    addChip("box", firstAvailable(post, ["brand", "manufacturer", "model"]));
  } else if (type === "hiring") {
    addChip("briefcase", firstAvailable(post, ["eventType", "title"]));
    addChip(
      "calendar-1",
      formatOptionalDate(
        firstAvailable(post, ["eventDate", "date", "startDate"]),
      ),
    );
    addChip(
      "people",
      typeof post.guestCount === "number"
        ? `${post.guestCount} convidados`
        : null,
    );
  } else {
    const genres = normalizeList(
      firstAvailable(post, ["genres", "musicGenres", "styles"]),
    ).slice(0, 2);

    addChip("star", genres.join(" · "));
    addChip(
      "clock",
      firstAvailable(post, ["availability", "schedule", "period"]),
    );
    addChip(
      "award",
      firstAvailable(post, ["experienceLevel", "level", "experience"]),
    );
  }

  return chips;
}

function formatOptionalDate(value) {
  const date = timestampToDate(value);
  return date ? formatPostDate(date) : null;
}

function escapeHtml(text) {
  if (!text) return "";
  const div = document.createElement("div");
  div.textContent = text;
  return div.innerHTML;
}

function normalizePostType(type) {
  const raw = String(type || "")
    .trim()
    .toLowerCase();
  const normalized = raw.normalize("NFD").replace(/[\u0300-\u036f]/g, "");

  if (normalized === "musician" || normalized === "musico") {
    return "musician";
  }

  if (normalized === "band" || normalized === "banda") {
    return "band";
  }

  if (
    normalized === "sales" ||
    normalized === "sale" ||
    normalized === "anuncio" ||
    normalized === "announcement"
  ) {
    return "sales";
  }

  if (
    normalized === "hiring" ||
    normalized === "contratacao" ||
    normalized === "job" ||
    normalized === "oportunidade"
  ) {
    return "hiring";
  }

  return "musician";
}

function timestampToDate(value) {
  if (!value) return null;
  if (typeof value?.toDate === "function") {
    const date = value.toDate();
    return date instanceof Date && !isNaN(date.getTime()) ? date : null;
  }
  if (value instanceof Date && !isNaN(value.getTime())) {
    return value;
  }
  if (typeof value === "number") {
    const date = new Date(value);
    return isNaN(date.getTime()) ? null : date;
  }
  if (typeof value === "string") {
    const date = new Date(value);
    return isNaN(date.getTime()) ? null : date;
  }
  return null;
}

function resolvePostExpiryDate(post) {
  const type = normalizePostType(post.type);
  const createdAt = timestampToDate(post.createdAt) || new Date();
  const expiresAt = timestampToDate(post.expiresAt);
  const promoEndDate = timestampToDate(post.promoEndDate);

  if (type === "sales") {
    if (promoEndDate) return promoEndDate;
    if (expiresAt) return expiresAt;
    return new Date(createdAt.getTime() + 30 * 24 * 60 * 60 * 1000);
  }

  if (expiresAt) {
    return expiresAt;
  }

  return new Date(createdAt.getTime() + 30 * 24 * 60 * 60 * 1000);
}

function isPostActive(post) {
  const now = Date.now();
  const expiresAt = resolvePostExpiryDate(post);
  return expiresAt.getTime() > now;
}

function comparePostsByCreatedAtDesc(postA, postB) {
  const dateA = timestampToDate(postA.createdAt)?.getTime() ?? 0;
  const dateB = timestampToDate(postB.createdAt)?.getTime() ?? 0;
  return dateB - dateA;
}

function getTypeDistribution(items) {
  return items.reduce((acc, post) => {
    const type = normalizePostType(post.type);
    acc[type] = (acc[type] || 0) + 1;
    return acc;
  }, {});
}

// Iniciar quando DOM estiver pronto
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", init);
} else {
  init();
}
