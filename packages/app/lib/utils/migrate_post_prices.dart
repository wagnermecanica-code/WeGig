import 'package:cloud_firestore/cloud_firestore.dart';

/// Script para migrar preços de posts existentes
/// Antes: post.price = preço FINAL (com desconto aplicado)
/// Depois: post.price = preço ORIGINAL (sem desconto)
Future<void> migratePostPrices() async {
  final firestore = FirebaseFirestore.instance;

  print('🔄 Iniciando migração de preços de posts...');

  try {
    // Buscar todos os posts de vendas
    final postsQuery = await firestore
        .collection('posts')
        .where('type', isEqualTo: 'sales')
        .get();

    print('📊 Encontrados ${postsQuery.docs.length} posts de vendas');

    int migrated = 0;
    int skipped = 0;

    for (final doc in postsQuery.docs) {
      final data = doc.data();
      final currentPrice = data['price'] as num?;
      final discountMode = data['discountMode'] as String?;
      final discountValue = data['discountValue'] as num?;

      if (currentPrice == null || currentPrice <= 0) {
        print('⚠️ Post ${doc.id}: preço inválido, pulando...');
        skipped++;
        continue;
      }

      // Se não há desconto, o preço já está correto (original = final)
      if (discountMode == null || discountMode == 'none' ||
          discountValue == null || discountValue <= 0) {
        print('✅ Post ${doc.id}: sem desconto, preço já correto');
        skipped++;
        continue;
      }

      // Calcular preço original a partir do final atual
      double originalPrice = currentPrice.toDouble();

      if (discountMode == 'percentage') {
        // Se preço atual é final e desconto é %, calcular original
        originalPrice = currentPrice.toDouble() / (1 - discountValue / 100);
      } else if (discountMode == 'fixed') {
        // Se desconto é valor fixo
        originalPrice = currentPrice.toDouble() + discountValue;
      }

      // Atualizar o documento com o preço original
      await doc.reference.update({
        'price': originalPrice,
      });

      print('✅ Post ${doc.id}: migrado R\$ ${currentPrice.toStringAsFixed(2)} → R\$ ${originalPrice.toStringAsFixed(2)}');
      migrated++;
    }

    print('🎉 Migração concluída!');
    print('📈 Migrados: $migrated posts');
    print('⏭️ Pulados: $skipped posts');
    print('📊 Total processados: ${postsQuery.docs.length} posts');

  } catch (e) {
    print('❌ Erro durante migração: $e');
    rethrow;
  }
}