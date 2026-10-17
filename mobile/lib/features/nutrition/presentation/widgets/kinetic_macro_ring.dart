import 'dart:math' as math;
import 'package:flutter/material.dart';

class KineticMacroRing extends StatefulWidget {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double size;
  final bool autoRotate;

  const KineticMacroRing({
    super.key,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.size = 110.0,
    this.autoRotate = false,
  });

  @override
  State<KineticMacroRing> createState() => _KineticMacroRingState();
}

class _KineticMacroRingState extends State<KineticMacroRing>
    with SingleTickerProviderStateMixin {
  AnimationController? _animController;
  double _manualAngle = 0.5;
  double _lastPanX = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.autoRotate) {
      _animController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 14),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        _lastPanX = details.localPosition.dx;
      },
      onPanUpdate: (details) {
        setState(() {
          final dx = details.localPosition.dx - _lastPanX;
          _manualAngle += dx * 0.04;
          _lastPanX = details.localPosition.dx;
        });
      },
      child: _animController != null
          ? AnimatedBuilder(
              animation: _animController!,
              builder: (context, _) {
                final currentAngle = _manualAngle + (_animController!.value * 2 * math.pi);
                return _buildRing(currentAngle);
              },
            )
          : _buildRing(_manualAngle),
    );
  }

  Widget _buildRing(double currentAngle) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _MacroRingPainter(
              angle: currentAngle,
              proteinG: widget.proteinG,
              carbsG: widget.carbsG,
              fatG: widget.fatG,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.calories.round()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'KKAL',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroRingPainter extends CustomPainter {
  final double angle;
  final double proteinG;
  final double carbsG;
  final double fatG;

  _MacroRingPainter({
    required this.angle,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width * 0.42;

    // Background track ring
    final bgPaint = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: radius * 2, height: radius * 1.3),
      bgPaint,
    );

    final totalMacros = math.max(1.0, proteinG + carbsG + fatG);
    final segments = [
      _SegmentData(color: const Color(0xFF818CF8), ratio: proteinG / totalMacros), // Protein Indigo
      _SegmentData(color: const Color(0xFFF59E0B), ratio: carbsG / totalMacros),   // Carbs Amber
      _SegmentData(color: const Color(0xFFFB7185), ratio: fatG / totalMacros),     // Fat Rose
    ];

    double startAngle = angle;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7.0;

    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: radius * 2,
      height: radius * 1.3,
    );

    for (final seg in segments) {
      final sweep = seg.ratio * 2 * math.pi;
      arcPaint.color = seg.color;
      canvas.drawArc(rect, startAngle, sweep, false, arcPaint);
      startAngle += sweep;
    }

    // Center subtle orb
    final orbPaint = Paint()
      ..color = const Color(0xFF0F121C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 16, orbPaint);

    final orbBorder = Paint()
      ..color = const Color(0x4D10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), 16, orbBorder);
  }

  @override
  bool shouldRepaint(covariant _MacroRingPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.proteinG != proteinG ||
        oldDelegate.carbsG != carbsG ||
        oldDelegate.fatG != fatG;
  }
}

class _SegmentData {
  final Color color;
  final double ratio;
  _SegmentData({required this.color, required this.ratio});
}
