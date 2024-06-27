import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Timer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Custom Timer UI',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        body: const Center(child: TimerWidget()),
      ),
    );
  }
}

class TimerPainter extends CustomPainter {
  final double angle;
  TimerPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dialPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final Paint progressPaint = Paint()
      ..color = Colors.red.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final Paint knobPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final Paint strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;

    final Paint handlePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    // Draw the dial
    canvas.drawCircle(center, radius, dialPaint);

    // Draw the progress arc (only half circle)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      angle,
      true,
      progressPaint,
    );

    // Draw the knob
    final knobAngle = -math.pi / 2 + angle;
    final knobPosition = Offset(
      center.dx + radius * math.cos(knobAngle),
      center.dy + radius * math.sin(knobAngle),
    );
    canvas.drawCircle(knobPosition, 10.0, knobPaint);

    // Draw the 24 strokes at the circumference
    for (int i = 0; i < 24; i++) {
      final double strokeAngle = (i * 2 * math.pi) / 24;
      final double outerRadius = radius;
      final double innerRadius = radius - 10;

      final Offset outerPoint = Offset(
        center.dx + outerRadius * math.cos(strokeAngle),
        center.dy + outerRadius * math.sin(strokeAngle),
      );

      final Offset innerPoint = Offset(
        center.dx + innerRadius * math.cos(strokeAngle),
        center.dy + innerRadius * math.sin(strokeAngle),
      );

      canvas.drawLine(innerPoint, outerPoint, strokePaint..color = Colors.grey.shade800);
    }

    final handleEnd = Offset(
      center.dx + (radius / 2) * math.cos(knobAngle),
      center.dy + (radius / 2) * math.sin(knobAngle),
    );
    canvas.drawLine(center, handleEnd, handlePaint);

    // Draw the knob at the center
    canvas.drawCircle(center, 10.0, knobPaint..color = Colors.white);
  }

  int getMinutes() {
    // The total angle is mapped to 120 minutes (2 hours).
    const totalMinutes = 120;
    final minutes = (angle / (2 * math.pi)) * totalMinutes;
    return minutes.round();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class TimerWidget extends StatefulWidget {
  const TimerWidget({super.key});

  @override
  _TimerWidgetState createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> with SingleTickerProviderStateMixin {
  double angle = 0.0;
  int totalTimeInSeconds = 0;
  Timer? countdownTimer;
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _controller!.addListener(() {
      setState(() {
        angle = _animation!.value;
      });
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    countdownTimer?.cancel();
    super.dispose();
  }

  void _updateAngle(Offset position, Size size) {
   final center = Offset(size.width / 2, size.height / 2);
    final touchVector = position - center;
    double touchAngle = touchVector.direction;

    touchAngle = touchAngle + math.pi / 2;
    if (touchAngle < 0) touchAngle += 2 * math.pi;

    totalTimeInSeconds = TimerPainter(angle).getMinutes() * 60;
    // int totalTimeInMinutes = totalTimeInSeconds ~/ 60;
    // if (totalTimeInMinutes % 10 == 0) {
    // }
    setState(() {
      angle = touchAngle;
    });
  }

  void _startTimer() {
    if (countdownTimer != null) {
      countdownTimer!.cancel();
    }
    countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        if (totalTimeInSeconds > 0) {
          totalTimeInSeconds--;
          double newAngle = (totalTimeInSeconds / (120 * 60)) * (2 * math.pi);
          _animateAngle(newAngle);
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _animateAngle(double newAngle) {
    _animation = Tween<double>(begin: angle, end: newAngle).animate(CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeOut,
    ));
    _controller!.forward(from: 0);
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        _updateAngle(details.localPosition, context.size!);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomPaint(
            size: const Size(200, 200),
            painter: TimerPainter(angle: angle),
          ),
          const SizedBox(height: 20),
          Text(
            'Time: ${_formatTime(totalTimeInSeconds)}',
            style: const TextStyle(fontSize: 24, color: Colors.white),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffFF375F),
              foregroundColor: Colors.white,
            ),
            onPressed: _startTimer,
            child: const Text('Start Focusing'),
          ),
        ],
      ),
    );
  }
}
