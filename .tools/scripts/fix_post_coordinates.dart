#!/usr/bin/env dart

import 'dart:convert';
import 'package:http/http.dart' as http;

// Script para corrigir coordenadas de posts no Firestore
// As coordenadas estão invertidas (lat/lng trocadas ou erradas)

void main() async {
  print('=== Corrigir Coordenadas de Posts ===\n');
  
  // CEPs conhecidos de São Paulo
  final ceps = {
    'São Paulo': '01310-100', // Av. Paulista
  };
  
  print('Este script ajudará a corrigir as coordenadas dos posts.');
  print('');
  print('Passos:');
  print('1. Acesse o Firebase Console');
  print('2. Vá em Firestore Database > posts');
  print('3. Para cada post com coordenadas erradas:');
  print('   a) Clique no post');
  print('   b) Edite o campo "location"');
  print('   c) Use as coordenadas corretas abaixo:\n');
  
  for (final entry in ceps.entries) {
    final city = entry.key;
    final cep = entry.value;
    
    print('--- $city (CEP: $cep) ---');
    
    final coords = await getCoordsFromCep(cep);
    if (coords != null) {
      print('Latitude:  ${coords['lat']}');
      print('Longitude: ${coords['lng']}');
      print('');
    } else {
      print('Erro ao buscar coordenadas');
      print('');
    }
  }
  
  print('\n=== Coordenadas Corretas por Cidade ===');
  print('São Paulo:   latitude: -23.5505, longitude: -46.6333');
  print('Guararema:   latitude: -23.4097, longitude: -46.0354');
  print('');
  print('IMPORTANTE: No Firestore, o campo "location" deve ser do tipo geopoint');
  print('            com latitude e longitude nesta ordem!');
}

Future<Map<String, double>?> getCoordsFromCep(String cep) async {
  try {
    final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    final url = 'https://viacep.com.br/ws/$cleanCep/json/';
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;
    
    final data = json.decode(response.body);
    if (data['erro'] == true) return null;
    
    // ViaCEP não retorna coordenadas, vamos usar valores conhecidos
    // Em produção, usaria Google Geocoding API
    return {
      'lat': -23.5505,
      'lng': -46.6333,
    };
  } catch (e) {
    print('Erro ao buscar CEP: $e');
    return null;
  }
}
