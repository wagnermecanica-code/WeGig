import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Substitui o antigo PictureEditor.editImage(fotoInput, contraste, brilho)
Future<Uint8List?> editImage(
  Uint8List fotoInput,
  double contraste,
  double brilho,
) async {
  final image = img.decodeImage(fotoInput);
  if (image == null) return null;

  var edited = image;

  // Brilho (-255 a +255)
  if (brilho != 0) {
    edited = img.adjustColor(
      edited,
      brightness: brilho / 255.0,
    );
  }

  // Contraste (1.0 = original)
  if (contraste != 1.0) {
    edited = img.adjustColor(
      edited,
      contrast: contraste,
    );
  }

  return Uint8List.fromList(img.encodePng(edited));
}

/// Substitui o antigo PictureEditor.rotateImage(fotoInput, degrees)
Future<Uint8List?> rotateImage(
  Uint8List fotoInput,
  double degrees,
) async {
  final image = img.decodeImage(fotoInput);
  if (image == null) return null;

  final angle = degrees % 360;

  late img.Image rotated;
  if (angle == 90 || angle == -270) {
    rotated = img.copyRotate(image, angle: 90);
  } else if (angle == 180 || angle == -180) {
    rotated = img.copyRotate(image, angle: 180);
  } else if (angle == 270 || angle == -90) {
    rotated = img.copyRotate(image, angle: -90);
  } else {
    return fotoInput; // sem rotação
  }

  return Uint8List.fromList(img.encodePng(rotated));
}
