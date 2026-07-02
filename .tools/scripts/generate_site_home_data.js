const fs = require('fs');
const path = require('path');

const outputPath = path.resolve(__dirname, '../../docs/site-home-data.json');

const fallbackPayload = {
  stats: {
    community: 'Comunidade musical ativa e em expansão contínua',
    opportunities: 'Novas oportunidades, serviços e convites toda semana',
  },
  postsSectionSubtitle:
    'Veja exemplos editoriais de oportunidades, perfis e serviços antes de baixar o app.',
  cards: [],
};

function loadCurrentPayload() {
  if (!fs.existsSync(outputPath)) {
    return { ...fallbackPayload };
  }

  const raw = fs.readFileSync(outputPath, 'utf8');
  const parsed = JSON.parse(raw);

  return {
    stats:
      parsed && typeof parsed.stats === 'object' && parsed.stats
        ? parsed.stats
        : fallbackPayload.stats,
    postsSectionSubtitle:
      typeof parsed?.postsSectionSubtitle === 'string' &&
      parsed.postsSectionSubtitle.trim()
        ? parsed.postsSectionSubtitle.trim()
        : fallbackPayload.postsSectionSubtitle,
    cards: Array.isArray(parsed?.cards) ? parsed.cards : fallbackPayload.cards,
  };
}

const payload = {
  ...loadCurrentPayload(),
  generatedAt: new Date().toISOString(),
};

fs.writeFileSync(outputPath, `${JSON.stringify(payload, null, 2)}\n`, 'utf8');
console.log(`site-home-data.json atualizado em ${outputPath}`);