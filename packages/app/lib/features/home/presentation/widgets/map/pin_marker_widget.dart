import 'package:flutter/material.dart';

/// Widget customizado em formato de PIN (gota invertida) de alta qualidade
/// 
/// Características:
/// - Formato tradicional de "gota invertida" do Google Maps
/// - Círculo branco central no topo (marca registrada dos pins do Google)
/// - Cores dinâmicas baseadas no tipo (Músico azul / Banda laranja)
/// - Renderizado vetorial (sem pixelização)
/// - Design minimalista WeGig 2025
/// 
/// Performance:
/// - Convertido para BitmapDescriptor via widget_to_marker
/// - Cache automático para evitar regeneração
/// - Tamanho otimizado (80x120px padrão)
class PinMarkerWidget extends StatelessWidget {
  /// Cor base do marcador (músico/banda)
  final Color bodyColor;

  /// Ícone central exibido dentro do círculo branco
  final IconData iconData;

  /// Cor do ícone central (padrão usa [bodyColor])
  final Color? iconColor;

  /// Se o marcador está ativo (selecionado)
  final bool isActive;

  /// Tamanho do pin (largura da gota)
  final double size;

  /// Cor do círculo interno (default branco)
  final Color innerCircleColor;

  const PinMarkerWidget({
    super.key,
    required this.bodyColor,
    required this.iconData,
    this.iconColor,
    this.isActive = false,
    this.size = 80.0,
    this.innerCircleColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    // Marcador ativo é ligeiramente maior e mais brilhante
    final double pinSize = isActive ? size * 1.15 : size;
    final Color finalColor = isActive
        ? bodyColor
        : bodyColor.withValues(alpha: 0.95);
    final Color resolvedIconColor = iconColor ?? finalColor;

    return SizedBox(
      width: pinSize,
      height: pinSize * 1.5, // Altura 1.5x a largura (formato alongado)
      child: CustomPaint(
        painter: _PinPainter(
          color: finalColor,
          isActive: isActive,
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: pinSize * 0.5), // Centraliza no círculo superior
            child: Container(
              width: pinSize * 0.35,
              height: pinSize * 0.35,
              decoration: BoxDecoration(
                color: innerCircleColor, // Círculo branco central
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  iconData,
                  color: resolvedIconColor,
                  size: pinSize * 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Painter para desenhar o formato de gota invertida (pin)
class _PinPainter extends CustomPainter {
  final Color color;
  final bool isActive;

  _PinPainter({
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.9),
          color,
          color.withValues(alpha: 0.95),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bounds);

    if (isActive) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

      canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.3),
        size.width * 0.65,
        glowPaint,
      );
    }

    final Path pinPath = Path()
      ..moveTo(size.width / 2, size.height)
      ..cubicTo(
        size.width * 0.05,
        size.height * 0.72,
        size.width * 0.05,
        size.height * 0.35,
        size.width / 2,
        size.height * 0.2,
      )
      ..cubicTo(
        size.width * 0.95,
        size.height * 0.35,
        size.width * 0.95,
        size.height * 0.72,
        size.width / 2,
        size.height,
      )
      ..close();

    canvas.drawPath(pinPath, fillPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isActive ? 3.0 : 2.0;

    canvas.drawPath(pinPath, borderPaint);

    final double highlightRadius = size.width * 0.38;
    final Offset highlightCenter = Offset(size.width / 2, size.height * 0.32);

    final Paint highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: highlightCenter, radius: highlightRadius),
      );

    canvas.drawCircle(highlightCenter, highlightRadius, highlightPaint);
  }

  @override
  bool shouldRepaint(_PinPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isActive != isActive;
  }
}
