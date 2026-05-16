// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_params.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SearchParams {
  String get city => throw _privateConstructorUsedError;
  double get maxDistanceKm => throw _privateConstructorUsedError;
  bool get onlyConnections => throw _privateConstructorUsedError;
  String? get level => throw _privateConstructorUsedError;
  Set<String> get instruments => throw _privateConstructorUsedError;
  Set<String> get genres => throw _privateConstructorUsedError;
  String? get postType =>
      throw _privateConstructorUsedError; // 'musician', 'band', 'sales' ou 'hiring'
  Set<String> get availableFor =>
      throw _privateConstructorUsedError; // Disponibilidades/formatos
  bool? get hasYoutube => throw _privateConstructorUsedError;
  bool? get hasSpotify => throw _privateConstructorUsedError;
  bool? get hasDeezer =>
      throw _privateConstructorUsedError; // ✅ Campos de hiring (contratação)
  Set<String> get eventTypes => throw _privateConstructorUsedError;
  Set<String> get gigFormats => throw _privateConstructorUsedError;
  Set<String> get venueSetups => throw _privateConstructorUsedError;
  Set<String> get budgetRanges =>
      throw _privateConstructorUsedError; // ✅ Campos de sales (anúncios)
  Set<String> get salesTypes =>
      throw _privateConstructorUsedError; // 'Gravação', 'Ensaios', etc (multi)
  double? get minPrice =>
      throw _privateConstructorUsedError; // Faixa de preço mínima
  double? get maxPrice =>
      throw _privateConstructorUsedError; // Faixa de preço máxima
  bool? get onlyWithDiscount =>
      throw _privateConstructorUsedError; // Apenas anúncios com desconto
  String? get searchUsername => throw _privateConstructorUsedError;

  /// Create a copy of SearchParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchParamsCopyWith<SearchParams> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchParamsCopyWith<$Res> {
  factory $SearchParamsCopyWith(
          SearchParams value, $Res Function(SearchParams) then) =
      _$SearchParamsCopyWithImpl<$Res, SearchParams>;
  @useResult
  $Res call(
      {String city,
      double maxDistanceKm,
      bool onlyConnections,
      String? level,
      Set<String> instruments,
      Set<String> genres,
      String? postType,
      Set<String> availableFor,
      bool? hasYoutube,
      bool? hasSpotify,
      bool? hasDeezer,
      Set<String> eventTypes,
      Set<String> gigFormats,
      Set<String> venueSetups,
      Set<String> budgetRanges,
      Set<String> salesTypes,
      double? minPrice,
      double? maxPrice,
      bool? onlyWithDiscount,
      String? searchUsername});
}

/// @nodoc
class _$SearchParamsCopyWithImpl<$Res, $Val extends SearchParams>
    implements $SearchParamsCopyWith<$Res> {
  _$SearchParamsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? city = null,
    Object? maxDistanceKm = null,
    Object? onlyConnections = null,
    Object? level = freezed,
    Object? instruments = null,
    Object? genres = null,
    Object? postType = freezed,
    Object? availableFor = null,
    Object? hasYoutube = freezed,
    Object? hasSpotify = freezed,
    Object? hasDeezer = freezed,
    Object? eventTypes = null,
    Object? gigFormats = null,
    Object? venueSetups = null,
    Object? budgetRanges = null,
    Object? salesTypes = null,
    Object? minPrice = freezed,
    Object? maxPrice = freezed,
    Object? onlyWithDiscount = freezed,
    Object? searchUsername = freezed,
  }) {
    return _then(_value.copyWith(
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      maxDistanceKm: null == maxDistanceKm
          ? _value.maxDistanceKm
          : maxDistanceKm // ignore: cast_nullable_to_non_nullable
              as double,
      onlyConnections: null == onlyConnections
          ? _value.onlyConnections
          : onlyConnections // ignore: cast_nullable_to_non_nullable
              as bool,
      level: freezed == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as String?,
      instruments: null == instruments
          ? _value.instruments
          : instruments // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      genres: null == genres
          ? _value.genres
          : genres // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      postType: freezed == postType
          ? _value.postType
          : postType // ignore: cast_nullable_to_non_nullable
              as String?,
      availableFor: null == availableFor
          ? _value.availableFor
          : availableFor // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      hasYoutube: freezed == hasYoutube
          ? _value.hasYoutube
          : hasYoutube // ignore: cast_nullable_to_non_nullable
              as bool?,
      hasSpotify: freezed == hasSpotify
          ? _value.hasSpotify
          : hasSpotify // ignore: cast_nullable_to_non_nullable
              as bool?,
      hasDeezer: freezed == hasDeezer
          ? _value.hasDeezer
          : hasDeezer // ignore: cast_nullable_to_non_nullable
              as bool?,
      eventTypes: null == eventTypes
          ? _value.eventTypes
          : eventTypes // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      gigFormats: null == gigFormats
          ? _value.gigFormats
          : gigFormats // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      venueSetups: null == venueSetups
          ? _value.venueSetups
          : venueSetups // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      budgetRanges: null == budgetRanges
          ? _value.budgetRanges
          : budgetRanges // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      salesTypes: null == salesTypes
          ? _value.salesTypes
          : salesTypes // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      minPrice: freezed == minPrice
          ? _value.minPrice
          : minPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      maxPrice: freezed == maxPrice
          ? _value.maxPrice
          : maxPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      onlyWithDiscount: freezed == onlyWithDiscount
          ? _value.onlyWithDiscount
          : onlyWithDiscount // ignore: cast_nullable_to_non_nullable
              as bool?,
      searchUsername: freezed == searchUsername
          ? _value.searchUsername
          : searchUsername // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SearchParamsImplCopyWith<$Res>
    implements $SearchParamsCopyWith<$Res> {
  factory _$$SearchParamsImplCopyWith(
          _$SearchParamsImpl value, $Res Function(_$SearchParamsImpl) then) =
      __$$SearchParamsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String city,
      double maxDistanceKm,
      bool onlyConnections,
      String? level,
      Set<String> instruments,
      Set<String> genres,
      String? postType,
      Set<String> availableFor,
      bool? hasYoutube,
      bool? hasSpotify,
      bool? hasDeezer,
      Set<String> eventTypes,
      Set<String> gigFormats,
      Set<String> venueSetups,
      Set<String> budgetRanges,
      Set<String> salesTypes,
      double? minPrice,
      double? maxPrice,
      bool? onlyWithDiscount,
      String? searchUsername});
}

/// @nodoc
class __$$SearchParamsImplCopyWithImpl<$Res>
    extends _$SearchParamsCopyWithImpl<$Res, _$SearchParamsImpl>
    implements _$$SearchParamsImplCopyWith<$Res> {
  __$$SearchParamsImplCopyWithImpl(
      _$SearchParamsImpl _value, $Res Function(_$SearchParamsImpl) _then)
      : super(_value, _then);

  /// Create a copy of SearchParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? city = null,
    Object? maxDistanceKm = null,
    Object? onlyConnections = null,
    Object? level = freezed,
    Object? instruments = null,
    Object? genres = null,
    Object? postType = freezed,
    Object? availableFor = null,
    Object? hasYoutube = freezed,
    Object? hasSpotify = freezed,
    Object? hasDeezer = freezed,
    Object? eventTypes = null,
    Object? gigFormats = null,
    Object? venueSetups = null,
    Object? budgetRanges = null,
    Object? salesTypes = null,
    Object? minPrice = freezed,
    Object? maxPrice = freezed,
    Object? onlyWithDiscount = freezed,
    Object? searchUsername = freezed,
  }) {
    return _then(_$SearchParamsImpl(
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      maxDistanceKm: null == maxDistanceKm
          ? _value.maxDistanceKm
          : maxDistanceKm // ignore: cast_nullable_to_non_nullable
              as double,
      onlyConnections: null == onlyConnections
          ? _value.onlyConnections
          : onlyConnections // ignore: cast_nullable_to_non_nullable
              as bool,
      level: freezed == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as String?,
      instruments: null == instruments
          ? _value._instruments
          : instruments // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      genres: null == genres
          ? _value._genres
          : genres // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      postType: freezed == postType
          ? _value.postType
          : postType // ignore: cast_nullable_to_non_nullable
              as String?,
      availableFor: null == availableFor
          ? _value._availableFor
          : availableFor // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      hasYoutube: freezed == hasYoutube
          ? _value.hasYoutube
          : hasYoutube // ignore: cast_nullable_to_non_nullable
              as bool?,
      hasSpotify: freezed == hasSpotify
          ? _value.hasSpotify
          : hasSpotify // ignore: cast_nullable_to_non_nullable
              as bool?,
      hasDeezer: freezed == hasDeezer
          ? _value.hasDeezer
          : hasDeezer // ignore: cast_nullable_to_non_nullable
              as bool?,
      eventTypes: null == eventTypes
          ? _value._eventTypes
          : eventTypes // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      gigFormats: null == gigFormats
          ? _value._gigFormats
          : gigFormats // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      venueSetups: null == venueSetups
          ? _value._venueSetups
          : venueSetups // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      budgetRanges: null == budgetRanges
          ? _value._budgetRanges
          : budgetRanges // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      salesTypes: null == salesTypes
          ? _value._salesTypes
          : salesTypes // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      minPrice: freezed == minPrice
          ? _value.minPrice
          : minPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      maxPrice: freezed == maxPrice
          ? _value.maxPrice
          : maxPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      onlyWithDiscount: freezed == onlyWithDiscount
          ? _value.onlyWithDiscount
          : onlyWithDiscount // ignore: cast_nullable_to_non_nullable
              as bool?,
      searchUsername: freezed == searchUsername
          ? _value.searchUsername
          : searchUsername // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$SearchParamsImpl implements _SearchParams {
  const _$SearchParamsImpl(
      {required this.city,
      required this.maxDistanceKm,
      this.onlyConnections = false,
      this.level,
      final Set<String> instruments = const {},
      final Set<String> genres = const {},
      this.postType,
      final Set<String> availableFor = const {},
      this.hasYoutube,
      this.hasSpotify,
      this.hasDeezer,
      final Set<String> eventTypes = const {},
      final Set<String> gigFormats = const {},
      final Set<String> venueSetups = const {},
      final Set<String> budgetRanges = const {},
      final Set<String> salesTypes = const {},
      this.minPrice,
      this.maxPrice,
      this.onlyWithDiscount,
      this.searchUsername})
      : _instruments = instruments,
        _genres = genres,
        _availableFor = availableFor,
        _eventTypes = eventTypes,
        _gigFormats = gigFormats,
        _venueSetups = venueSetups,
        _budgetRanges = budgetRanges,
        _salesTypes = salesTypes;

  @override
  final String city;
  @override
  final double maxDistanceKm;
  @override
  @JsonKey()
  final bool onlyConnections;
  @override
  final String? level;
  final Set<String> _instruments;
  @override
  @JsonKey()
  Set<String> get instruments {
    if (_instruments is EqualUnmodifiableSetView) return _instruments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_instruments);
  }

  final Set<String> _genres;
  @override
  @JsonKey()
  Set<String> get genres {
    if (_genres is EqualUnmodifiableSetView) return _genres;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_genres);
  }

  @override
  final String? postType;
// 'musician', 'band', 'sales' ou 'hiring'
  final Set<String> _availableFor;
// 'musician', 'band', 'sales' ou 'hiring'
  @override
  @JsonKey()
  Set<String> get availableFor {
    if (_availableFor is EqualUnmodifiableSetView) return _availableFor;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_availableFor);
  }

// Disponibilidades/formatos
  @override
  final bool? hasYoutube;
  @override
  final bool? hasSpotify;
  @override
  final bool? hasDeezer;
// ✅ Campos de hiring (contratação)
  final Set<String> _eventTypes;
// ✅ Campos de hiring (contratação)
  @override
  @JsonKey()
  Set<String> get eventTypes {
    if (_eventTypes is EqualUnmodifiableSetView) return _eventTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_eventTypes);
  }

  final Set<String> _gigFormats;
  @override
  @JsonKey()
  Set<String> get gigFormats {
    if (_gigFormats is EqualUnmodifiableSetView) return _gigFormats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_gigFormats);
  }

  final Set<String> _venueSetups;
  @override
  @JsonKey()
  Set<String> get venueSetups {
    if (_venueSetups is EqualUnmodifiableSetView) return _venueSetups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_venueSetups);
  }

  final Set<String> _budgetRanges;
  @override
  @JsonKey()
  Set<String> get budgetRanges {
    if (_budgetRanges is EqualUnmodifiableSetView) return _budgetRanges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_budgetRanges);
  }

// ✅ Campos de sales (anúncios)
  final Set<String> _salesTypes;
// ✅ Campos de sales (anúncios)
  @override
  @JsonKey()
  Set<String> get salesTypes {
    if (_salesTypes is EqualUnmodifiableSetView) return _salesTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_salesTypes);
  }

// 'Gravação', 'Ensaios', etc (multi)
  @override
  final double? minPrice;
// Faixa de preço mínima
  @override
  final double? maxPrice;
// Faixa de preço máxima
  @override
  final bool? onlyWithDiscount;
// Apenas anúncios com desconto
  @override
  final String? searchUsername;

  @override
  String toString() {
    return 'SearchParams(city: $city, maxDistanceKm: $maxDistanceKm, onlyConnections: $onlyConnections, level: $level, instruments: $instruments, genres: $genres, postType: $postType, availableFor: $availableFor, hasYoutube: $hasYoutube, hasSpotify: $hasSpotify, hasDeezer: $hasDeezer, eventTypes: $eventTypes, gigFormats: $gigFormats, venueSetups: $venueSetups, budgetRanges: $budgetRanges, salesTypes: $salesTypes, minPrice: $minPrice, maxPrice: $maxPrice, onlyWithDiscount: $onlyWithDiscount, searchUsername: $searchUsername)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchParamsImpl &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.maxDistanceKm, maxDistanceKm) ||
                other.maxDistanceKm == maxDistanceKm) &&
            (identical(other.onlyConnections, onlyConnections) ||
                other.onlyConnections == onlyConnections) &&
            (identical(other.level, level) || other.level == level) &&
            const DeepCollectionEquality()
                .equals(other._instruments, _instruments) &&
            const DeepCollectionEquality().equals(other._genres, _genres) &&
            (identical(other.postType, postType) ||
                other.postType == postType) &&
            const DeepCollectionEquality()
                .equals(other._availableFor, _availableFor) &&
            (identical(other.hasYoutube, hasYoutube) ||
                other.hasYoutube == hasYoutube) &&
            (identical(other.hasSpotify, hasSpotify) ||
                other.hasSpotify == hasSpotify) &&
            (identical(other.hasDeezer, hasDeezer) ||
                other.hasDeezer == hasDeezer) &&
            const DeepCollectionEquality()
                .equals(other._eventTypes, _eventTypes) &&
            const DeepCollectionEquality()
                .equals(other._gigFormats, _gigFormats) &&
            const DeepCollectionEquality()
                .equals(other._venueSetups, _venueSetups) &&
            const DeepCollectionEquality()
                .equals(other._budgetRanges, _budgetRanges) &&
            const DeepCollectionEquality()
                .equals(other._salesTypes, _salesTypes) &&
            (identical(other.minPrice, minPrice) ||
                other.minPrice == minPrice) &&
            (identical(other.maxPrice, maxPrice) ||
                other.maxPrice == maxPrice) &&
            (identical(other.onlyWithDiscount, onlyWithDiscount) ||
                other.onlyWithDiscount == onlyWithDiscount) &&
            (identical(other.searchUsername, searchUsername) ||
                other.searchUsername == searchUsername));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        city,
        maxDistanceKm,
        onlyConnections,
        level,
        const DeepCollectionEquality().hash(_instruments),
        const DeepCollectionEquality().hash(_genres),
        postType,
        const DeepCollectionEquality().hash(_availableFor),
        hasYoutube,
        hasSpotify,
        hasDeezer,
        const DeepCollectionEquality().hash(_eventTypes),
        const DeepCollectionEquality().hash(_gigFormats),
        const DeepCollectionEquality().hash(_venueSetups),
        const DeepCollectionEquality().hash(_budgetRanges),
        const DeepCollectionEquality().hash(_salesTypes),
        minPrice,
        maxPrice,
        onlyWithDiscount,
        searchUsername
      ]);

  /// Create a copy of SearchParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchParamsImplCopyWith<_$SearchParamsImpl> get copyWith =>
      __$$SearchParamsImplCopyWithImpl<_$SearchParamsImpl>(this, _$identity);
}

abstract class _SearchParams implements SearchParams {
  const factory _SearchParams(
      {required final String city,
      required final double maxDistanceKm,
      final bool onlyConnections,
      final String? level,
      final Set<String> instruments,
      final Set<String> genres,
      final String? postType,
      final Set<String> availableFor,
      final bool? hasYoutube,
      final bool? hasSpotify,
      final bool? hasDeezer,
      final Set<String> eventTypes,
      final Set<String> gigFormats,
      final Set<String> venueSetups,
      final Set<String> budgetRanges,
      final Set<String> salesTypes,
      final double? minPrice,
      final double? maxPrice,
      final bool? onlyWithDiscount,
      final String? searchUsername}) = _$SearchParamsImpl;

  @override
  String get city;
  @override
  double get maxDistanceKm;
  @override
  bool get onlyConnections;
  @override
  String? get level;
  @override
  Set<String> get instruments;
  @override
  Set<String> get genres;
  @override
  String? get postType; // 'musician', 'band', 'sales' ou 'hiring'
  @override
  Set<String> get availableFor; // Disponibilidades/formatos
  @override
  bool? get hasYoutube;
  @override
  bool? get hasSpotify;
  @override
  bool? get hasDeezer; // ✅ Campos de hiring (contratação)
  @override
  Set<String> get eventTypes;
  @override
  Set<String> get gigFormats;
  @override
  Set<String> get venueSetups;
  @override
  Set<String> get budgetRanges; // ✅ Campos de sales (anúncios)
  @override
  Set<String> get salesTypes; // 'Gravação', 'Ensaios', etc (multi)
  @override
  double? get minPrice; // Faixa de preço mínima
  @override
  double? get maxPrice; // Faixa de preço máxima
  @override
  bool? get onlyWithDiscount; // Apenas anúncios com desconto
  @override
  String? get searchUsername;

  /// Create a copy of SearchParams
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchParamsImplCopyWith<_$SearchParamsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
