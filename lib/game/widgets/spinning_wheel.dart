import 'dart:math';
import 'package:flutter/material.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// A spinning wheel widget that displays letters and spins to select one
class SpinningWheel extends StatefulWidget {
  const SpinningWheel({
    super.key,
    required this.letters,
    required this.onLetterSelected,
    this.size = 300,
  });

  /// Letters to display on the wheel (remaining letters)
  final List<String> letters;

  /// Callback when a letter is selected after spinning
  final ValueChanged<String> onLetterSelected;

  /// Size of the wheel
  final double size;

  @override
  State<SpinningWheel> createState() => _SpinningWheelState();
}

class _SpinningWheelState extends State<SpinningWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final _random = Random();

  double _currentRotation = 0;
  bool _isSpinning = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
          _currentRotation = _animation.value;
        });
        // Call callback with selected letter
        widget.onLetterSelected(widget.letters[_selectedIndex]);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning || widget.letters.isEmpty) return;

    setState(() {
      _isSpinning = true;
    });

    // Pick a random letter
    _selectedIndex = _random.nextInt(widget.letters.length);

    // Calculate target rotation
    // We want to land on the selected letter at the top (12 o'clock position)
    final segmentAngle = 2 * pi / widget.letters.length;
    final targetSegmentAngle = _selectedIndex * segmentAngle;

    // Add multiple full rotations for effect (5-8 rotations)
    final fullRotations = (5 + _random.nextInt(4)) * 2 * pi;

    // Target rotation - we want the selected segment at top
    // Top is at -pi/2 (or 3pi/2)
    final targetRotation = _currentRotation + fullRotations + targetSegmentAngle;

    _animation = Tween<double>(
      begin: _currentRotation,
      end: targetRotation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _spin,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Wheel background glow
            Container(
              width: widget.size * 0.95,
              height: widget.size * 0.95,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGold.withAlpha(100),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),

            // Rotating wheel
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final rotation = _isSpinning ? _animation.value : _currentRotation;
                return Transform.rotate(
                  angle: rotation,
                  child: child,
                );
              },
              child: CustomPaint(
                size: Size(widget.size * 0.9, widget.size * 0.9),
                painter: _WheelPainter(letters: widget.letters),
              ),
            ),

            // Center hub
            _buildCenterHub(),

            // Selection indicator (pointer at top)
            Positioned(
              top: 0,
              child: _buildPointer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterHub() {
    return Container(
      width: widget.size * 0.2,
      height: widget.size * 0.2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentGold,
            AppColors.accentOrange,
            AppColors.accentGold.withAlpha(200),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(100),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withAlpha(150),
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          _isSpinning ? '...' : 'SPIN',
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.size * 0.04,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: AppColors.black.withAlpha(100),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointer() {
    return CustomPaint(
      size: Size(widget.size * 0.1, widget.size * 0.12),
      painter: _PointerPainter(),
    );
  }
}

/// Custom painter for the wheel segments
class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.letters});

  final List<String> letters;

  // Segment colors - alternating vibrant colors
  static const List<Color> _segmentColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFF43F5E), // Rose
    Color(0xFFF97316), // Orange
    Color(0xFFEAB308), // Yellow
    Color(0xFF22C55E), // Green
    Color(0xFF14B8A6), // Teal
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (letters.isEmpty) return;

    final segmentAngle = 2 * pi / letters.length;

    // Draw segments
    for (var i = 0; i < letters.length; i++) {
      final startAngle = i * segmentAngle - pi / 2 - segmentAngle / 2;
      final color = _segmentColors[i % _segmentColors.length];

      // Segment paint
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            color,
            HSLColor.fromColor(color)
                .withLightness((HSLColor.fromColor(color).lightness - 0.15).clamp(0.0, 1.0))
                .toColor(),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      // Draw segment
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Draw segment border
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withAlpha(80)
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );

      // Draw letter
      _drawLetter(
        canvas,
        letters[i],
        center,
        radius * 0.7,
        startAngle + segmentAngle / 2,
        size.width * 0.08,
      );
    }

    // Draw outer ring
    final outerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.accentGold
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, outerRingPaint);

    // Draw inner ring
    final innerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withAlpha(100)
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius * 0.35, innerRingPaint);
  }

  void _drawLetter(
    Canvas canvas,
    String letter,
    Offset center,
    double distance,
    double angle,
    double fontSize,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: AppColors.black.withAlpha(150),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final x = center.dx + distance * cos(angle) - textPainter.width / 2;
    final y = center.dy + distance * sin(angle) - textPainter.height / 2;

    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return letters != oldDelegate.letters;
  }
}

/// Custom painter for the selection pointer
class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accentGold,
          AppColors.accentOrange,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);

    // Border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 2;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
