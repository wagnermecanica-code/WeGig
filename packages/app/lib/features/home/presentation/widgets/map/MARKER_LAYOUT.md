# 🎨 Layout dos Marcadores do Mapa

## 📐 Dimensões e Estrutura

### Marcador COM FOTO (Normal - 80x80px)

```
        80px
    ┌─────────┐
    │    ○    │ ← Badge (só quando ativo)
    │ ╔═════╗ │
  8 │ ║     ║ │ 8  ← Círculo branco (80px)
  0 │ ║ 👤  ║ │ 0
  p │ ║FOTO ║ │ p
  x │ ║     ║ │ x
    │ ╚═════╝ │    ← Foto circular (60px)
    │         │    ← Borda colorida (3px normal / 5px ativo)
    └─────────┘
       ╰───╯       ← Sombra (blur 4px)
```

**Camadas (de baixo para cima):**

1. **Sombra** (offset Y+2px, blur 4px, black 30%)
2. **Círculo branco** (80px diâmetro, fundo)
3. **Foto circular** (60px diâmetro, crop circular)
4. **Borda colorida** (3px normal, 5px ativo, Escuro/Laranja)
5. **Badge** (20px, canto superior direito, só se ativo)

---

### Marcador COM FOTO (Ativo - 80x80px)

```
  ~~~~~~~~~~~~~~~~~~~  ← Glow effect (blur 12px, alpha 30%)
 ~      80px        ~
~   ┌─────────┐     ~
~   │  ◉ 🎸   │     ~ ← Badge com ícone (♪ músico, 👥 banda)
~   │ ╔═════╗ │     ~
~   │ ║     ║ │     ~
~ 8 │ ║ 👤  ║ │ 8   ~ ← Círculo branco (80px)
~ 0 │ ║FOTO ║ │ 0   ~
~ p │ ║     ║ │ p   ~
~ x │ ║     ║ │ x   ~
~   │ ╚═════╝ │     ~ ← Foto circular (60px)
~   │         │     ~ ← Borda GROSSA (5px)
~   └─────────┘     ~
 ~     ╰───╯       ~
  ~~~~~~~~~~~~~~~~~~~  ← Glow pulsante
```

**Diferenças do Normal:**

- ✅ Glow effect (raio +8px, blur 12px)
- ✅ Borda mais grossa (5px vs 3px)
- ✅ Badge no canto superior direito
- ✅ zIndex 1000 (fica por cima)

---

### Marcador SEM FOTO (Fallback - 60x60px)

```
        60px
    ┌─────────┐
    │  ╭───╮  │
    │  │   │  │ ← Círculo colorido (60px)
  6 │  │ ♪ │  │ 6  ← Ícone branco (24px)
  0 │  │   │  │ 0
  p │  │   │  │ p
  x │  ╰───╯  │ x  ← Borda branca (3px normal / 4px ativo)
    │         │
    └─────────┘
       ╰───╯      ← Sombra
```

**Camadas:**

1. **Sombra** (mesma do anterior)
2. **Círculo colorido** (60px, Escuro/Laranja)
3. **Borda branca** (3px normal, 4px ativo)
4. **Ícone** (24px normal, 28px ativo, ♪ ou 👥)

---

## 🎨 Cores e Estilos

### Cores de Borda

```dart
// Músico (type == 'musician')
AppColors.primary    // #37475A (Escuro/Azul-acinzentado)

// Banda (type == 'band')
AppColors.accent     // #E47911 (Laranja vibrante)
```

### Ícones

```dart
// Músico
Icons.music_note     // ♪

// Banda
Icons.group          // 👥
```

### Badge (só quando ativo)

```dart
Position: (size - 12, 12)  // Canto superior direito
Size: 20px diâmetro (raio 10px)
Background: cor do tipo (Escuro/Laranja)
Border: 2px branco
Icon: 12px, branco, bold
```

---

## 📊 Especificações Técnicas

### Marcador COM FOTO

| Elemento           | Tamanho                     | Cor             | Efeito          |
| ------------------ | --------------------------- | --------------- | --------------- |
| **Canvas total**   | 80x80px                     | -               | -               |
| **Círculo branco** | 80px ⌀                      | `Colors.white`  | Fundo           |
| **Foto**           | 60px ⌀                      | -               | Crop circular   |
| **Borda**          | 3px (normal)<br>5px (ativo) | Escuro/Laranja  | Stroke          |
| **Glow (ativo)**   | 96px ⌀<br>(+16px)           | Cor + 30% alpha | Blur 12px       |
| **Badge (ativo)**  | 20px ⌀                      | Cor tipo        | Canto superior  |
| **Ícone badge**    | 12px                        | Branco          | Bold            |
| **Sombra**         | 80px ⌀                      | Black 30%       | Blur 4px, Y+2px |

### Marcador SEM FOTO

| Elemento          | Tamanho                       | Cor             | Efeito          |
| ----------------- | ----------------------------- | --------------- | --------------- |
| **Canvas total**  | 60x60px                       | -               | -               |
| **Círculo fundo** | 60px ⌀                        | Escuro/Laranja  | Preenchido      |
| **Borda branca**  | 3px (normal)<br>4px (ativo)   | `Colors.white`  | Stroke          |
| **Ícone central** | 24px (normal)<br>28px (ativo) | Branco          | Normal/Bold     |
| **Glow (ativo)**  | 72px ⌀<br>(+12px)             | Cor + 30% alpha | Blur 10px       |
| **Sombra**        | 60px ⌀                        | Black 30%       | Blur 4px, Y+2px |

---

## 🔄 Estados dos Marcadores

### Estado: NORMAL (isActive = false)

**Com foto:**

```
    ╔═════╗
    ║ 👤  ║  ← Foto 60px
    ║FOTO ║
    ╚═════╝
    └──┬──┘
       │
     Borda 3px Escuro/Laranja
```

**Sem foto:**

```
    ╭───╮
    │ ♪ │  ← Ícone 24px
    ╰───╯
    └─┬─┘
      │
    Borda 3px branca
```

### Estado: ATIVO (isActive = true)

**Com foto:**

```
  ~~~◉ 🎸~~~  ← Glow + Badge
    ╔═════╗
    ║ 👤  ║  ← Foto 60px
    ║FOTO ║
    ╚═════╝
    └──┬──┘
       │
     Borda 5px GROSSA
     zIndex 1000
```

**Sem foto:**

```
   ~~~♪~~~   ← Glow
    ╭───╮
    │ ♪ │  ← Ícone 28px MAIOR
    ╰───╯
    └─┬─┘
      │
    Borda 4px branca
    zIndex 1000
```

---

## 🎯 Exemplo Visual Comparativo

### Mapa com 3 marcadores:

```
            Músico ATIVO              Banda Normal            Músico sem foto
         (com foto + glow)          (com foto)              (fallback)

    ~~~~~~~~~~~~~~~~~~~~~~~~~~~
   ~     ◉ ♪                  ~
  ~   ╔═══════╗                ~       ╔═══════╗              ╭─────╮
 ~    ║       ║                 ~      ║       ║              │     │
~     ║  👤   ║                  ~     ║  👥   ║              │  ♪  │
~     ║ Foto  ║                  ~     ║ Foto  ║              │     │
 ~    ║       ║                 ~      ║       ║              ╰─────╯
  ~   ╚═══════╝                ~       ╚═══════╝            Escuro fill
   ~  └───┬───┘               ~        └───┬───┘            + ícone
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~             │
         │                                  │
    Borda 5px Escuro                  Borda 3px Laranja
    zIndex 1000                       zIndex 1
```

---

## 💡 Características Visuais

### 1. Hierarquia Visual

- **Ativo:** Maior (glow), mais contraste, badge, zIndex alto
- **Normal:** Tamanho padrão, borda fina, sem efeitos
- **Sem foto:** Menor, ícone simples, fallback elegante

### 2. Identidade de Tipo

- **Músico:** Escuro (#37475A) + ícone ♪
- **Banda:** Laranja (#E47911) + ícone 👥

### 3. Feedback Visual

- **Glow pulsante:** Indica marcador ativo
- **Badge:** Reforça tipo quando selecionado
- **Borda grossa:** Destaque no marcador ativo
- **Sombra:** Profundidade e realismo

### 4. Performance

- **Cache:** Reutiliza BitmapDescriptor
- **Foto:** Download assíncrono + cache
- **Fallback:** Instantâneo (ícone)

---

## 📝 Notas de Implementação

### Canvas Drawing Order (importante!)

```dart
1. Glow (se ativo) - primeiro
2. Sombra - base
3. Círculo branco (ou colorido) - fundo
4. Foto (com clip circular) - conteúdo
5. Borda - contorno
6. Badge (se ativo) - último (por cima)
```

### Crop Circular da Foto

```dart
// Usa clip path para garantir círculo perfeito
canvas.save();
final circlePath = Path()..addOval(Rect.fromCircle(...));
canvas.clipPath(circlePath);
canvas.drawImageRect(image, srcRect, dstRect, Paint());
canvas.restore();
```

### InfoWindow (ao tocar)

```dart
infoWindow: InfoWindow(
  title: post.authorName ?? 'Músico',  // Nome do autor
  snippet: post.city,                   // Cidade
)
```

---

**Criado em:** 30 de Novembro de 2025  
**Baseado em:** `photo_marker_builder.dart`  
**Canvas API:** Flutter `dart:ui`
