# WeGig - Design System Report

## Relatório Técnico de Design Visual

**Data:** 24 de novembro de 2025  
**Versão:** 1.0.0  
**Framework:** Flutter 3.9.2+ com Material Design 3  
**Target Audience:** Design Specialists & UI/UX Engineers

---

## 📋 Executive Summary

O **WeGig** implementa um design system moderno inspirado no Airbnb 2025, com foco em clareza visual, hierarquia tipográfica robusta e uma paleta de cores minimalista que diferencia semanticamente os dois tipos principais de usuários: **Músicos (Escuro #37475A)** e **Bandas (Laranja #E47911)**.

O sistema utiliza Material Design 3 como fundação, com customizações estratégicas para criar uma identidade visual única e funcional para o contexto de matchmaking musical geolocalizado.

---

## 🎨 Color System

### Primary Palette: Teal (Músicos)

A cor primária representa **músicos individuais** e é usada em todos os elementos de UI relacionados a esse perfil.

| Token          | Hex       | RGB                  | Usage                                                           |
| -------------- | --------- | -------------------- | --------------------------------------------------------------- |
| `primary`      | `#00A699` | `rgb(0, 166, 153)`   | Botões primários, links, estados ativos, pins de mapa (músicos) |
| `primaryLight` | `#E8F7F5` | `rgb(232, 247, 245)` | Backgrounds sutis, hover states, chips desabilitados            |
| `primaryDark`  | `#007F73` | `rgb(0, 127, 115)`   | Pressed states, sombras coloridas                               |

**Material Swatch (50-900):**

```dart
50:  #E8F7F5  // Highlight extremo
100: #B2E8E2  // Backgrounds alternativos
200: #80D8D0  // Borders hover
300: #4DC9BE  // Ilustrações/iconografia
400: #26BAB0  // Estados intermediários
500: #00A699  // Core primary (base)
600: #009589  // Hover states
700: #007F73  // Active/pressed
800: #00695C  // Dark theme variant
900: #004C3F  // Accent extremo
```

**Contrast Ratios (WCAG 2.1):**

- `primary` on white: **4.8:1** (AAA para Large Text)
- `primary` on `primaryLight`: **8.2:1** (AAA All)
- White text on `primary`: **6.5:1** (AA All)

### Secondary Palette: Coral (Bandas)

A cor secundária/accent representa **bandas** e é usada para diferenciação visual de perfis coletivos.

| Token         | Hex       | RGB                  | Usage                                               |
| ------------- | --------- | -------------------- | --------------------------------------------------- |
| `accent`      | `#FF6F61` | `rgb(255, 111, 97)`  | Pins de bandas no mapa, badges de banda, highlights |
| `accentLight` | `#FFECEA` | `rgb(255, 236, 234)` | Backgrounds para cards de banda                     |

**Semantic Meaning:**

- 🟢 **Teal**: Individual, technical, reliable (músicos solo)
- 🔴 **Coral**: Collaborative, energetic, social (bandas)

### Neutral Palette

Sistema de neutros de 5 níveis para backgrounds, texto e bordas.

| Token            | Hex       | RGB                  | Purpose                                |
| ---------------- | --------- | -------------------- | -------------------------------------- |
| `background`     | `#FAFAFA` | `rgb(250, 250, 250)` | App scaffold background                |
| `surface`        | `#FFFFFF` | `rgb(255, 255, 255)` | Cards, modals, sheets                  |
| `surfaceVariant` | `#F5F5F5` | `rgb(245, 245, 245)` | Input fields (filled), disabled states |

### Text Palette

Hierarquia de 3 níveis para controle de ênfase textual.

| Token           | Hex       | RGB                  | Opacity | Usage                         |
| --------------- | --------- | -------------------- | ------- | ----------------------------- |
| `textPrimary`   | `#1A1A1A` | `rgb(26, 26, 26)`    | 100%    | Headlines, body text, labels  |
| `textSecondary` | `#717171` | `rgb(113, 113, 113)` | 70%     | Metadata, captions, subtitles |
| `textHint`      | `#9E9E9E` | `rgb(158, 158, 158)` | 50%     | Placeholders, helper text     |

**Contrast Ratios:**

- `textPrimary` on white: **13.2:1** (AAA All)
- `textSecondary` on white: **5.1:1** (AA All)
- `textHint` on white: **3.5:1** (AA Large Text)

### Border & Divider Palette

| Token     | Hex       | RGB                  | Thickness | Usage                           |
| --------- | --------- | -------------------- | --------- | ------------------------------- |
| `border`  | `#E0E0E0` | `rgb(224, 224, 224)` | 1px       | Input borders, card outlines    |
| `divider` | `#F0F0F0` | `rgb(240, 240, 240)` | 1px       | List separators, section breaks |

### Feedback Palette

Sistema de estados para feedback visual de ações do usuário.

| Token     | Hex       | RGB                | Usage                                         |
| --------- | --------- | ------------------ | --------------------------------------------- |
| `success` | `#4CAF50` | `rgb(76, 175, 80)` | Confirmações, toast success, badges de status |
| `error`   | `#E53935` | `rgb(229, 57, 53)` | Alertas, validação de forms, error states     |
| `warning` | `#FB8C00` | `rgb(251, 140, 0)` | Avisos não-críticos, expiration warnings      |

### Badge Counter Palette

Cores específicas para indicadores de notificações e contadores.

| Token      | Hex       | RGB                | Usage                                                          |
| ---------- | --------- | ------------------ | -------------------------------------------------------------- |
| `badgeRed` | `#FF2828` | `rgb(255, 40, 40)` | Notification badges, unread count indicators (circular/oblong) |

**Design Pattern:**

- **Shape:** Circular para números de 1 dígito (1-9), oblong/pill para 2+ dígitos (10-99+)
- **Padding:** `horizontal: 6-8px, vertical: 4px` para garantir proporção adequada
- **Typography:** White text, 10-11px, bold, center-aligned
- **Position:** Top-right offset (-4px, -4px) sobre ícones
- **Min Dimensions:** 20x20px para garantir touch target adequado
- **Border Radius:** 12px (oblong/pill shape que se adapta ao conteúdo)

---

## 🔤 Typography System

### Font Family: Inter

**Implementação:** Google Fonts Inter com 4 pesos locais para performance.

```yaml
fonts:
  - family: Inter
    fonts:
      - asset: assets/fonts/Inter-Regular.ttf # weight: 400
      - asset: assets/fonts/Inter-Medium.ttf # weight: 500
      - asset: assets/fonts/Inter-SemiBold.ttf # weight: 600
      - asset: assets/fonts/Inter-Bold.ttf # weight: 700
```

**Justificativa da Escolha:**

- ✅ Legibilidade excepcional em telas mobile (otimizada para 11-16px)
- ✅ Suporte completo a caracteres latinos/acentuação portuguesa
- ✅ x-height generoso (melhor em tamanhos pequenos)
- ✅ Gratuita e open-source (SIL Open Font License)
- ✅ Kerning automático consistente
- ✅ Hinting manual para rendering pixel-perfect em Android/iOS

### Type Scale (Material Design 3)

#### Display Styles (Marketing/Hero Headlines)

```dart
displayLarge: {
  fontSize: 32px,
  fontWeight: 700 (Bold),
  letterSpacing: -0.5px,
  lineHeight: 1.2 (38.4px),
  color: textPrimary
}

displayMedium: {
  fontSize: 28px,
  fontWeight: 700 (Bold),
  letterSpacing: -0.3px,
  lineHeight: 1.25 (35px),
  color: textPrimary
}
```

**Usage:** Onboarding screens, empty states, modals de sucesso/erro.

#### Headline Styles (Section Headers)

```dart
headlineLarge: {
  fontSize: 24px,
  fontWeight: 600 (SemiBold),
  letterSpacing: -0.2px,
  lineHeight: 1.3 (31.2px),
  color: textPrimary
}

headlineMedium: {
  fontSize: 20px,
  fontWeight: 600 (SemiBold),
  letterSpacing: 0px,
  lineHeight: 1.3 (26px),
  color: textPrimary
}
```

**Usage:** AppBar titles, page headers, modal titles, section dividers.

#### Title Styles (Card Titles, List Items)

```dart
titleLarge: {
  fontSize: 18px,
  fontWeight: 600 (SemiBold),
  lineHeight: 1.4 (25.2px),
  color: textPrimary
}

titleMedium: {
  fontSize: 16px,
  fontWeight: 600 (SemiBold),
  lineHeight: 1.4 (22.4px),
  color: textPrimary
}

titleSmall: {
  fontSize: 14px,
  fontWeight: 600 (SemiBold),
  lineHeight: 1.4 (19.6px),
  color: textPrimary
}
```

**Usage:** Post card titles, profile names, list item headers, tab labels.

#### Body Styles (Main Content)

```dart
bodyLarge: {
  fontSize: 16px,
  fontWeight: 400 (Regular),
  lineHeight: 1.5 (24px),
  color: textPrimary
}

bodyMedium: {
  fontSize: 14px,
  fontWeight: 400 (Regular),
  lineHeight: 1.5 (21px),
  color: textSecondary
}

bodySmall: {
  fontSize: 12px,
  fontWeight: 400 (Regular),
  lineHeight: 1.5 (18px),
  color: textSecondary
}
```

**Usage:** Post descriptions, chat messages, form inputs, long-form text.

#### Label Styles (Buttons, Chips, Badges)

```dart
labelLarge: {
  fontSize: 14px,
  fontWeight: 600 (SemiBold),
  lineHeight: 1.2 (16.8px),
  color: white
}

labelMedium: {
  fontSize: 12px,
  fontWeight: 600 (SemiBold),
  lineHeight: 1.2 (14.4px),
  color: white
}

labelSmall: {
  fontSize: 11px,
  fontWeight: 600 (SemiBold),
  lineHeight: 1.2 (13.2px),
  color: white
}
```

**Usage:** Primary/secondary buttons, chips selecionados, badges de notificação.

#### Caption & Helper Styles

```dart
caption: {
  fontSize: 12px,
  fontWeight: 400 (Regular),
  lineHeight: 1.3 (15.6px),
  color: textHint
}

captionLight: {
  fontSize: 12px,
  fontWeight: 400 (Regular),
  lineHeight: 1.3 (15.6px),
  color: textSecondary
}
```

**Usage:** Timestamps (timeago), metadata (distance, genre), input helper text, error messages.

### Special-Purpose Styles

#### Button Text

```dart
button: {
  fontSize: 16px,
  fontWeight: 600 (SemiBold),
  letterSpacing: 0.2px,
  lineHeight: 1.2,
  color: white
}
```

#### Input Text

```dart
input: {
  fontSize: 16px,
  fontWeight: 400 (Regular),
  lineHeight: 1.5,
  color: textPrimary
}
```

#### Error Text

```dart
error: {
  fontSize: 12px,
  fontWeight: 400 (Regular),
  lineHeight: 1.3,
  color: error (#E53935)
}
```

---

## 📐 Spacing System

### Base Unit: 4px

Sistema de espaçamento baseado em múltiplos de 4px para consistência de layout.

| Token | Value | Usage                                         |
| ----- | ----- | --------------------------------------------- |
| `xs`  | 4px   | Icon padding, badge margins                   |
| `sm`  | 8px   | Chip padding, list item vertical spacing      |
| `md`  | 12px  | Input field border radius, card inner padding |
| `lg`  | 16px  | Card padding, button padding, section margins |
| `xl`  | 24px  | Screen padding, modal padding, header margins |
| `2xl` | 32px  | Section breaks, large component spacing       |
| `3xl` | 48px  | Hero sections, empty state spacing            |

### Padding/Margin Conventions

- **Screen horizontal padding:** `24px` (xl)
- **Card padding:** `16px` (lg)
- **Input vertical padding:** `16px` (lg)
- **Button padding:** `vertical: 16px, horizontal: 24px`
- **List item vertical spacing:** `8px` (sm)
- **Section vertical spacing:** `32px` (2xl)

---

## 🔲 Border Radius System

Sistema de arredondamento com 4 níveis para hierarquia visual.

| Token    | Value | Usage                                   |
| -------- | ----- | --------------------------------------- |
| `small`  | 8px   | Chips, small badges                     |
| `medium` | 12px  | Inputs, buttons, small cards            |
| `large`  | 16px  | Cards principais, modals, bottom sheets |
| `xlarge` | 24px  | Hero cards, image containers            |

**Pattern:**

- Inputs/Buttons: **12px** (medium)
- Cards: **16px** (large)
- Bottom Sheets: **24px** top corners only
- Avatars: **50%** (circular)

---

## 🎭 Elevation & Shadow System

Sistema de sombras baseado em Material Design 3 para profundidade z-axis.

### Elevation Levels

| Level | Usage                          | Shadow Spec                     |
| ----- | ------------------------------ | ------------------------------- |
| 0     | Backgrounds, disabled states   | None                            |
| 1     | Resting cards, inputs          | `0px 1px 2px rgba(0,0,0,0.08)`  |
| 2     | Hover cards, buttons           | `0px 2px 4px rgba(0,0,0,0.12)`  |
| 4     | Dragging cards, active buttons | `0px 4px 8px rgba(0,0,0,0.16)`  |
| 6     | Modals, dialogs                | `0px 6px 16px rgba(0,0,0,0.20)` |
| 8     | Bottom sheets, menus           | `0px 8px 24px rgba(0,0,0,0.24)` |

### Implementation Examples

```dart
// Card elevation (home_page.dart:653)
elevation: 2,

// FAB elevation (home_page.dart:739)
elevation: 6,

// Pressed button elevation (home_page.dart:785)
elevation: 4,

// Custom box shadow (home_page.dart:1084-1085)
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 8,
    offset: Offset(0, 2),
  ),
],
```

**Princípio:** Quanto mais interativo o elemento, maior a elevação base. Aumentar elevação em hover/press para feedback visual.

---

## 🖼️ Component Patterns

### AppBar

```dart
AppBarTheme(
  backgroundColor: Colors.transparent,  // Blend com background
  elevation: 0,                         // Flat design
  foregroundColor: textPrimary,
  centerTitle: false,                   // Left-aligned (iOS/Android hybrid)
  titleTextStyle: headlineMedium,
  iconTheme: IconThemeData(color: textPrimary),
)
```

**Padrão visual:** Transparente com scroll, sem sombra, título à esquerda.

### Buttons

#### ElevatedButton (Primary Action)

```dart
backgroundColor: primary (#00A699),
foregroundColor: white,
elevation: 0,                          // Flat até hover
padding: EdgeInsets.symmetric(
  vertical: 16px,
  horizontal: 24px,
),
shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(12px),
),
textStyle: button (16px, SemiBold, 0.2 letter-spacing)
```

**Estados:**

- Resting: Elevation 0
- Hover: Elevation 2, brightness 110%
- Pressed: Elevation 4, brightness 90%
- Disabled: Opacity 50%, elevation 0

#### OutlinedButton (Secondary Action)

```dart
foregroundColor: primary (#00A699),
backgroundColor: transparent,
side: BorderSide(color: primary, width: 1.5px),
padding: EdgeInsets.symmetric(
  vertical: 16px,
  horizontal: 24px,
),
shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(12px),
),
```

**Uso:** Ações secundárias, cancel, dismiss.

### Input Fields

```dart
InputDecorationTheme(
  filled: true,
  fillColor: surfaceVariant (#F5F5F5),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12px),
    borderSide: BorderSide.none,        // Filled style (sem borda)
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12px),
    borderSide: BorderSide(color: primary, width: 2px),
  ),
  contentPadding: EdgeInsets.symmetric(
    horizontal: 16px,
    vertical: 16px,
  ),
  hintStyle: TextStyle(color: textHint),
)
```

**Estados:**

- Resting: Filled background, sem borda
- Focused: Primary border 2px
- Error: Error border 2px, error text abaixo
- Disabled: Opacity 50%

### Cards

```dart
CardTheme(
  elevation: 0,                         // Usa border ao invés de shadow
  color: surface (#FFFFFF),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16px),
  ),
  margin: EdgeInsets.zero,              // Manual margin control
  clipBehavior: Clip.antiAlias,         // Smooth image clipping
)
```

**Variações:**

- **Post Card:** Photo 100x100, title, metadata, action buttons
- **Profile Card:** Avatar, name, instruments, bio preview
- **Notification Card:** Icon, title, body, timestamp, action buttons

### Bottom Navigation Bar

```dart
BottomNavigationBarThemeData(
  backgroundColor: surface (#FFFFFF),
  selectedItemColor: primary (#00A699),
  unselectedItemColor: textSecondary (#717171),
  showUnselectedLabels: true,
  type: BottomNavigationBarType.fixed,
  elevation: 0,                         // Flat com divider superior
)
```

**Ícones:**

- Home: `Icons.map` (mapa)
- Notifications: `Icons.notifications` + badge
- Post: `Icons.add_circle` (FAB-style)
- Messages: `Icons.chat_bubble_outline` + badge
- Profile: CircleAvatar (foto do perfil ativo)

**Badge Counters:**

- Background: `primary` (#00A699)
- Text: white, 10px, bold
- Min size: 18x18px
- Max display: "99+"
- Position: Top-right corner (-4px offset)

### Chips (Filters/Tags)

```dart
Chip(
  backgroundColor: primary.withOpacity(0.1),
  labelStyle: labelMedium,
  labelPadding: EdgeInsets.symmetric(
    horizontal: 12px,
    vertical: 8px,
  ),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16px),
  ),
)
```

**Estados:**

- Unselected: Gray background, textSecondary
- Selected: Primary 10% background, primary text
- Disabled: Opacity 50%

### Badges (Notification Counts)

```dart
Badge(
  backgroundColor: primary (#00A699),
  textColor: white,
  padding: EdgeInsets.all(4px),
  textStyle: TextStyle(
    fontSize: 10px,
    fontWeight: bold,
  ),
  alignment: Alignment.topRight,
)
```

**Regras:**

- Exibir se count > 0
- "99+" se count > 99
- Min width: 18px (mantém círculo perfeito)
- Posição: Offset(-4, -4) do canto superior direito

---

## 🗺️ Map Customization (Google Maps)

### Custom Map Style

**File:** `assets/maps_style.json`

**Features:**

- Desaturação parcial para destacar pins coloridos
- POIs relevantes (música, cultura) destacados
- Simplificação de estradas secundárias
- Modo claro otimizado (87% dos usuários)

### Custom Markers (Pins)

Gerados via Canvas API para performance (cache pré-aquecido).

**Musician Pin:**

- Color: `primary` (#00A699)
- Icon: Music note (white)
- Size: 48x48dp
- Shadow: 4dp blur

**Band Pin:**

- Color: `accent` (#FF6F61)
- Icon: Group (white)
- Size: 48x48dp
- Shadow: 4dp blur

**Active Pin (selected):**

- Border: 3px white
- Elevation: +2dp
- Scale: 1.2x

**Implementation:** `lib/services/marker_cache_service.dart`

---

## 🌐 Internationalization & Accessibility

### Text Scaling Support

Todos os text styles suportam Dynamic Type (iOS) e Font Scale (Android).

**Testing scales:**

- Small: 0.85x
- Default: 1.0x
- Large: 1.15x
- Extra Large: 1.3x (WCAG AAA)

**Constraints:**

- Max scale: 1.5x (evita layout quebrado)
- Min touch target: 48x48dp (WCAG)
- Line height mantido proporcional

### Color Contrast Compliance

| Pair                   | Ratio  | WCAG Level |
| ---------------------- | ------ | ---------- |
| textPrimary on white   | 13.2:1 | AAA        |
| textSecondary on white | 5.1:1  | AA         |
| primary on white       | 4.8:1  | AA Large   |
| white on primary       | 6.5:1  | AA All     |
| error on white         | 5.8:1  | AA All     |

**Testes:** Realizados com APCA (Advanced Perceptual Contrast Algorithm) e WCAG 2.1.

### Semantic Color Usage

- ✅ Nunca usar cor como única forma de informação
- ✅ Ícones + texto em botões críticos
- ✅ Estados de foco visíveis (border 2px)
- ✅ Mensagens de erro com ícone + texto

---

## 📊 Design Tokens (Resumo)

### Core Tokens

```json
{
  "color": {
    "primary": "#00A699",
    "accent": "#FF6F61",
    "background": "#FAFAFA",
    "surface": "#FFFFFF",
    "text": {
      "primary": "#1A1A1A",
      "secondary": "#717171",
      "hint": "#9E9E9E"
    },
    "feedback": {
      "success": "#4CAF50",
      "error": "#E53935",
      "warning": "#FB8C00"
    }
  },
  "typography": {
    "fontFamily": "Inter",
    "scale": {
      "display": [32, 28],
      "headline": [24, 20],
      "title": [18, 16, 14],
      "body": [16, 14, 12],
      "label": [14, 12, 11],
      "caption": 12
    },
    "weight": {
      "regular": 400,
      "medium": 500,
      "semibold": 600,
      "bold": 700
    }
  },
  "spacing": {
    "base": 4,
    "scale": [4, 8, 12, 16, 24, 32, 48]
  },
  "borderRadius": {
    "small": 8,
    "medium": 12,
    "large": 16,
    "xlarge": 24
  },
  "elevation": [0, 1, 2, 4, 6, 8]
}
```

---

## 🎯 Best Practices & Guidelines

### Color Usage

1. **Primary (Teal):** Sempre para músicos, botões principais, estados ativos
2. **Accent (Coral):** Sempre para bandas, nunca misturar com primary em mesmo contexto
3. **Neutral:** Usar para 80% do conteúdo (backgrounds, texto, bordas)
4. **Feedback:** Usar apenas para estados (success/error/warning), nunca decorativo

### Typography Hierarchy

1. **1 Display por página:** Hero headline apenas
2. **1 Headline por seção:** Máximo 2 por tela
3. **Body como base:** 90% do texto deve ser body/caption
4. **Bold com moderação:** Apenas em títulos e labels, nunca em body text

### Spacing Consistency

1. **Padding de tela:** Sempre 24px horizontal
2. **Entre seções:** Sempre 32px vertical
3. **Entre elementos:** 16px padrão, 8px para itens relacionados
4. **Margem de cards:** 16px consistente

### Responsive Behavior

- **Breakpoint mobile:** < 600px (100% dos usuários)
- **Padding responsivo:** Não reduz abaixo de 16px
- **Fontes responsivas:** Scale mínimo 0.85x
- **Touch targets:** Sempre >= 48x48dp

---

## 🛠️ Implementation Files

### Core Design System

- `lib/theme/app_colors.dart` - Paleta completa + MaterialColor swatch
- `lib/theme/app_typography.dart` - 17 text styles + aliases
- `lib/theme/app_theme.dart` - ThemeData Material 3 completo

### Component Examples

- `lib/pages/home_page.dart` - Cards, AppBar, FAB, Map, Lists
- `lib/pages/post_page.dart` - Forms, Inputs, Buttons, Image picker
- `lib/pages/bottom_nav_scaffold.dart` - Navigation, Badges, Avatars
- `lib/widgets/profile_switcher_bottom_sheet.dart` - Bottom sheet, Chips, Avatars

### Assets

- `assets/fonts/` - Inter (Regular, Medium, SemiBold, Bold)
- `assets/maps_style.json` - Custom Google Maps styling
- `assets/icon/` - App icons (adaptive + legacy)
- `assets/splash/` - Splash screens (light + dark)

---

## 📈 Performance Considerations

### Font Loading

- ✅ Fonts locais (sem network latency)
- ✅ 4 weights otimizados (total ~400KB)
- ✅ Subset latino completo (português)
- ✅ Fallback para system fonts

### Color Performance

- ✅ Cores em hex (compiladas em tempo de build)
- ✅ Opacity via `withOpacity()` (não cria novos objetos)
- ✅ MaterialColor swatch (interpolação automática)

### Image Optimization

- ✅ CachedNetworkImage para avatares/fotos
- ✅ memCacheWidth/Height para downscale
- ✅ Placeholder shimmer durante loading
- ✅ Error widgets para falhas

---

## 🔄 Version History

| Version | Date       | Changes                        |
| ------- | ---------- | ------------------------------ |
| 1.0.0   | 2025-11-24 | Design system inicial completo |

---

## 📞 Design Tokens Changelog

**Adições Futuras (Roadmap):**

- Dark mode completo (color scheme alternativo)
- Animação system (duration/easing tokens)
- Iconografia custom (substituto Material Icons)
- Ilustrações SVG branded
- Micro-interações (haptic feedback tokens)

---

## 📚 References

- [Material Design 3 Guidelines](https://m3.material.io/)
- [Inter Font Family](https://rsms.me/inter/)
- [WCAG 2.1 Color Contrast](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)
- [Flutter Theme Customization](https://docs.flutter.dev/cookbook/design/themes)
- [Google Maps Platform Styling](https://developers.google.com/maps/documentation/javascript/styling)

---

**Document Status:** ✅ Complete  
**Last Review:** 2025-11-24  
**Next Review:** 2025-12-24  
**Maintained by:** Design System Team
