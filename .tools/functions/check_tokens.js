const admin = require('firebase-admin');

// Initialize with default credentials (uses GOOGLE_APPLICATION_CREDENTIALS)
admin.initializeApp({
  projectId: 'to-sem-banda-83e19'
});

const db = admin.firestore();

async function checkTokens() {
  // Profile ID from the logs that was failing
  const profileId = 'F6D3lVpGgcrOCVOrZjON';
  
  console.log(`\n📋 Verificando tokens do perfil: ${profileId}\n`);
  
  const tokensSnap = await db
    .collection('profiles')
    .doc(profileId)
    .collection('fcmTokens')
    .limit(20)
    .get();
  
  if (tokensSnap.empty) {
    console.log('❌ Nenhum token encontrado');
    process.exit(0);
    return;
  }
  
  console.log(`Encontrados ${tokensSnap.size} tokens:\n`);
  
  // Count by platform
  const platformCounts = {};
  
  tokensSnap.docs.forEach((doc, idx) => {
    const data = doc.data();
    const platform = data.platform || 'SEM_PLATFORM';
    platformCounts[platform] = (platformCounts[platform] || 0) + 1;
    
    if (idx < 10) {
      const token = (data.token || '').substring(0, 30);
      console.log(`${idx + 1}. Platform: ${platform}, Token: ${token}...`);
    }
  });
  
  console.log('\n📊 Resumo por plataforma:');
  Object.entries(platformCounts).forEach(([platform, count]) => {
    console.log(`   ${platform}: ${count}`);
  });
  
  process.exit(0);
}

checkTokens().catch(err => {
  console.error('Erro:', err.message);
  process.exit(1);
});
