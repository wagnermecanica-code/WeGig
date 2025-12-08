import 'package:cloud_firestore/cloud_firestore.dart';

/// Data object that represents the values collected in the post form.
///
/// UI widgets should populate this structure and hand it to the
/// PostNotifier, which is responsible for orchestrating uploads,
/// validations and persistence.
class PostFormInput {
  const PostFormInput({
    this.postId,
    required this.type,
    required this.content,
    required this.location,
    required this.city,
    this.neighborhood,
    this.state,
    this.level,
    this.genres = const [],
    this.selectedInstruments = const [],
    this.availableFor = const [],
    this.youtubeLink,
    this.photoPaths = const [],
    this.createdAt,
    this.expiresAt,
    // Sales-specific fields
    this.title,
    this.salesType,
    this.price,
    this.discountMode,
    this.discountValue,
    this.promoStartDate,
    this.promoEndDate,
    this.whatsappNumber,
  });

  /// When null we are creating a new post.
  final String? postId;
  final String type;
  final String content;
  final GeoPoint location;
  final String city;
  final String? neighborhood;
  final String? state;
  
  // Musician/Band fields (nullable for sales)
  final String? level;
  final List<String> genres;
  final List<String> selectedInstruments;
  final List<String> availableFor;
  final String? youtubeLink;
  
  /// Lista de caminhos de fotos (locais ou URLs remotas).
  /// Paths que começam com 'http' são URLs existentes, outros são arquivos locais.
  final List<String> photoPaths;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  // Sales-specific fields
  final String? title;
  final String? salesType;
  final double? price;
  final String? discountMode; // 'none', 'percentage', 'fixed'
  final double? discountValue;
  final DateTime? promoStartDate;
  final DateTime? promoEndDate;
  final String? whatsappNumber;

  bool get isEditing => postId != null;
  bool get isSales => type == 'sales';
  
  /// Retorna apenas os caminhos locais (arquivos que precisam de upload).
  List<String> get localPhotoPaths => 
      photoPaths.where((p) => !p.startsWith('http')).toList();
  
  /// Retorna apenas as URLs existentes (já estão no Storage).
  List<String> get existingPhotoUrls => 
      photoPaths.where((p) => p.startsWith('http')).toList();
}
