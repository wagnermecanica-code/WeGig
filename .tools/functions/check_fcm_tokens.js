const admin = require('firebase-admin');
const serviceAccount = require('/Users/wagneroliveira/to_sem_banda/.config/firebase/to-sem-banda-83e19-firebase-adminsdk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkTokens() {
  const profileId = '45HHAPu2xOf2rfiCKlzY';
  const tokensSnap = await db.collection('profiles').doc(profileId).collection('fcmTokens').get();
  
  console.log('\n📱 Tokens FCM para perfil ' + profileId + ':\n');
  
  if (tokensSnap.empty) {
    console.log('❌ Nenhum token encontrado!');
    return;
  }
  
  const tokens = [];
  tokensSnap.docs.forEach(doc => {
    const data = doc.data();
    const updatedAt = data.updatedAt ? data.updatedAt.toDate() : null;
    tokens.push({
      id: doc.id,
      token: data.token,
      platform: data.platform || 'unknown',
      updatedAt: updatedAt ? updatedAt.toISOString() : 'N/A'
    });
  });
  
  // Ordenar por data (mais recente primeiro)
  tokens.sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));
  
  console.log('Total: ' + tokens.length + ' tokens\n');
  tokens.forEach((t, i) => {
    console.log((i+1) + '. [' + t.platform + '] ' + t.token.substring(0, 50) + '...');
    console.log('   Updated: ' + t.updatedAt + '\n');
  });
  
  process.exit(0);
}

checkTokens().catch(err => {
  console.error(err);
  process.exit(1);
});
