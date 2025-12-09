# Flutter SDK 3.27.1 Patches

**Data:** 9 de dezembro de 2025  
**Versão Flutter:** 3.27.1 (via FVM)

---

## ⚠️ IMPORTANTE

Estes patches são **necessários** para compilar o app iOS com Flutter 3.27.1.  
Se você reinstalar o Flutter ou mudar de versão, **re-aplique os patches**.

---

## Patch 1: CupertinoDynamicColor.toARGB32()

### Arquivo
```
.fvm/flutter_sdk/packages/flutter/lib/src/cupertino/colors.dart
```

### Problema
```
Error: The non-abstract class 'CupertinoDynamicColor' is missing implementations for these members:
 - Color.toARGB32
```

### Solução
Adicione este método no final da classe `CupertinoDynamicColor` (antes do `}`):

```dart
  @override
  int toARGB32() => _effectiveColor.value;
```

### Localização Exata
Após o método `withValues()`, aproximadamente linha 1213.

---

## Patch 2: SemanticsData.elevation

### Arquivo
```
.fvm/flutter_sdk/packages/flutter/lib/src/semantics/semantics.dart
```

### Problema
```
Error: No named parameter with the name 'elevation'.
    elevation: data.elevation,
```

### Solução
Substitua:
```dart
elevation: data.elevation,
```

Por:
```dart
elevation: data.elevation ?? 0.0,
```

### Localização Exata
Linha 2920 aproximadamente, dentro do método que cria `SemanticsUpdateBuilder`.

---

## Script de Aplicação Automática

Salve como `.tools/scripts/apply_flutter_patches.sh`:

```bash
#!/bin/bash

FVM_FLUTTER_PATH="$HOME/to_sem_banda/.fvm/flutter_sdk"

# Patch 1: CupertinoDynamicColor
COLORS_FILE="$FVM_FLUTTER_PATH/packages/flutter/lib/src/cupertino/colors.dart"
if grep -q "int toARGB32()" "$COLORS_FILE"; then
  echo "✅ Patch 1 já aplicado (colors.dart)"
else
  # Adiciona o método antes do último }
  sed -i '' 's/colorSpace: colorSpace);$/colorSpace: colorSpace);\n\n  @override\n  int toARGB32() => _effectiveColor.value;/' "$COLORS_FILE"
  echo "✅ Patch 1 aplicado (colors.dart)"
fi

# Patch 2: SemanticsData.elevation
SEMANTICS_FILE="$FVM_FLUTTER_PATH/packages/flutter/lib/src/semantics/semantics.dart"
if grep -q "elevation: data.elevation ?? 0.0" "$SEMANTICS_FILE"; then
  echo "✅ Patch 2 já aplicado (semantics.dart)"
else
  sed -i '' 's/elevation: data.elevation,/elevation: data.elevation ?? 0.0,/' "$SEMANTICS_FILE"
  echo "✅ Patch 2 aplicado (semantics.dart)"
fi

echo ""
echo "🎉 Patches aplicados com sucesso!"
echo "Execute: cd packages/app && fvm flutter clean && fvm flutter pub get"
```

---

## Verificação

Para verificar se os patches estão aplicados:

```bash
# Patch 1
grep -n "toARGB32" .fvm/flutter_sdk/packages/flutter/lib/src/cupertino/colors.dart

# Patch 2  
grep -n "elevation: data.elevation" .fvm/flutter_sdk/packages/flutter/lib/src/semantics/semantics.dart
```

---

## Causa Raiz

O Flutter 3.27.1 foi lançado em dezembro de 2024, mas a API do Dart engine evoluiu.
Há incompatibilidades entre:
- `dart:ui` Color API (adicionou `toARGB32()` como abstract)
- Semantics API (removeu parâmetro `elevation` em algumas construções)

A solução correta seria atualizar para Flutter 3.38.4, mas o projeto tem constraints que impedem isso.

---

## Referências

- Flutter Issue: Incompatibilidade Color.toARGB32
- Dart SDK Changelog 3.6.0
- SESSION_15_NOTIFICATIONS_SECURITY_AUDIT.md
