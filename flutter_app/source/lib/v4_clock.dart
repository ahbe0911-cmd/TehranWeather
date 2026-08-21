import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';
import 'weather_ui.dart';

class V4WeatherClock extends StatefulWidget {
  const V4WeatherClock({
    super.key,
    required this.snapshot,
    required this.size,
  });

  final WeatherSnapshot snapshot;
  final double size;

  @override
  State<V4WeatherClock> createState() => _V4WeatherClockState();
}

class _V4WeatherClockState extends State<V4WeatherClock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = widget.snapshot.daily.isEmpty ? null : widget.snapshot.daily.first;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ticker,
        builder: (context, _) {
          final now = DateTime.now();
          final marks = _forecastMarks(widget.snapshot, now);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _V4ClockPainter(now),
                      ),
                    ),
                    ..._numberWidgets(widget.size),
                    ..._forecastWidgets(widget.size, marks),
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: appRed,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: appRed.withValues(alpha: .24),
                                blurRadius: 9,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                shamsiDate(now),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Nazanin',
                  color: appInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _InfoChip(
                    icon: Icons.wb_sunny_rounded,
                    iconColor: const Color(0xFFF2B019),
                    text: today == null
                        ? 'طلوع نامشخص'
                        : 'طلوع ${formatClock(today.sunrise)}',
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.access_time_rounded,
                    iconColor: appRed,
                    text: formatClock(now, seconds: true),
                    ltr: true,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  List<_ForecastMark> _forecastMarks(WeatherSnapshot snapshot, DateTime now) {
    final currentCode = snapshot.current.precipitation > .02 &&
            !isRainCode(snapshot.current.weatherCode)
        ? 51
        : snapshot.current.weatherCode;

    final marks = <_ForecastMark>[
      _ForecastMark(
        time: now,
        weatherCode: currentCode,
        current: true,
      ),
    ];

    for (final item in snapshot.hourly) {
      if (!item.time.isAfter(now.add(const Duration(minutes: 20)))) continue;
      marks.add(_ForecastMark(time: item.time, weatherCode: item.weatherCode));
      if (marks.length >= 12) break;
    }
    return marks;
  }

  List<Widget> _numberWidgets(double size) {
    final center = size / 2;
    final radius = size * .465;
    final result = <Widget>[];
    for (var number = 1; number <= 12; number++) {
      final angle = number / 12 * math.pi * 2 - math.pi / 2;
      final x = center + math.cos(angle) * radius;
      final y = center + math.sin(angle) * radius;
      result.add(
        Positioned(
          left: x - 16,
          top: y - 15,
          width: 32,
          height: 30,
          child: Center(
            child: Text(
              faDigits(number),
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontFamily: 'Titr',
                color: appInk.withValues(alpha: .9),
                fontSize: number >= 10 ? 13 : 14,
                height: 1,
              ),
            ),
          ),
        ),
      );
    }
    return result;
  }

  List<Widget> _forecastWidgets(double size, List<_ForecastMark> marks) {
    final center = size / 2;
    final radius = size * .325;
    return marks.map((mark) {
      final decimalHour = mark.time.hour + mark.time.minute / 60.0;
      final angle = decimalHour / 12 * math.pi * 2 - math.pi / 2;
      final x = center + math.cos(angle) * radius;
      final y = center + math.sin(angle) * radius;
      final color = weatherAccent(
        mark.weatherCode,
        isDay: widget.snapshot.current.isDay,
      );
      return Positioned(
        left: x - 13,
        top: y - 13,
        width: 26,
        height: 26,
        child: Container(
          decoration: BoxDecoration(
            color: mark.current
                ? color.withValues(alpha: .17)
                : Colors.white.withValues(alpha: .78),
            shape: BoxShape.circle,
            border: Border.all(
              color: mark.current
                  ? color.withValues(alpha: .42)
                  : const Color(0xFFDCEAF3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4E7A96).withValues(alpha: .10),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            weatherIcon(mark.weatherCode, isDay: widget.snapshot.current.isDay),
            size: 14,
            color: color,
          ),
        ),
      );
    }).toList();
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.ltr = false,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final bool ltr;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FC),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE0EDF5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 5),
            Text(
              text,
              textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'Nazanin',
                color: appInk,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _ForecastMark {
  const _ForecastMark({
    required this.time,
    required this.weatherCode,
    this.current = false,
  });

  final DateTime time;
  final int weatherCode;
  final bool current;
}

class _V4ClockPainter extends CustomPainter {
  const _V4ClockPainter(this.now);

  final DateTime now;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * .405;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center + const Offset(0, 6),
      radius,
      Paint()
        ..color = const Color(0xFF356C8E).withValues(alpha: .10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.22, -.28),
          radius: 1.08,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF7FBFE),
            Color(0xFFE7F3FA),
          ],
        ).createShader(rect),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white.withValues(alpha: .92),
    );
    canvas.drawCircle(
      center,
      radius - 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFB8D2E2).withValues(alpha: .78),
    );

    for (var i = 0; i < 60; i++) {
      final angle = i / 60 * math.pi * 2 - math.pi / 2;
      final major = i % 5 == 0;
      final outerRadius = radius - 10;
      final innerRadius = radius - (major ? 24 : 17);
      final outer = Offset(
        center.dx + math.cos(angle) * outerRadius,
        center.dy + math.sin(angle) * outerRadius,
      );
      final inner = Offset(
        center.dx + math.cos(angle) * innerRadius,
        center.dy + math.sin(angle) * innerRadius,
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = major ? 2.7 : 1.05
          ..color = major
              ? appInk.withValues(alpha: .60)
              : appInk.withValues(alpha: .18),
      );
    }

    final seconds = now.second + now.millisecond / 1000.0;
    final minutes = now.minute + seconds / 60.0;
    final hours = (now.hour % 12) + minutes / 60.0;

    final hourAngle = hours / 12 * math.pi * 2 - math.pi / 2;
    final minuteAngle = minutes / 60 * math.pi * 2 - math.pi / 2;
    final secondAngle = seconds / 60 * math.pi * 2 - math.pi / 2;

    _drawHand(
      canvas,
      center,
      hourAngle,
      radius * .49,
      6,
      appInk,
    );
    _drawHand(
      canvas,
      center,
      minuteAngle,
      radius * .68,
      4,
      const Color(0xFF294C66),
    );
    _drawHand(
      canvas,
      center,
      secondAngle,
      radius * .80,
      1.7,
      appRed,
      tail: radius * .18,
    );
  }

  void _drawHand(
    Canvas canvas,
    Offset center,
    double angle,
    double length,
    double width,
    Color color, {
    double tail = 0,
  }) {
    final end = Offset(
      center.dx + math.cos(angle) * length,
      center.dy + math.sin(angle) * length,
    );
    final start = tail == 0
        ? center
        : Offset(
            center.dx - math.cos(angle) * tail,
            center.dy - math.sin(angle) * tail,
          );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _V4ClockPainter oldDelegate) => true;
}
