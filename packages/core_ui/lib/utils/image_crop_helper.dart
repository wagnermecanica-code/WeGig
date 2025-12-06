import 'dart:io';

import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

/// Helper para padronizar configurações de crop de imagem em todo o app
class ImageCropHelper {
  /// Crop para fotos de perfil (1:1 quadrado)
  static Future<File?> cropProfileImage(String sourcePath) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
      compressFormat: ImageCompressFormat.jpg,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Ajustar imagem',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          statusBarColor: AppColors.primary,
          backgroundColor: Colors.black,
          activeControlsWidgetColor: AppColors.primary,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false,
          cropFrameColor: AppColors.primary,
          cropGridColor: Colors.white24,
          dimmedLayerColor: Colors.black.withValues(alpha: 0.8),
        ),
        IOSUiSettings(
          title: 'Ajustar imagem',
          aspectRatioLockEnabled: true,
          minimumAspectRatio: 1.0,
          rotateButtonsHidden: false,
          aspectRatioPickerButtonHidden: true,
          resetButtonHidden: false,
          aspectRatioLockDimensionSwapEnabled: false,
        ),
      ],
    );

    return cropped != null ? File(cropped.path) : null;
  }

  /// Crop para fotos de posts (4:3)
  static Future<File?> cropPostImage(String sourcePath) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressQuality: 85,
      maxWidth: 1600,
      maxHeight: 1200,
      compressFormat: ImageCompressFormat.jpg,
      aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 3),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Ajustar foto',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          statusBarColor: AppColors.primary,
          backgroundColor: Colors.black,
          activeControlsWidgetColor: AppColors.primary,
          initAspectRatio: CropAspectRatioPreset.ratio4x3,
          lockAspectRatio: true,
          hideBottomControls: false,
          cropFrameColor: AppColors.primary,
          cropGridColor: Colors.white24,
          dimmedLayerColor: Colors.black.withValues(alpha: 0.8),
        ),
        IOSUiSettings(
          title: 'Ajustar foto',
          aspectRatioLockEnabled: true,
          minimumAspectRatio: 4 / 3,
          rotateButtonsHidden: false,
          aspectRatioPickerButtonHidden: true,
          resetButtonHidden: false,
          aspectRatioLockDimensionSwapEnabled: false,
        ),
      ],
    );

    return cropped != null ? File(cropped.path) : null;
  }
}
