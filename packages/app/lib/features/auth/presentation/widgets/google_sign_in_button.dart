import 'package:core_ui/widgets/app_loading_overlay.dart';
import 'package:flutter/material.dart';

/// Botão oficial "Sign In with Google" seguindo as diretrizes do Google
///
/// Design baseado em: https://developers.google.com/identity/branding-guidelines
/// - Logo oficial do Google (SVG com cores oficiais)
/// - Fundo branco (#FFFFFF)
/// - Texto em Roboto Medium
/// - Sombra sutil para elevação
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    required this.onPressed,
    super.key,
    this.isLoading = false,
  });
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          shadowColor: Colors.black26,
          disabledBackgroundColor: Colors.grey.shade200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: AppRadioPulseLoader(
                  size: 20,
                  color: Colors.grey.shade700,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo oficial do Google (SVG inline)
                  _GoogleLogo(),
                  const SizedBox(width: 12),
                  const Flexible(
                    child: Text(
                      'Continuar com Google',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        letterSpacing: 0.25,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Logo oficial do Google em SVG (cores oficiais da marca)
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

/// Painter para desenhar o logo oficial do Google
/// Baseado no SVG oficial: https://developers.google.com/identity/branding-guidelines
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 48;
    final scaleY = size.height / 48;

    // Cor vermelha (#EA4335) - Parte superior esquerda
    final redPath = Path()
      ..moveTo(24 * scaleX, 9.5 * scaleY)
      ..cubicTo(27.54 * scaleX, 9.5 * scaleY, 30.71 * scaleX, 10.72 * scaleY,
          33.21 * scaleX, 13.1 * scaleY)
      ..lineTo(40.06 * scaleX, 6.25 * scaleY)
      ..cubicTo(35.9 * scaleX, 2.38 * scaleY, 30.47 * scaleX, 0, 24 * scaleX, 0)
      ..cubicTo(14.62 * scaleX, 0, 6.51 * scaleX, 5.38 * scaleY, 2.56 * scaleX,
          13.22 * scaleY)
      ..lineTo(10.54 * scaleX, 19.41 * scaleY)
      ..cubicTo(12.43 * scaleX, 13.72 * scaleY, 17.74 * scaleX, 9.5 * scaleY,
          24 * scaleX, 9.5 * scaleY)
      ..close();

    canvas.drawPath(
      redPath,
      Paint()..color = const Color(0xFFEA4335),
    );

    // Cor azul (#4285F4) - Parte superior direita
    final bluePath = Path()
      ..moveTo(46.98 * scaleX, 24.55 * scaleY)
      ..cubicTo(46.98 * scaleX, 22.98 * scaleY, 46.83 * scaleX, 21.46 * scaleY,
          46.6 * scaleX, 20 * scaleY)
      ..lineTo(24 * scaleX, 20 * scaleY)
      ..lineTo(24 * scaleX, 29.02 * scaleY)
      ..lineTo(36.94 * scaleX, 29.02 * scaleY)
      ..cubicTo(36.36 * scaleX, 31.98 * scaleY, 34.68 * scaleX, 34.5 * scaleY,
          32.16 * scaleX, 36.2 * scaleY)
      ..lineTo(39.89 * scaleX, 42.2 * scaleY)
      ..cubicTo(44.4 * scaleX, 38.02 * scaleY, 46.98 * scaleX, 31.84 * scaleY,
          46.98 * scaleX, 24.55 * scaleY)
      ..close();

    canvas.drawPath(
      bluePath,
      Paint()..color = const Color(0xFF4285F4),
    );

    // Cor amarela (#FBBC05) - Parte inferior esquerda
    final yellowPath = Path()
      ..moveTo(10.53 * scaleX, 28.59 * scaleY)
      ..cubicTo(10.05 * scaleX, 27.14 * scaleY, 9.77 * scaleX, 25.6 * scaleY,
          9.77 * scaleX, 24 * scaleY)
      ..cubicTo(9.77 * scaleX, 22.4 * scaleY, 10.04 * scaleX, 20.86 * scaleY,
          10.53 * scaleX, 19.41 * scaleY)
      ..lineTo(2.55 * scaleX, 13.22 * scaleY)
      ..cubicTo(
          0.92 * scaleX, 16.46 * scaleY, 0, 20.12 * scaleY, 0, 24 * scaleY)
      ..cubicTo(0, 27.88 * scaleY, 0.92 * scaleX, 31.54 * scaleY, 2.56 * scaleX,
          34.78 * scaleY)
      ..lineTo(10.53 * scaleX, 28.59 * scaleY)
      ..close();

    canvas.drawPath(
      yellowPath,
      Paint()..color = const Color(0xFFFBBC05),
    );

    // Cor verde (#34A853) - Parte inferior direita
    final greenPath = Path()
      ..moveTo(24 * scaleX, 48 * scaleY)
      ..cubicTo(30.48 * scaleX, 48 * scaleY, 35.93 * scaleX, 45.87 * scaleY,
          39.89 * scaleX, 42.19 * scaleY)
      ..lineTo(32.16 * scaleX, 36.19 * scaleY)
      ..cubicTo(30.01 * scaleX, 37.64 * scaleY, 27.24 * scaleX, 38.49 * scaleY,
          24 * scaleX, 38.49 * scaleY)
      ..cubicTo(17.74 * scaleX, 38.49 * scaleY, 12.43 * scaleX, 34.27 * scaleY,
          10.53 * scaleX, 28.58 * scaleY)
      ..lineTo(2.55 * scaleX, 34.77 * scaleY)
      ..cubicTo(6.51 * scaleX, 42.62 * scaleY, 14.62 * scaleX, 48 * scaleY,
          24 * scaleX, 48 * scaleY)
      ..close();

    canvas.drawPath(
      greenPath,
      Paint()..color = const Color(0xFF34A853),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
