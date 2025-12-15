import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script para deletar posts antigos que não têm o campo 'location'
/// Uso: dart run scripts/delete_old_posts.dart

void main() async {
  print('🔥 Iniciando script para deletar posts antigos...\n');
  
  try {
    // Inicializa o Firebase
    await Firebase.initializeApp();
    print('✅ Firebase inicializado\n');
    
    final firestore = FirebaseFirestore.instance;
    
    // Busca todos os posts
    print('🔍 Buscando posts na coleção...');
    final snapshot = await firestore.collection('posts').get();
    
    print('📊 Total de posts encontrados: ${snapshot.docs.length}\n');
    
    if (snapshot.docs.isEmpty) {
      print('ℹ️  Nenhum post encontrado na coleção.');
      return;
    }
    
    // Filtra posts sem o campo 'location'
    final postsWithoutLocation = <QueryDocumentSnapshot>[];
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (!data.containsKey('location') || data['location'] == null) {
        postsWithoutLocation.add(doc);
      }
    }
    
    print('📌 Posts sem campo "location": ${postsWithoutLocation.length}');
    
    if (postsWithoutLocation.isEmpty) {
      print('✨ Todos os posts já têm o campo "location". Nada a fazer!');
      return;
    }
    
    // Mostra detalhes dos posts que serão deletados
    print('\n📋 Posts que serão deletados:\n');
    for (var i = 0; i < postsWithoutLocation.length; i++) {
      final doc = postsWithoutLocation[i];
      final data = doc.data() as Map<String, dynamic>;
      print('   ${i + 1}. ID: ${doc.id}');
      print('      Autor: ${data['authorUid'] ?? 'desconhecido'}');
      print('      Mensagem: ${data['message'] ?? 'sem mensagem'}');
      print('      Criado: ${data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : 'desconhecido'}');
      print('');
    }
    
    // Confirmação do usuário
    print('⚠️  ATENÇÃO: Esta ação é irreversível!');
    print('Deseja deletar estes ${postsWithoutLocation.length} posts? (s/n): ');
    
    final response = stdin.readLineSync()?.toLowerCase().trim();
    
    if (response != 's' && response != 'sim') {
      print('\n❌ Operação cancelada pelo usuário.');
      return;
    }
    
    // Deleta os posts
    print('\n🗑️  Deletando posts...');
    
    int deletedCount = 0;
    int errorCount = 0;
    
    for (final doc in postsWithoutLocation) {
      try {
        await doc.reference.delete();
        deletedCount++;
        stdout.write('\r   Progresso: $deletedCount/${postsWithoutLocation.length}');
      } catch (e) {
        errorCount++;
        print('\n   ❌ Erro ao deletar post ${doc.id}: $e');
      }
    }
    
    print('\n\n✅ Concluído!');
    print('   • Posts deletados: $deletedCount');
    if (errorCount > 0) {
      print('   • Erros: $errorCount');
    }
    print('\n💡 Agora você pode criar novos posts que terão o campo "location" automaticamente.\n');
    
  } catch (e, stackTrace) {
    print('\n❌ Erro ao executar o script: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
