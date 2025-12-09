/// Profile types available in the app
enum ProfileType {
  /// Individual musician profile
  musician('musician', 'Músico'),
  
  /// Band/group profile
  band('band', 'Banda'),
  
  /// Musical space/venue profile (studios, stores, venues, etc.)
  space('space', 'Espaço');

  const ProfileType(this.value, this.label);

  /// Firestore value representation
  final String value;
  
  /// User-friendly label
  final String label;

  /// Parse ProfileType from string value
  static ProfileType fromString(String value) {
    return ProfileType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ProfileType.musician,
    );
  }
}

/// Space subtypes for ProfileType.space
enum SpaceType {
  recordingStudio('recording_studio', 'Estúdio de Gravação/Ensaios'),
  instrumentStore('instrument_store', 'Loja de Instrumentos'),
  barVenue('bar_venue', 'Bar/Casa de Show'),
  musicSchool('music_school', 'Escola de Música'),
  eventProducer('event_producer', 'Produtora de Eventos'),
  equipmentRental('equipment_rental', 'Aluguel de Equipamento'),
  luthier('luthier', 'Luthieria'),
  recordLabel('label', 'Selo/Distribuidora'),
  other('other', 'Outro Espaço Musical');

  const SpaceType(this.value, this.label);

  final String value;
  final String label;

  static SpaceType fromString(String value) {
    return SpaceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SpaceType.other,
    );
  }
}
