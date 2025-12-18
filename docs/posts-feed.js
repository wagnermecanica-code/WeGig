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

// Criar HTML do card de post
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
  const city = post.city || "";
  const state = post.state || "";
  const location = [city, state].filter(Boolean).join(", ");

  // Data
  const createdAt = post.createdAt?.toDate?.() || new Date();
  const timeAgo = formatTimeAgo(createdAt);

  // Conteúdo específico por tipo
  let specificContent = "";

  if (type === "sales") {
    // Anúncio de espaço
    const title = post.title || "Anúncio";
    const price = post.price || 0;
    const discountValue = post.discountValue || 0;
    const hasDiscount = discountValue > 0;
    const finalPrice = hasDiscount
      ? post.discountMode === "percentage"
        ? price * (1 - discountValue / 100)
        : price - discountValue
      : price;

    specificContent = `
      <div class="post-title">${escapeHtml(title)}</div>
      ${
        hasDiscount
          ? `
        <div class="post-price-original">
          <span class="price-strikethrough">R$ ${price.toFixed(2)}</span>
          <span class="discount-badge">-${discountValue}${
              post.discountMode === "percentage" ? "%" : ""
            }</span>
        </div>
      `
          : ""
      }
      <div class="post-price">R$ ${finalPrice.toFixed(2)}</div>
    `;
  } else {
    // Músico ou Banda
    const instruments =
      type === "musician"
        ? (post.instruments || []).slice(0, 3).join(", ")
        : (post.seekingMusicians || []).slice(0, 3).join(", ");
    const level = post.level || "";

    specificContent = `
      <div class="post-type-label">${typeLabel}</div>
      ${
        instruments
          ? `<div class="post-instruments">🎵 ${escapeHtml(instruments)}</div>`
          : ""
      }
      ${level ? `<div class="post-level">⭐ ${escapeHtml(level)}</div>` : ""}
    `;
  }

  // Mensagem/conteúdo
  const content = post.content || "";
  const truncatedContent =
    content.length > 100 ? content.substring(0, 100) + "..." : content;

  return `
    <div class="post-card" data-post-id="${
      post.id
    }" style="--card-color: ${color}">
      <div class="post-card-image">
        ${
          postPhoto
            ? `<img src="${postPhoto}" alt="Foto do post" loading="lazy" />`
            : `<div class="post-card-placeholder" style="background-color: ${color}20">
              <span>${typeIcon}</span>
            </div>`
        }
      </div>
      <div class="post-card-content">
        <div class="post-card-header">
          <div class="post-author">
            ${
              authorPhoto
                ? `<img src="${authorPhoto}" alt="${escapeHtml(
                    authorName
                  )}" class="author-avatar" />`
                : `<div class="author-avatar-placeholder" style="background-color: ${color}">${authorName
                    .charAt(0)
                    .toUpperCase()}</div>`
            }
            <span class="author-name">${escapeHtml(authorName)}</span>
          </div>
          <span class="post-type-badge" style="background-color: ${color}">${typeIcon}</span>
        </div>
        
        <div class="post-card-body">
          ${specificContent}
          ${
            truncatedContent
              ? `<p class="post-content">${escapeHtml(truncatedContent)}</p>`
              : ""
          }
        </div>
        
        <div class="post-card-footer">
          <span class="post-location">📍 ${
            escapeHtml(location) || "Brasil"
          }</span>
          <span class="post-time">🕐 ${timeAgo}</span>
        </div>
      </div>
    </div>
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

// Criar conteúdo do marker (estilo do app Flutter - CustomMarkerWidget)
function createMarkerContent(post, isActive) {
  const type = post.type || "musician";
  const color = CONFIG.COLORS[type];
  const authorPhoto = post.authorPhotoUrl || post.activeProfilePhotoUrl;

  const size = isActive ? 56 : 46;
  const borderWidth = isActive ? 4 : 3;

  // Container wrapper para efeitos
  const wrapper = document.createElement("div");
  wrapper.style.cssText = `
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
  `;

  // Efeito de pulso para marcador ativo (como no app)
  if (isActive) {
    const pulse = document.createElement("div");
    pulse.style.cssText = `
      position: absolute;
      width: 70px;
      height: 70px;
      border-radius: 50%;
      background: ${color}30;
      animation: markerPulse 1.5s ease-out infinite;
    `;
    wrapper.appendChild(pulse);
  }

  // Container principal do marcador (replica CustomMarkerWidget)
  const container = document.createElement("div");
  container.className = `map-marker ${isActive ? "active" : ""} ${type}`;
  container.style.cssText = `
    position: relative;
    width: ${size}px;
    height: ${size}px;
    border-radius: 50%;
    border: ${borderWidth}px solid white;
    background: linear-gradient(135deg, ${color}, ${color}cc);
    box-shadow: 0 4px 8px rgba(0,0,0,0.3);
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    overflow: hidden;
  `;

  if (authorPhoto) {
    const img = document.createElement("img");
    img.src = authorPhoto;
    img.style.cssText = `
      width: 100%;
      height: 100%;
      object-fit: cover;
    `;
    img.onerror = () => {
      container.innerHTML = getMarkerIcon(type);
    };
    container.appendChild(img);
  } else {
    container.innerHTML = getMarkerIcon(type);
  }

  wrapper.appendChild(container);
  return wrapper;
}

// Ícone padrão do marker
function getMarkerIcon(type) {
  const icons = {
    musician:
      '<svg width="24" height="24" viewBox="0 0 24 24" fill="white"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg>',
    band: '<svg width="24" height="24" viewBox="0 0 24 24" fill="white"><path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"/></svg>',
    sales:
      '<svg width="24" height="24" viewBox="0 0 24 24" fill="white"><path d="M21.41 11.58l-9-9C12.05 2.22 11.55 2 11 2H4c-1.1 0-2 .9-2 2v7c0 .55.22 1.05.59 1.42l9 9c.36.36.86.58 1.41.58.55 0 1.05-.22 1.41-.59l7-7c.37-.36.59-.86.59-1.41 0-.55-.23-1.06-.59-1.42zM5.5 7C4.67 7 4 6.33 4 5.5S4.67 4 5.5 4 7 4.67 7 5.5 6.33 7 5.5 7z"/></svg>',
  };
  return icons[type] || icons.musician;
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
  document.querySelectorAll(".post-card").forEach((card) => {
    card.classList.toggle("highlighted", card.dataset.postId === postId);
  });
}

// Scroll para o post no carrossel
function scrollToPost(postId) {
  const card = document.querySelector(`.post-card[data-post-id="${postId}"]`);
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
