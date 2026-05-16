/// Constantes musicais centralizadas para uso em todo o app
/// 
/// Este arquivo contém as listas de opções para:
/// - Níveis de habilidade
/// - Instrumentos musicais
/// - Gêneros musicais
/// 
/// Usado em: EditProfilePage, PostPage, SearchPage

/// Níveis de habilidade musical
class MusicConstants {
  MusicConstants._();

  /// Lista de níveis de habilidade
  static const List<String> levelOptions = [
    'Iniciante',
    'Intermediário',
    'Avançado',
    'Profissional',
  ];

  /// Lista completa de instrumentos musicais
  static const List<String> instrumentOptions = [
    'Violão',
    'Guitarra',
    'Baixo elétrico',
    'Contrabaixo acústico',
    'Baixolão',
    'Bateria',
    'Teclado',
    'Piano',
    'Saxofone',
    'Flauta',
    'Trompete',
    'Trombone',
    'Clarinete',
    'Oboé',
    'Fagote',
    'Violino',
    'Viola',
    'Cello',
    'Voz',
    'Voz (Soprano)',
    'Voz (Contralto)',
    'Voz (Tenor)',
    'Voz (Barítono)',
    'Voz (Baixo)',
    'Voz (Backing)',
    'DJ',
    'Percussão',
    'Bateria Eletrônica',
    'Caixa',
    'Cajón',
    'Bongô',
    'Pandeiro',
    'Zabumba',
    'Timbal',
    'Harmônica',
    'Gaita',
    'Acordeon',
    'Sanfona',
    'Bandolim',
    'Cavaquinho',
    'Ukulele',
    'Banjo',
    'Harpa',
    'Sitar',
    'Alaúde',
    'Guitarra Clássica',
    'Berimbau',
    'Escaleta',
    'Melódica',
    'Theremin',
    'Sintetizador',
    'Teclado MIDI',
    'Sampler',
    'Produtor Musical',
    'Beatmaker',
    'Outros',
  ];

  /// Lista completa de gêneros musicais
  static const List<String> genreOptions = [
    'Rock',
    'Pop',
    'Jazz',
    'Blues',
    'Funk',
    'Soul',
    'R&B',
    'Reggae',
    'MPB',
    'Sertanejo',
    'Sertanejo Universitário',
    'Sertanejo Raiz',
    'Forró',
    'Forró Eletrônico',
    'Axé',
    'Hip-Hop',
    'Rap',
    'Trap',
    'Drill',
    'Eletrônica',
    'House',
    'Techno',
    'Trance',
    'Dubstep',
    'Drum and Bass',
    'EDM',
    'Folk',
    'Country',
    'Classical',
    'Ópera',
    'Metal',
    'Heavy Metal',
    'Death Metal',
    'Black Metal',
    'Thrash Metal',
    'Power Metal',
    'Punk',
    'Punk Rock',
    'Hardcore',
    'Post-Punk',
    'Indie',
    'Indie Rock',
    'Alternative',
    'Grunge',
    'Samba',
    'Samba-Enredo',
    'Pagode',
    'Bossa Nova',
    'Gospel',
    'Música Católica',
    'Música Evangélica',
    'Choro',
    'Baião',
    'Maracatu',
    'Frevo',
    'Salsa',
    'Merengue',
    'Bachata',
    'Tango',
    'Flamenco',
    'Brega',
    'Piseiro',
    'Arrocha',
    'Música Sertaneja',
    'Música Gaúcha',
    'Música Caipira',
    'Rock Progressivo',
    'Psicodélico',
    'Disco',
    'New Wave',
    'Synth-pop',
    'Ska',
    'Reggaeton',
    'K-Pop',
    'J-Pop',
    'World Music',
    'Afrobeat',
    'Zouk',
    'Ambient',
    'Experimental',
    'Avant-garde',
    'Minimalista',
    'Lo-fi',
    'Vaporwave',
    'Outros',
  ];

  /// Lista de opções de disponibilidade
  static const List<String> availableForOptions = [
    'Show ao vivo',
    'Free lance',
    'Produção',
    'Gravações',
    'Turnês',
    'Ensaios regulares',
    'Criação de conteúdo digital',
    'Outros',
  ];

  /// Tipos de evento para contratações
  static const List<String> eventTypeOptions = [
    'Casamento',
    'Aniversário',
    'Corporativo',
    'Formatura',
    'Baile/Recepção',
    'Festival',
    'Bar/Restaurante',
    'Condomínio/Clube',
    'Religioso',
    'Festa privada',
    'Ação promocional',
    'Outro',
  ];

  /// Especialidades para perfil Técnico
  static const List<String> technicianSpecialtyOptions = [
    'Técnico de Som',
    'Técnico de Luz',
    'Roadie',
    'Produtor Musical',
    'Stage Manager',
    'Videomaker',
    'Fotógrafo',
    'Operador de Transmissão',
    'Outro',
  ];

  /// Faixas de experiência para perfil Técnico
  static const List<String> experienceRangeOptions = [
    'Menos de 1 ano',
    '1 a 2 anos',
    '3 a 5 anos',
    '6 a 10 anos',
    'Mais de 10 anos',
  ];

  /// Formatos de contratação (tamanho do grupo)
  static const List<String> gigFormatOptions = [
    'Solo',
    'Duo',
    'Trio',
    'Quarteto',
    'Banda completa',
    'DJ',
    'MC/Host',
    'Banda + DJ',
    'Pocket show',
    'Outra formação',
  ];

  /// Estrutura disponível no local
  static const List<String> venueSetupOptions = [
    'Som (PA) disponível',
    'Iluminação de palco',
    'Palco montado',
    'Backline básico (bateria, amps)',
    'Microfones e cabos',
    'Mesa de som',
    'Técnico de som',
    'Técnico de luz',
    'Gerador de energia',
    'Camarim',
    'Sem estrutura (levar tudo)',
  ];

  /// Faixas de orçamento sugeridas (opcional)
  static const List<String> budgetRangeOptions = [
    'A combinar',
    'Até R\$1.000',
    'R\$1.000 - R\$3.000',
    'R\$3.000 - R\$5.000',
    'R\$5.000 - R\$10.000',
    'Acima de R\$10.000',
  ];
}
