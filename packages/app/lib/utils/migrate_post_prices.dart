import 'package:cloud_firestore/cloud_firestore.dart';

/// ⚠️ MIGRAÇÃO DESATIVADA - NÃO USAR
/// 
/// Esta migração foi desativada porque causava o problema descrito abaixo:
/// 
/// O código de salvamento de posts já salva o preço ORIGINAL (sem desconto)
/// no campo 'price' do Firestore. Esta migração assumia erroneamente que
/// o 'price' era o preço FINAL (com desconto aplicado) e tentava calcular
/// o original, causando inflação progressiva dos preços.
/// 
/// Exemplo do bug:
/// 1. Usuário cria post: price=100, discount=20%
/// 2. Firestore salva: price=100 (correto)
/// 3. Migração roda: assume que 100 é o final e calcula original = 100 / 0.8 = 125
/// 4. Firestore atualiza: price=125 (ERRADO!)
/// 5. Na próxima vez: 125 / 0.8 = 156.25 (pior ainda!)
/// 
/// A solução é NÃO rodar esta migração. O cálculo de exibição usa
/// PriceCalculator que corretamente subtrai o desconto do preço original.
@Deprecated('Esta migração foi desativada - causava inflação de preços')
Future<void> migratePostPrices() async {
  print('⚠️ MIGRAÇÃO DESATIVADA - Não executa nada');
  print('📖 Leia os comentários em migrate_post_prices.dart para entender por quê');
  return;
}

/// Script para CORRIGIR preços que foram inflados pela migração antiga.
/// 
/// ⚠️ EXECUTE APENAS UMA VEZ e com CUIDADO!
/// 
/// Este script tenta reverter o dano causado pela migração anterior.
/// Ele assume que os posts foram inflados N vezes e tenta calcular
/// o preço original correto.
/// 
/// USO:
/// 1. Primeiro faça um BACKUP do Firestore
/// 2. Execute manualmente via console
/// 3. Verifique os resultados
Future<void> fixInflatedPrices({int maxInflations = 5}) async {
  final firestore = FirebaseFirestore.instance;

  print('🔧 Iniciando correção de preços inflados...');
  print('⚠️ BACKUP: Certifique-se de ter feito backup do Firestore antes!');

  try {
    final postsQuery = await firestore
        .collection('posts')
        .where('type', isEqualTo: 'sales')
        .get();

    print('📊 Encontrados ${postsQuery.docs.length} posts de vendas');

    int fixed = 0;
    int skipped = 0;

    for (final doc in postsQuery.docs) {
      final data = doc.data();
      final currentPrice = data['price'] as num?;
      final discountMode = data['discountMode'] as String?;
      final discountValue = data['discountValue'] as num?;

      if (currentPrice == null || currentPrice <= 0) {
        skipped++;
        continue;
      }

      // Se não há desconto, não há como ter sido inflado
      if (discountMode == null || discountMode == 'none' ||
          discountValue == null || discountValue <= 0) {
        skipped++;
        continue;
      }

      // Heurística: verificar se o preço parece inflado
      // Um preço "razoável" estaria entre R$ 1 e R$ 100.000
      // Se estiver muito alto, pode ter sido inflado
      if (currentPrice < 100000) {
        skipped++;
        continue;
      }

      // Tentar reverter a inflação
      double originalPrice = currentPrice.toDouble();
      int inflationCount = 0;

      if (discountMode == 'percentage') {
        final multiplier = 1 / (1 - discountValue / 100);
        
        // Reverter multiplicações até chegar a um preço razoável
        while (originalPrice > 100000 && inflationCount < maxInflations) {
          originalPrice = originalPrice / multiplier;
          inflationCount++;
        }
      } else if (discountMode == 'fixed') {
        // Reverter adições
        while (originalPrice > 100000 && inflationCount < maxInflations) {
          originalPrice = originalPrice - discountValue;
          inflationCount++;
        }
      }

      if (inflationCount > 0 && originalPrice > 0 && originalPrice < 100000) {
        await doc.reference.update({'price': originalPrice});
        print('✅ Post ${doc.id}: corrigido R\$ ${currentPrice.toStringAsFixed(2)} → R\$ ${originalPrice.toStringAsFixed(2)} ($inflationCount inflações revertidas)');
        fixed++;
      } else {
        skipped++;
      }
    }

    print('🎉 Correção concluída!');
    print('📈 Corrigidos: $fixed posts');
    print('⏭️ Pulados: $skipped posts');
    print('📊 Total: ${postsQuery.docs.length} posts');

  } catch (e) {
    print('❌ Erro durante correção: $e');
    rethrow;
  }
}
