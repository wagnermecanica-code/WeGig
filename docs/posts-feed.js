/**
 * WeGig - Posts Feed Component
 * Integração com Firebase Firestore e Google Maps
 *
 * Cores do Design System:
 * - Primary (Músico): #37475A
 * - Accent (Banda): #E47911
 * - SalesBlue (Espaço): #007EB9
 */

// Configurações
const CONFIG = {
  MAP_ID: "b7134f9dc59c2ad97d5b292e", // WeGigProdMapWeb
  MAX_POSTS: 20,
  DEFAULT_CENTER: { lat: -23.5505, lng: -46.6333 }, // São Paulo
  DEFAULT_ZOOM: 11,
  COLORS: {
    musician: "#37475A",
    band: "#E47911",
    sales: "#007EB9",
  },
  TYPE_LABELS: {
    musician: "Busca banda",
    band: "Busca músico",
    sales: "Anúncio",
  },
  TYPE_ICONS: {
    musician: "🎸",
    band: "👥",
    sales: "🏪",
  },
};

// Estado global
let map = null;
let markers = [];
let posts = [];
let activePostId = null;

// Aguardar Firebase e Google Maps estarem prontos
function waitForDependencies() {
  return new Promise((resolve, reject) => {
    console.log("🔍 Aguardando dependências...");

    // Polling approach - mais confiável que eventos
    let attempts = 0;
    const maxAttempts = 100; // 10 segundos (100 * 100ms)

    const checkDependencies = () => {
      attempts++;

      const firebaseOk = window.firebaseReady === true && window.firebaseDb;
      const mapsOk = window.googleMapsReady === true && window.google?.maps;

      console.log(
        `🔍 Tentativa ${attempts} - Firebase: ${firebaseOk}, Maps: ${mapsOk}`
      );

      if (firebaseOk && mapsOk) {
        console.log("✅ Ambas dependências prontas!");
        resolve();
        return;
      }

      if (attempts >= maxAttempts) {
        console.error("⏱️ Timeout esperando dependências");
        console.error("Firebase:", {
          ready: window.firebaseReady,
          db: !!window.firebaseDb,
        });
        console.error("Maps:", {
          ready: window.googleMapsReady,
          google: !!window.google,
        });
        reject(new Error(`Timeout: Firebase=${firebaseOk}, Maps=${mapsOk}`));
        return;
      }

      // Verificar novamente em 100ms
      setTimeout(checkDependencies, 100);
    };

    // Também ouvir eventos como backup
    window.addEventListener("firebase-ready", () => {
      console.log("📡 Evento firebase-ready recebido");
    });

    window.addEventListener("google-maps-ready", () => {
      console.log("🗺️ Evento google-maps-ready recebido");
    });

    // Iniciar verificação
    checkDependencies();
  });
}

// Inicialização
async function init() {
  console.log("🚀 WeGig Posts Feed: Iniciando...");

  try {
    await waitForDependencies();
    console.log("✅ Dependências carregadas");

    // Inicializar mapa
    initMap();
    console.log("✅ Mapa inicializado");

    // Carregar posts do Firebase
    await loadPosts();
    console.log("✅ Posts carregados:", posts.length);

    // Renderizar posts
    renderPosts();
    console.log("✅ Posts renderizados");

    // Adicionar markers ao mapa
    addMarkersToMap();
    console.log("✅ Markers adicionados");

    console.log("✅ Posts Feed inicializado com sucesso");
  } catch (error) {
    console.error("❌ Erro ao inicializar Posts Feed:", error);
    console.error("❌ Stack:", error.stack);
    showError(error.message);
  }
}

// Inicializar Google Maps
function initMap() {
  const mapElement = document.getElementById("posts-map");
  if (!mapElement) return;

  map = new google.maps.Map(mapElement, {
    center: CONFIG.DEFAULT_CENTER,
    zoom: CONFIG.DEFAULT_ZOOM,
    mapId: CONFIG.MAP_ID,
    disableDefaultUI: true,
    zoomControl: true,
    gestureHandling: "cooperative",
    styles: [
      {
        featureType: "poi",
        elementType: "labels",
        stylers: [{ visibility: "off" }],
      },
    ],
  });
}

// Carregar posts do Firebase
async function loadPosts() {
  console.log("📥 Iniciando carregamento de posts...");

  const db = window.firebaseDb;
  const q = window.firebaseQuery;
  const coll = window.firebaseCollection;
  const whereClause = window.firebaseWhere;
  const orderByClause = window.firebaseOrderBy;
  const limitClause = window.firebaseLimit;
  const getDocs = window.firebaseGetDocs;
  const Timestamp = window.firebaseTimestamp;

  console.log("📥 Firebase refs:", {
    db: !!db,
    q: !!q,
    coll: !!coll,
    getDocs: !!getDocs,
    Timestamp: !!Timestamp,
  });

  if (!db || !q || !coll || !getDocs || !Timestamp) {
    throw new Error("Firebase não inicializado corretamente");
  }

  const now = Timestamp.now();
  console.log("📥 Timestamp now:", now.toDate());

  const postsRef = coll(db, "posts");
  const postsQuery = q(
    postsRef,
    whereClause("expiresAt", ">", now),
    orderByClause("expiresAt", "asc"), // REQUIRED: must orderBy the inequality field first
    orderByClause("createdAt", "desc"),
    limitClause(CONFIG.MAX_POSTS)
  );

  console.log("📥 Executando query...");
  const snapshot = await getDocs(postsQuery);
  console.log("📥 Query retornou:", snapshot.size, "documentos");

  posts = snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));

  console.log(`📋 ${posts.length} posts carregados`);
  if (posts.length > 0) {
    console.log(
      "📋 Primeiro post:",
      posts[0].id,
      posts[0].authorName,
      posts[0].type
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
        <div class="icon">📭</div>
        <h3>Nenhum post disponível</h3>
        <p>Seja o primeiro a publicar! Baixe o app e comece a conectar-se com músicos.</p>
        <a href="#download" class="btn btn-primary">Baixar App</a>
      </div>
    `;
    return;
  }

  carousel.innerHTML = posts.map((post) => createPostCard(post)).join("");

  // Adicionar event listeners para interação com mapa
  carousel.querySelectorAll(".post-card").forEach((card) => {
    card.addEventListener("mouseenter", () => {
      const postId = card.dataset.postId;
      highlightMarker(postId);
    });

    card.addEventListener("click", () => {
      // Não faz nada - apenas visual
      // Futuro: poderia abrir modal ou redirecionar para app
    });
  });
}

// Criar HTML do card de post - Layout horizontal (estilo lista)
function createPostCard(post) {
  const type = post.type || "musician";
  const color = CONFIG.COLORS[type];
  const typeLabel = CONFIG.TYPE_LABELS[type];
  const typeIcon = CONFIG.TYPE_ICONS[type];

  // Dados do autor
  const authorName = post.authorName || "Perfil";
  const authorPhoto = post.authorPhotoUrl || post.activeProfilePhotoUrl;
  const postPhoto = post.photoUrls?.[0] || null;

  // Localização
  const city = post.city || "Brasil";

  // Data
  const createdAt = post.createdAt?.toDate?.() || new Date();
  const timeAgo = formatTimeAgo(createdAt);

  // Mensagem do post (truncada)
  const content = post.content || "";
  const truncatedContent =
    content.length > 120 ? content.substring(0, 120) + "..." : content;

  // Conteúdo específico por tipo
  let subtitle = typeLabel;
  let extraInfo = "";

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
    extraInfo = `<span class="pc-price">R$ ${finalPrice.toFixed(0)}${
      hasDiscount
        ? ` <small class="pc-discount">-${discountValue}${
            post.discountMode === "percentage" ? "%" : ""
          }</small>`
        : ""
    }</span>`;
  } else {
    const items =
      type === "musician"
        ? (post.instruments || []).slice(0, 3).join(" · ")
        : (post.seekingMusicians || []).slice(0, 3).join(" · ");
    if (items) extraInfo = `<span class="pc-tags">${escapeHtml(items)}</span>`;
  }

  return `
    <article class="pc" data-post-id="${post.id}">
      <div class="pc-content">
        <div class="pc-header">
          <span class="pc-name">${escapeHtml(authorName)}</span>
          ${
            authorPhoto
              ? `<img src="${authorPhoto}" alt="" class="pc-avatar" />`
              : `<span class="pc-avatar pc-avatar--placeholder" style="background:${color}">${authorName.charAt(
                  0
                )}</span>`
          }
        </div>
        <div class="pc-subtitle" style="color:${color}">${escapeHtml(
    subtitle
  )}</div>
        ${extraInfo}
        ${
          truncatedContent
            ? `<p class="pc-message">${escapeHtml(truncatedContent)}</p>`
            : ""
        }
        <div class="pc-meta">
          <span>📍 ${escapeHtml(city)}</span>
          <span>· ${timeAgo}</span>
        </div>
      </div>
    </article>
  `;
}

// Adicionar markers ao mapa
function addMarkersToMap() {
  if (!map || posts.length === 0) {
    console.log("⚠️ addMarkersToMap: map=", !!map, "posts=", posts.length);
    return;
  }

  console.log("🗺️ Adicionando", posts.length, "markers ao mapa...");
  const bounds = new google.maps.LatLngBounds();

  posts.forEach((post, index) => {
    if (!post.location) {
      console.log(`⚠️ Post ${index} sem localização:`, post.id);
      return;
    }

    // Firebase Web SDK GeoPoint: propriedades latitude/longitude são getters
    // Admin SDK: _latitude/_longitude são propriedades internas
    // Tentamos ambos para compatibilidade
    let lat, lng;

    if (typeof post.location.latitude === "number") {
      lat = post.location.latitude;
      lng = post.location.longitude;
    } else if (typeof post.location._latitude === "number") {
      lat = post.location._latitude;
      lng = post.location._longitude;
    } else {
      console.log(
        `⚠️ Post ${index} formato de localização desconhecido:`,
        post.location
      );
      return;
    }

    console.log(`📍 Post ${index}:`, post.id, "lat=", lat, "lng=", lng);

    if (!lat || !lng) {
      console.log(`⚠️ Post ${index} com lat/lng inválidos`);
      return;
    }

    const position = { lat, lng };
    const type = post.type || "musician";
    const color = CONFIG.COLORS[type];

    // Criar marker customizado usando AdvancedMarkerElement
    const markerContent = createMarkerContent(post, false);

    const marker = new google.maps.marker.AdvancedMarkerElement({
      map,
      position,
      content: markerContent,
      title: post.authorName || "Post",
    });

    marker.postId = post.id;
    marker.postType = type;

    marker.addListener("click", () => {
      scrollToPost(post.id);
      highlightMarker(post.id);
    });

    markers.push(marker);
    bounds.extend(position);
  });

  // Ajustar zoom para mostrar todos os markers
  if (markers.length > 0) {
    map.fitBounds(bounds);

    // Limitar zoom máximo
    const listener = google.maps.event.addListener(map, "idle", () => {
      if (map.getZoom() > 14) map.setZoom(14);
      google.maps.event.removeListener(listener);
    });
  }
}

// Criar conteúdo do marker - SVG idêntico ao pin_template.svg do App Flutter
// NOTA: O app NÃO usa fotos nos markers, apenas cores sólidas com círculo branco
function createMarkerContent(post, isActive) {
  const type = post.type || "musician";
  const color = CONFIG.COLORS[type];

  // Cores de highlight (reflexo) baseadas na cor principal
  const highlightColor = lightenColor(color, 30);

  // Tamanhos proporcionais ao pin_template.svg (viewBox 256x256, mas escalado para 90x90)
  // Proporção: width=46.9, height=62.7 (ratio 1.337) do WeGigPinDescriptorBuilder
  const baseSize = isActive ? 52 : 46;
  const width = baseSize;
  const height = baseSize * 1.28; // Mesmo ratio do app (1.28)

  // Container wrapper com sombra
  const wrapper = document.createElement("div");
  wrapper.style.cssText = `
    position: relative;
    display: flex;
    flex-direction: column;
    align-items: center;
    filter: drop-shadow(0 3px 6px rgba(0,0,0,0.4));
  `;

  // Efeito de glow/blur para marcador ativo (como WeGigPinWidget.isHighlighted)
  if (isActive) {
    const glowSvg = document.createElementNS(
      "http://www.w3.org/2000/svg",
      "svg"
    );
    glowSvg.setAttribute("width", width * 1.15);
    glowSvg.setAttribute("height", height * 1.15);
    glowSvg.setAttribute("viewBox", "0 0 256 256");
    glowSvg.style.cssText = `
      position: absolute;
      top: -${height * 0.075}px;
      left: -${width * 0.075}px;
      opacity: 0.45;
      filter: blur(${baseSize * 0.12}px);
    `;
    // SVG path da gota (mesmo do pin_template.svg)
    glowSvg.innerHTML = `
      <g transform="translate(1.4 1.4) scale(2.81)">
        <path d="M 45 90 C 30.086 71.757 15.174 46.299 15.174 29.826 S 28.527 0 45 0 s 29.826 13.353 29.826 29.826 S 59.914 71.757 45 90 z" 
              fill="${color}" fill-opacity="0.9"/>
      </g>
    `;
    wrapper.appendChild(glowSvg);
  }

  // SVG principal - Exatamente como pin_template.svg do app
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  svg.setAttribute("width", width);
  svg.setAttribute("height", height);
  svg.setAttribute("viewBox", "0 0 256 256");
  svg.style.cssText = "position: relative; z-index: 1; cursor: pointer;";

  // Estrutura idêntica ao pin_template.svg:
  // 1. Path da gota (cor primária)
  // 2. Círculo branco central
  // 3. Highlight/reflexo para volume 3D
  svg.innerHTML = `
    <g transform="translate(1.4 1.4) scale(2.81)">
      <!-- Corpo da gota (cor primária) -->
      <path d="M 45 90 C 30.086 71.757 15.174 46.299 15.174 29.826 S 28.527 0 45 0 s 29.826 13.353 29.826 29.826 S 59.914 71.757 45 90 z" 
            fill="${color}"/>
      
      <!-- Círculo branco central -->
      <circle cx="45" cy="29.38" r="13.5" fill="white"/>
      
      <!-- Highlight/reflexo (dá volume 3D) -->
      <path d="M 48.596 5.375 C 33.355 5.375 21 17.73 21 32.97 c 0 1.584 0.141 3.135 0.397 4.646 C 20.496 35.035 20 32.264 20 29.375 c 0 -13.807 11.193 -25 25 -25 c 2.889 0 5.661 0.496 8.242 1.397 C 51.731 5.516 50.18 5.375 48.596 5.375 z" 
            fill="${highlightColor}"/>
    </g>
  `;

  wrapper.appendChild(svg);
  return wrapper;
}

// Função auxiliar para clarear uma cor hex
function lightenColor(hex, percent) {
  const num = parseInt(hex.replace("#", ""), 16);
  const r = Math.min(
    255,
    Math.floor((num >> 16) + ((255 - (num >> 16)) * percent) / 100)
  );
  const g = Math.min(
    255,
    Math.floor(
      ((num >> 8) & 0x00ff) + ((255 - ((num >> 8) & 0x00ff)) * percent) / 100
    )
  );
  const b = Math.min(
    255,
    Math.floor((num & 0x0000ff) + ((255 - (num & 0x0000ff)) * percent) / 100)
  );
  return `rgb(${r},${g},${b})`;
}

// Destacar marker no mapa
function highlightMarker(postId) {
  if (activePostId === postId) return;

  // Remover destaque anterior
  markers.forEach((marker) => {
    if (marker.postId === activePostId) {
      const post = posts.find((p) => p.id === marker.postId);
      if (post) {
        marker.content = createMarkerContent(post, false);
      }
    }
  });

  // Aplicar novo destaque
  activePostId = postId;
  const activeMarker = markers.find((m) => m.postId === postId);

  if (activeMarker) {
    const post = posts.find((p) => p.id === postId);
    if (post) {
      activeMarker.content = createMarkerContent(post, true);

      // Centralizar mapa no marker
      let lat, lng;
      if (typeof post.location.latitude === "number") {
        lat = post.location.latitude;
        lng = post.location.longitude;
      } else {
        lat = post.location._latitude;
        lng = post.location._longitude;
      }
      map.panTo({ lat, lng });
    }
  }

  // Destacar card no carrossel
  document.querySelectorAll(".pc").forEach((card) => {
    card.classList.toggle("pc--active", card.dataset.postId === postId);
  });
}

// Scroll para o post no carrossel
function scrollToPost(postId) {
  const card = document.querySelector(`.pc[data-post-id="${postId}"]`);
  if (card) {
    card.scrollIntoView({ behavior: "smooth", block: "center" });
  }
}

// Mostrar erro
function showError(errorMessage) {
  const carousel = document.getElementById("posts-carousel");
  if (carousel) {
    carousel.innerHTML = `
      <div class="error-message">
        <div class="icon">⚠️</div>
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

function escapeHtml(text) {
  if (!text) return "";
  const div = document.createElement("div");
  div.textContent = text;
  return div.innerHTML;
}

// Iniciar quando DOM estiver pronto
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", init);
} else {
  init();
}
