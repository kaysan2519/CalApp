import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SlideToLogButton extends StatefulWidget {
  final VoidCallback onConfirmed;
  final String label;

  const SlideToLogButton({
    super.key,
    required this.onConfirmed,
    this.label = 'Geser untuk Verifikasi & Catat ➔',
  });

  @override
  State<SlideToLogButton> createState() => _SlideToLogButtonState();
}

class _SlideToLogButtonState extends State<SlideToLogButton> {
  double _dragPosition = 0.0;
  bool _confirmed = false;

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_confirmed) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });

    if (_dragPosition >= maxDrag - 4 && !_confirmed) {
      _confirmed = true;
      HapticFeedback.heavyImpact();
      widget.onConfirmed();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _dragPosition = 0.0;
            _confirmed = false;
          });
        }
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_confirmed) {
      setState(() {
        _dragPosition = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const handleSize = 46.0;
        final maxDrag = constraints.maxWidth - handleSize - 8.0;
        final progress = (maxDrag > 0) ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        return Container(
          height: 54,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F121C),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Label that fades out as user drags
              Opacity(
                opacity: (1.0 - progress).clamp(0.0, 1.0),
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Draggable Handle
              Positioned(
                left: _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(details, maxDrag),
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                  child: Container(
                    width: handleSize,
                    height: handleSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF05060A),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
