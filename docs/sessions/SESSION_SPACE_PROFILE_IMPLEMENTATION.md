# Space Profile Type Implementation - Complete

**Date**: 2025-01-XX  
**Status**: ✅ COMPLETED  
**Branch**: main

## Overview

Implemented a third profile type "Espaço" (Space) in addition to existing Musician and Band profiles. This allows musical venues, stores, studios, and other music-related businesses to create profiles on the platform.

## Implementation Summary

### 1. ProfileType Enum Creation

**Location**: `packages/core_ui/lib/features/profile/domain/entities/profile_type.dart`

- Created `ProfileType` enum with three values: `musician`, `band`, `space`
- Created `SpaceType` enum with 9 subtypes:
  - Estúdio de Gravação/Ensaios
  - Loja de Instrumentos
  - Bar/Casa de Show
  - Escola de Música
  - Produtora de Eventos
  - Aluguel de Equipamento
  - Luthieria
  - Selo/Distribuidora
  - Outro Espaço Musical

### 2. ProfileEntity Updates

**Location**: `packages/core_ui/lib/features/profile/domain/entities/profile_entity.dart`

#### Added Fields:

- `profileType`: ProfileType (new, default: ProfileType.musician)
- `spaceType`: String? (space category)
- `phone`: String? (required for spaces)
- `operatingHours`: String? (optional)
- `website`: String? (optional)
- `amenities`: List<String>? (Wi-Fi, Estacionamento, Ar-condicionado, Acesso para cadeirantes)

#### Maintained Backward Compatibility:

- Kept `isBand` field (marked as @Deprecated)
- `fromFirestore`: Auto-converts legacy `isBand` to `profileType`
- `toFirestore`: Saves both `profileType` and `isBand` for compatibility

#### Updated Computed Properties:

- `ageLabel`: Returns "Idade", "Tempo de formação", or "Ano de fundação" based on type
- `ageOrFormationText`: Adjusted for all three profile types
- Added helpers: `isMusician`, `isBandProfile`, `isSpace`

### 3. EditProfilePage Refactoring

**Location**: `packages/app/lib/features/profile/presentation/pages/edit_profile_page.dart`

#### State Changes:

- Replaced `bool? _isBand` with `ProfileType? _profileType`
- Added Space-specific controllers:
  - `_phoneController`: TextEditingController
  - `_operatingHoursController`: TextEditingController
  - `_websiteController`: TextEditingController
- Added Space-specific state:
  - `_selectedSpaceType`: String?
  - `_selectedAmenities`: Set<String>

#### UI Updates:

- **\_buildTypologyBlock**: Now shows 3 cards (Músico, Banda, Espaço) in a Row
- **Conditional Fields**:
  - Skills block (instruments/genres/level) only shown for Musicians/Bands
  - Space details block only shown for Spaces
- **Form Field Hints**: Updated to handle all three types:
  - Name: "Seu nome" / "Nome da banda" / "Nome do espaço"
  - Bio: Adapted hints for each type
  - BirthYear: "Ano de nascimento" / "Ano de formação" / "Ano de fundação"

#### New Space Details Block:

Created `_buildSpaceDetailsBlock()` widget with:

1. **Space Type Dropdown** (required): 9 options from SpaceType enum
2. **Phone/WhatsApp** (required): Validated for 10-11 digits
3. **Operating Hours** (optional): Free text field
4. **Website** (optional): URL validation
5. **Amenities** (optional): 4 FilterChip toggles

#### Validation Logic:

- Validates profile type is selected
- For Space profiles:
  - Phone/WhatsApp is required
  - Space type is required
  - Website must start with http:// or https://

#### Save Logic:

- Profile creation: Sets `profileType` and Space-specific fields
- Profile update: Preserves all Space fields
- Maintains backward compatibility by setting `isBand` field

### 4. Core UI Export

**Location**: `packages/core_ui/lib/core_ui.dart`

- Added export for `profile_type.dart` to make enums available app-wide

## Fields Reused (8 total)

1. **photo**: Existing `_photoUrl` + `_pickAndCropProfileImage`
2. **name**: `_nameController`
3. **bio**: `_bioController`
4. **location**: `_locationController` + TypeAheadField with Nominatim
5. **Instagram**: `_instagramController`
6. **TikTok**: `_tiktokController`
7. **YouTube**: `_youtubeController`
8. **username**: `_profileUsernameController`

## New Fields (7 total)

9. **Space Type**: Dropdown with 9 options (required)
10. **Phone/WhatsApp**: Text field with validation (required)
11. **Operating Hours**: Text field (optional)
12. **Website**: URL field with validation (optional)
    13-16. **Amenities**: 4 FilterChip toggles (optional)

## Testing Results

### Build Status

- ✅ `melos run build_runner`: SUCCESS
- ✅ `flutter analyze`: PASSED (no ProfileType/SpaceType errors)
- ⚠️ Existing warnings/infos unrelated to this implementation remain

### Backward Compatibility

- ✅ Existing musician/band profiles load correctly
- ✅ Legacy `isBand` field preserved in Firestore
- ✅ New `profileType` field auto-synced with `isBand`

## Migration Path

### Existing Profiles

- No migration needed - `fromFirestore` automatically converts:
  - `isBand: false` → `ProfileType.musician`
  - `isBand: true` → `ProfileType.band`
- New profiles save both fields for compatibility

### Future Cleanup (Optional)

After all profiles migrated:

1. Remove `@Deprecated` annotation from `isBand`
2. Update `fromFirestore` to require `profileType`
3. Remove `isBand` field from entity

## UI Flow

### Profile Creation

1. User selects type: Músico / Banda / **Espaço**
2. If Espaço selected:
   - Form shows Space-specific fields
   - Skills/instruments hidden
   - Space type dropdown becomes required
   - Phone field becomes required
3. Validation enforces Space requirements
4. Save creates profile with `profileType: ProfileType.space`

### Profile Viewing (Future Enhancement)

- Profile cards should show Space icon (Iconsax.building)
- Space profiles display phone, hours, website, amenities
- No instruments/genres shown for Spaces

## Files Modified

### Core UI Package (`packages/core_ui/`)

1. `lib/features/profile/domain/entities/profile_type.dart` (NEW)
2. `lib/features/profile/domain/entities/profile_entity.dart` (MODIFIED)
3. `lib/core_ui.dart` (MODIFIED - added export)

### App Package (`packages/app/`)

4. `lib/features/profile/presentation/pages/edit_profile_page.dart` (MODIFIED)

## Next Steps (Optional Enhancements)

### 1. Profile Viewing UI

- Update `view_profile_page.dart` to display Space fields
- Add Space-specific layout/icons
- Hide musician/band fields for Spaces

### 2. Search & Filtering

- Add Space type to search filters
- Enable filtering by amenities
- Show operating hours in search results

### 3. Post Visibility

- Consider if Spaces can create posts
- Or limit to profile-only presence

### 4. Analytics

- Track Space profile creation rate
- Monitor Space type distribution

## Known Limitations

1. **No UI for Space Profile Viewing**: View profile page not yet updated
2. **Profile Switcher**: May need icon update for Spaces
3. **Search**: Space filtering not yet implemented
4. **Posts**: Space post behavior undefined

## References

- Original request: User specification for 15-field Space profile
- Related files: `profile_entity.dart`, `edit_profile_page.dart`
- Enum pattern: Following Freezed + enum best practices

---

**Implementation completed by GitHub Copilot**  
**Zero breaking changes to existing musician/band functionality**
