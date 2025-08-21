// lib/widgets/circular_calorie_progress.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class CircularCalorieProgress extends StatefulWidget {
  final double currentCalories;
  final double targetCalories;
  final double size;

  const CircularCalorieProgress({
    Key? key,
    required this.currentCalories,
    required this.targetCalories,
    this.size = 200,
  }) : super(key: key);

  @override
  State<CircularCalorieProgress> createState() =>
      _CircularCalorieProgressState();
}

class _CircularCalorieProgressState extends State<CircularCalorieProgress>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(CircularCalorieProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentCalories != widget.currentCalories ||
        oldWidget.targetCalories != widget.targetCalories) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.targetCalories > 0
        ? widget.currentCalories / widget.targetCalories
        : 0.0;
    final remaining = widget.targetCalories - widget.currentCalories;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedProgress = progress * _animation.value;

        return Container(
          width: widget.size,
          height: widget.size,
          child: Stack(
            children: [
              // Background circle
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 12,
                  ),
                ),
              ),

              // Progress circle
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: CircularProgressPainter(
                  progress: animatedProgress,
                  strokeWidth: 12,
                  progressColor: _getProgressColor(progress),
                  backgroundColor: Colors.grey.shade200,
                ),
              ),

              // Center content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      remaining > 0
                          ? '${remaining.round()}'
                          : 'Exceeded ${(-remaining).round()}',
                      style: TextStyle(
                        fontSize: widget.size * 0.12,
                        fontWeight: FontWeight.bold,
                        color: remaining > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      remaining > 0 ? 'Remaining calories' : 'calories',
                      style: TextStyle(
                        fontSize: widget.size * 0.06,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.currentCalories.round()} / ${widget.targetCalories.round()}',
                      style: TextStyle(
                        fontSize: widget.size * 0.05,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}% complete',
                      style: TextStyle(
                        fontSize: widget.size * 0.04,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Progress dot
              if (animatedProgress > 0)
                Positioned.fill(
                  child: CustomPaint(
                    painter: ProgressDotPainter(
                      progress: animatedProgress,
                      size: widget.size,
                      strokeWidth: 12,
                      dotColor: _getProgressColor(progress),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getProgressColor(double progress) {
    if (progress <= 0.5) {
      // From red to yellow
      return Color.lerp(Colors.red, Colors.orange, progress * 2)!;
    } else if (progress <= 1.0) {
      // From yellow to green
      return Color.lerp(Colors.orange, Colors.green, (progress - 0.5) * 2)!;
    } else {
      // Exceeds target, turn red
      return Colors.red;
    }
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;

  CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw progress arc
    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * math.min(progress, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ProgressDotPainter extends CustomPainter {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color dotColor;

  ProgressDotPainter({
    required this.progress,
    required this.size,
    required this.strokeWidth,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Calculate progress dot position
    const startAngle = -math.pi / 2;
    final currentAngle = startAngle + (2 * math.pi * math.min(progress, 1.0));

    final dotX = center.dx + radius * math.cos(currentAngle);
    final dotY = center.dy + radius * math.sin(currentAngle);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = dotColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw progress dot
    canvas.drawCircle(Offset(dotX, dotY), 8, paint);
    canvas.drawCircle(Offset(dotX, dotY), 8, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
