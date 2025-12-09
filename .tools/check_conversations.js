const admin = require('firebase-admin');

// Initialize with DEV project
admin.initializeApp({
  projectId: 'wegig-dev'
});

const db = admin.firestore();

async function checkConversations() {
  const uid = '1xP3a8dBQqTlgwx3ZArXOkhgB2E2';
  const profileId = 'PUWMiOB96Q06phANJDSd';
  
  console.log('🔍 Verificando conversas no wegig-dev...');
  console.log('   UID:', uid);
  console.log('   ProfileId:', profileId);
  
  const snapshot = await db.collection('conversations').get();
  
  console.log('\n📋 Encontradas', snapshot.size, 'conversas:\n');
  
  snapshot.forEach(doc => {
    const data = doc.data();
    console.log('Document:', doc.id);
    console.log('  participants:', JSON.stringify(data.participants));
    console.log('  participantProfiles:', JSON.stringify(data.participantProfiles));
    console.log('  profileUid:', JSON.stringify(data.profileUid));
    console.log('  Has UID in participants?', data.participants?.includes(uid));
    console.log('  Has profileId in participantProfiles?', data.participantProfiles?.includes(profileId));
    console.log('');
  });
}

checkConversations().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
