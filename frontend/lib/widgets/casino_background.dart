import 'dart:math' as math;
import 'package:flutter/material.dart';

class CasinoBackground extends StatelessWidget {
  final Widget child;

  const CasinoBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Rich Gradient (Vignette from royal violet to deep obsidian purple)
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.1),
              radius: 1.25,
              colors: [
                Color(0xFF551980), // Radiant inner purple
                Color(0xFF370B58), // Mid velvet purple
                Color(0xFF1B032D), // Deep table edge
                Color(0xFF0D0117), // Outer border shadow
              ],
              stops: [0.0, 0.45, 0.85, 1.0],
            ),
          ),
        ),

        // Repeating Diamond Grid with Suit Watermarks (Clubs, Hearts, Spades, Diamonds)
        Positioned.fill(
          child: CustomPaint(
            painter: _SuitPatternPainter(),
          ),
        ),

        // Corner 3D Golden Suit Accents
        Positioned(
          top: -20,
          left: -20,
          child: _goldSuitAccent('♠', 74, -0.35),
        ),
        Positioned(
          top: -15,
          right: -10,
          child: _goldSuitAccent('♥', 68, 0.4),
        ),
        Positioned(
          bottom: -25,
          left: -15,
          child: _goldSuitAccent('♣', 80, 0.25),
        ),
        Positioned(
          bottom: -20,
          right: -20,
          child: _goldSuitAccent('♦', 70, -0.3),
        ),

        // Foreground content
        child,
      ],
    );
  }

  Widget _goldSuitAccent(String symbol, double size, double rotation) {
    return Transform.rotate(
      angle: rotation,
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFFFFDF7A), Color(0xFFD4AF37), Color(0xFF7E5B12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          symbol,
          style: TextStyle(
            fontSize: size,
            color: Colors.white.withOpacity(0.18),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SuitPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double gridSize = 72.0;
    final suitSymbols = ['♠', '♥', '♣', '♦'];

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    int row = 0;
    for (double y = -gridSize; y < size.height + gridSize; y += gridSize / 2) {
      int col = 0;
      for (double x = -gridSize; x < size.width + gridSize; x += gridSize) {
        final offsetX = (row % 2 == 1) ? x + (gridSize / 2) : x;
        final center = Offset(offsetX, y);

        // Draw faint diamond lattice lines
        final path = Path()
          ..moveTo(center.dx, center.dy - gridSize / 2)
          ..lineTo(center.dx + gridSize / 2, center.dy)
          ..lineTo(center.dx, center.dy + gridSize / 2)
          ..lineTo(center.dx - gridSize / 2, center.dy)
          ..close();
        canvas.drawPath(path, linePaint);

        // Suit Watermark inside each diamond
        final suitIndex = (row * 3 + col) % suitSymbols.length;
        final textSpan = TextSpan(
          text: suitSymbols[suitIndex],
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.045),
            fontWeight: FontWeight.bold,
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
        col++;
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}