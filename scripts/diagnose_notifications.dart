import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final firestore = FirebaseFirestore.instance;

  print('═══════════════════════════════════════════════════════════════');
  print('🔍 DIAGNÓSTICO COMPLETO DE NOTIFICAÇÕES');
  print('═══════════════════════════════════════════════════════════════\n');

  // Solicitar profileId do usuário
  print('Digite o profileId do perfil Wagner:');
  // Para teste, vamos usar um placeholder - você deve substituir pelo profileId real
  final profileId = 'SEU_PROFILE_ID_AQUI'; // ← SUBSTITUIR

  print('\n📌 Analisando perfil: $profileId\n');

  // 1. ANÁLISE DE NOTIFICATIONS
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('1️⃣  COLLECTION: notifications');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  final notificationsSnap = await firestore
      .collection('notifications')
      .where('recipientProfileId', isEqualTo: profileId)
      .get();

  print('📊 Total de documentos: ${notificationsSnap.docs.length}\n');

  int notifUnreadCount = 0;
  int notifReadCount = 0;
  int notifNullCount = 0;
  int notifExpiredCount = 0;

  for (var doc in notificationsSnap.docs) {
    final data = doc.data();
    final read = data['read'];
    final expiresAt = data['expiresAt'] as Timestamp?;
    final createdAt = data['createdAt'] as Timestamp?;
    final type = data['type'] ?? 'unknown';
    
    final isExpired = expiresAt != null && expiresAt.toDate().isBefore(DateTime.now());
    
    print('📄 Doc ID: ${doc.id}');
    print('   Type: $type');
    print('   read: $read (${read.runtimeType})');
    print('   expiresAt: ${expiresAt?.toDate()}');
    print('   createdAt: ${createdAt?.toDate()}');
    print('   expired: $isExpired');
    
    if (read == null) {
      print('   ⚠️  CAMPO read É NULL!');
      notifNullCount++;
    } else if (read == false) {
      print('   🔴 NÃO LIDA');
      notifUnreadCount++;
    } else if (read == true) {
      print('   ✅ LIDA');
      notifReadCount++;
    }
    
    if (isExpired) {
      print('   ⏰ EXPIRADA!');
      notifExpiredCount++;
    }
    
    print('');
  }

  print('📈 RESUMO NOTIFICATIONS:');
  print('   Não lidas (read=false): $notifUnreadCount');
  print('   Lidas (read=true): $notifReadCount');
  print('   Null (read=null): $notifNullCount');
  print('   Expiradas: $notifExpiredCount');
  print('');

  // 2. ANÁLISE DE INTERESTS
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('2️⃣  COLLECTION: interests');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  final interestsSnap = await firestore
      .collection('interests')
      .where('postAuthorProfileId', isEqualTo: profileId)
      .get();

  print('📊 Total de documentos: ${interestsSnap.docs.length}\n');

  int interestsUnreadCount = 0;
  int interestsReadCount = 0;
  int interestsNullCount = 0;

  for (var doc in interestsSnap.docs) {
    final data = doc.data();
    final read = data['read'];
    final createdAt = data['createdAt'] as Timestamp?;
    final interestedProfileId = data['interestedProfileId'] ?? 'unknown';
    
    print('📄 Doc ID: ${doc.id}');
    print('   interestedProfileId: $interestedProfileId');
    print('   read: $read (${read.runtimeType})');
    print('   createdAt: ${createdAt?.toDate()}');
    
    if (read == null) {
      print('   ⚠️  CAMPO read É NULL!');
      interestsNullCount++;
    } else if (read == false) {
      print('   🔴 NÃO LIDA');
      interestsUnreadCount++;
    } else if (read == true) {
      print('   ✅ LIDA');
      interestsReadCount++;
    }
    
    print('');
  }

  print('📈 RESUMO INTERESTS:');
  print('   Não lidas (read=false): $interestsUnreadCount');
  print('   Lidas (read=true): $interestsReadCount');
  print('   Null (read=null): $interestsNullCount');
  print('');

  // 3. TESTE DE QUERY COM FILTRO read=false
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('3️⃣  TESTE DE QUERY COM FILTRO read=false');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  print('🔎 Query: notifications where read == false...');
  final notifUnreadSnap = await firestore
      .collection('notifications')
      .where('recipientProfileId', isEqualTo: profileId)
      .where('read', isEqualTo: false)
      .get();

  print('   Resultado: ${notifUnreadSnap.docs.length} documentos\n');

  print('🔎 Query: interests where read == false...');
  final interestsUnreadSnap = await firestore
      .collection('interests')
      .where('postAuthorProfileId', isEqualTo: profileId)
      .where('read', isEqualTo: false)
      .get();

  print('   Resultado: ${interestsUnreadSnap.docs.length} documentos\n');

  final totalUnread = notifUnreadSnap.docs.length + interestsUnreadSnap.docs.length;
  print('🎯 TOTAL DE NÃO LIDAS (query com filtro): $totalUnread');
  print('');

  // 4. RESUMO FINAL
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('4️⃣  RESUMO FINAL');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  print('📊 CONTAGEM MANUAL (iterando docs):');
  print('   Notifications não lidas: $notifUnreadCount');
  print('   Interests não lidas: $interestsUnreadCount');
  print('   TOTAL: ${notifUnreadCount + interestsUnreadCount}');
  print('');

  print('📊 CONTAGEM COM QUERY (where read=false):');
  print('   Notifications não lidas: ${notifUnreadSnap.docs.length}');
  print('   Interests não lidas: ${interestsUnreadSnap.docs.length}');
  print('   TOTAL: $totalUnread');
  print('');

  print('⚠️  INCONSISTÊNCIAS DETECTADAS:');
  if (notifNullCount > 0) {
    print('   🔴 $notifNullCount notifications com read=null!');
  }
  if (interestsNullCount > 0) {
    print('   🔴 $interestsNullCount interests com read=null!');
  }
  if (notifExpiredCount > 0) {
    print('   ⏰ $notifExpiredCount notifications expiradas!');
  }
  if (notifNullCount == 0 && interestsNullCount == 0 && notifExpiredCount == 0) {
    print('   ✅ Nenhuma inconsistência detectada');
  }
  print('');

  print('═══════════════════════════════════════════════════════════════');
  print('✅ DIAGNÓSTICO COMPLETO');
  print('═══════════════════════════════════════════════════════════════');
}
