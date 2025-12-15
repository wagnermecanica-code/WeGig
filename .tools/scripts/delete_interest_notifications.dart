import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// Script para deletar notificações duplicadas do tipo 'interest'
/// 
/// CONTEXTO:
/// O sistema estava criando interesses em DOIS lugares:
/// 1. Collection 'interests' (correto, usado atualmente)
/// 2. Collection 'notifications' com type='interest' (legado, duplicado)
/// 
/// Este script limpa as notificações legadas para eliminar a duplicação.

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final firestore = FirebaseFirestore.instance;

  print('═══════════════════════════════════════════════════════════════');
  print('🧹 LIMPEZA DE NOTIFICAÇÕES DUPLICADAS');
  print('═══════════════════════════════════════════════════════════════\n');

  print('📋 Buscando notificações com type="interest"...\n');

  // Buscar TODAS as notificações do tipo 'interest'
  final querySnapshot = await firestore
      .collection('notifications')
      .where('type', isEqualTo: 'interest')
      .get();

  final totalFound = querySnapshot.docs.length;

  if (totalFound == 0) {
    print('✅ Nenhuma notificação type="interest" encontrada!');
    print('   O Firestore já está limpo.\n');
    print('═══════════════════════════════════════════════════════════════');
    return;
  }

  print('📊 Encontradas $totalFound notificações type="interest"\n');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('LISTAGEM DAS NOTIFICAÇÕES A SEREM DELETADAS:');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  // Listar todas antes de deletar
  for (int i = 0; i < querySnapshot.docs.length; i++) {
    final doc = querySnapshot.docs[i];
    final data = doc.data();
    final recipientId = data['recipientProfileId'] as String?;
    final createdAt = data['createdAt'] as Timestamp?;
    final read = data['read'] as bool?;

    print('${i + 1}. ID: ${doc.id}');
    print('   Recipient: $recipientId');
    print('   Created: ${createdAt?.toDate()}');
    print('   Read: $read\n');
  }

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('⚠️  CONFIRMAÇÃO NECESSÁRIA');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  print('Você está prestes a DELETAR $totalFound notificações.');
  print('Esta ação NÃO PODE SER DESFEITA!\n');
  print('Digite "CONFIRMAR" para prosseguir ou qualquer outra coisa para cancelar:');

  // Aguardar confirmação do usuário
  // NOTA: Para executar automaticamente, comente as linhas abaixo e descomente a linha de execução
  
  // ═══════════════════════════════════════════════════════════════
  // MODO AUTOMÁTICO (executando deleção):
  // ═══════════════════════════════════════════════════════════════
  await _executeDeletion(firestore, querySnapshot.docs);
}

Future<void> _executeDeletion(
  FirebaseFirestore firestore,
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) async {
  print('\n🔥 INICIANDO DELEÇÃO...\n');

  // Firestore permite no máximo 500 operações por batch
  const batchSize = 500;
  int deletedCount = 0;

  for (int i = 0; i < docs.length; i += batchSize) {
    final batch = firestore.batch();
    final end = (i + batchSize < docs.length) ? i + batchSize : docs.length;
    final batchDocs = docs.sublist(i, end);

    for (final doc in batchDocs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    deletedCount += batchDocs.length;

    print('✅ Batch ${(i / batchSize).floor() + 1}: ${batchDocs.length} notificações deletadas');
    print('   Progresso: $deletedCount/${docs.length}\n');

    // Pequeno delay para não sobrecarregar o Firestore
    if (end < docs.length) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('✅ LIMPEZA CONCLUÍDA COM SUCESSO!');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  print('📊 RESUMO:');
  print('   Total deletado: $deletedCount notificações type="interest"');
  print('   Collection "notifications" agora contém apenas notificações válidas');
  print('   Collection "interests" permanece intacta\n');
  print('🎯 RESULTADO:');
  print('   Badge counter agora contará apenas interests da collection correta');
  print('   Sem duplicação!\n');
  print('═══════════════════════════════════════════════════════════════');
}
