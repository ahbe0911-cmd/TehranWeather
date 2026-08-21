import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'models.dart';

const appInk = Color(0xFF16324A);
const appMuted = Color(0xFF71869A);
const appBlue = Color(0xFF248FE2);
const appRed = Color(0xFFE84555);

String faDigits(Object value) {
  const en = '0123456789';
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  var text = value.toString();
  for (var i = 0; i < en.length; i++) {
    text = text.replaceAll(en[i], fa[i]);
  }
  return text;
}

String formatTemp(double value) => '${faDigits(value.round())}°';

String formatClock(DateTime value, {bool seconds = false}) {
  final h = value.hour.toString().padLeft(2, '0');
  final m = value.minute.toString().padLeft(2, '0');
  if (!seconds) return faDigits('$h:$m');
  final s = value.second.toString().padLeft(2, '0');
  return faDigits('$h:$m:$s');
}

String shamsiDate(DateTime value) {
  final j = Jalali.fromDateTime(value);
  const months = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];
  const weekdays = [
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
    'شنبه',
    'یکشنبه',
  ];
  return '${weekdays[value.weekday - 1]}، ${faDigits(j.day)} ${months[j.month - 1]} ${faDigits(j.year)}';
}

String shortWeekday(DateTime value) {
  const names = [
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
    'شنبه',
    'یکشنبه',
  ];
  return names[value.weekday - 1];
}

String weatherTitle(int code) {
  if (code == 0) return 'صاف';
  if (code == 1) return 'عمدتاً صاف';
  if (code == 2) return 'نیمه‌ابری';
  if (code == 3) return 'ابری';
  if (code == 45 || code == 48) return 'مه‌آلود';
  if ([51, 53, 55, 56, 57].contains(code)) return 'نم‌نم باران';
  if ([61, 63, 65, 66, 67, 80, 81, 82].contains(code)) return 'بارانی';
  if ([71, 73, 75, 77, 85, 86].contains(code)) return 'برفی';
  if ([95, 96, 99].contains(code)) return 'رعدوبرق';
  return 'متغیر';
}

String currentWeatherText(CurrentWeather current) {
  if (current.precipitation > 0.02) {
    if (current.precipitation < .25) return 'باران بسیار ریز در حال بارش است';
    if (current.precipitation < 1.5) return 'بارش سبک در حال وقوع است';
    return 'بارش فعال در موقعیت شما';
  }
  return weatherTitle(current.weatherCode);
}

IconData weatherIcon(int code, {bool isDay = true}) {
  if (code == 0) return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
  if (code <= 2) return isDay ? Icons.wb_cloudy_rounded : Icons.nights_stay_rounded;
  if (code == 3 || code == 45 || code == 48) return Icons.cloud_rounded;
  if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].contains(code)) {
    return Icons.water_drop_rounded;
  }
  if ([71, 73, 75, 77, 85, 86].contains(code)) return Icons.ac_unit_rounded;
  if ([95, 96, 99].contains(code)) return Icons.thunderstorm_rounded;
  return Icons.cloud_queue_rounded;
}

bool isRainCode(int code) =>
    [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82, 95, 96, 99]
        .contains(code);

bool isSnowCode(int code) => [71, 73, 75, 77, 85, 86].contains(code);

Color weatherAccent(int code, {bool isDay = true}) {
  if (!isDay) return const Color(0xFF6676D9);
  if (isRainCode(code)) return const Color(0xFF168CE0);
  if (isSnowCode(code)) return const Color(0xFF7CB6D9);
  if (code >= 2) return const Color(0xFF7894A9);
  return const Color(0xFFF6B71C);
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 26,
    this.opacity = .88,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double opacity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: .95),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3C6F98).withValues(alpha: .12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: .7),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: box,
      ),
    );
  }
}

class LiveAnalogClock extends StatefulWidget {
  const LiveAnalogClock({super.key, this.size = 260});

  final double size;

  @override
  State<LiveAnalogClock> createState() => _LiveAnalogClockState();
}

class _LiveAnalogClockState extends State<LiveAnalogClock>
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
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size + 34,
        child: AnimatedBuilder(
          animation: _ticker,
          builder: (context, _) {
            final now = DateTime.now();
            return Column(
              children: [
                SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: _LiveClockPainter(now),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatClock(now, seconds: true),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontFamily: 'Titr',
                    color: appInk,
                    fontSize: 21,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LiveClockPainter extends CustomPainter {
  _LiveClockPainter(this.now);

  final DateTime now;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFEAF5FC)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFBFD4E3).withValues(alpha: .75),
    );

    for (var i = 0; i < 60; i++) {
      final angle = (i / 60) * math.pi * 2 - math.pi / 2;
      final major = i % 5 == 0;
      final outer = Offset(
        center.dx + math.cos(angle) * (radius - 10),
        center.dy + math.sin(angle) * (radius - 10),
      );
      final inner = Offset(
        center.dx + math.cos(angle) * (radius - (major ? 23 : 16)),
        center.dy + math.sin(angle) * (radius - (major ? 23 : 16)),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = major ? 2.6 : 1.1
          ..color = major
              ? appInk.withValues(alpha: .78)
              : appInk.withValues(alpha: .22),
      );
    }

    final seconds = now.second + now.millisecond / 1000.0;
    final minutes = now.minute + seconds / 60.0;
    final hours = (now.hour % 12) + minutes / 60.0;
    final hourAngle = hours / 12 * math.pi * 2 - math.pi / 2;
    final minuteAngle = minutes / 60 * math.pi * 2 - math.pi / 2;
    final secondAngle = seconds / 60 * math.pi * 2 - math.pi / 2;

    _hand(
      canvas,
      center,
      hourAngle,
      radius * .48,
      5.5,
      appInk,
    );
    _hand(
      canvas,
      center,
      minuteAngle,
      radius * .68,
      3.5,
      appInk.withValues(alpha: .88),
    );
    _hand(
      canvas,
      center,
      secondAngle,
      radius * .78,
      1.8,
      appRed,
      tail: radius * .16,
    );

    canvas.drawCircle(center, 7.5, Paint()..color = Colors.white);
    canvas.drawCircle(center, 4.7, Paint()..color = appRed);
  }

  void _hand(
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
  bool shouldRepaint(covariant _LiveClockPainter oldDelegate) => true;
}

class AnimatedSky extends StatefulWidget {
  const AnimatedSky({super.key, required this.code, required this.isDay});

  final int code;
  final bool isDay;

  @override
  State<AnimatedSky> createState() => _AnimatedSkyState();
}

class _AnimatedSkyState extends State<AnimatedSky>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _SkyPainter(
            progress: _controller.value,
            code: widget.code,
            isDay: widget.isDay,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  const _SkyPainter({
    required this.progress,
    required this.code,
    required this.isDay,
  });

  final double progress;
  final int code;
  final bool isDay;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = !isDay
        ? const [Color(0xFF566F9B), Color(0xFFDDE9F5)]
        : isRainCode(code)
            ? const [Color(0xFF79A8C9), Color(0xFFEAF4FA)]
            : code >= 2
                ? const [Color(0xFFA5C0D8), Color(0xFFF1F8FC)]
                : const [Color(0xFF8BC9F5), Color(0xFFF6FBFE)];
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect),
    );

    final haze = Paint()..color = Colors.white.withValues(alpha: .13);
    canvas.drawCircle(
      Offset(size.width * .12, size.height * .18),
      size.width * .38,
      haze,
    );
    canvas.drawCircle(
      Offset(size.width * .92, size.height * .52),
      size.width * .55,
      haze,
    );

    if (isDay) {
      final sun = Offset(size.width * .82, size.height * .1);
      final pulse = 1 + math.sin(progress * math.pi * 2) * .05;
      for (var i = 5; i >= 1; i--) {
        canvas.drawCircle(
          sun,
          17.0 * i * pulse,
          Paint()
            ..color = const Color(0xFFFFD464)
                .withValues(alpha: .025 * (6 - i)),
        );
      }
      canvas.drawCircle(
        sun,
        23 * pulse,
        Paint()..color = const Color(0xFFFFD25B),
      );
    } else {
      final moon = Offset(size.width * .82, size.height * .1);
      canvas.drawCircle(
        moon,
        26,
        Paint()..color = Colors.white.withValues(alpha: .94),
      );
      canvas.drawCircle(
        moon + const Offset(10, -7),
        24,
        Paint()..color = colors.first,
      );
    }

    final cloudAlpha = isDay ? .46 : .26;
    _cloud(canvas, size, .15, .22, 0, 1.05, cloudAlpha);
    if (code >= 2 || isRainCode(code) || isSnowCode(code)) {
      _cloud(canvas, size, .68, .31, .37, .8, cloudAlpha);
      _cloud(canvas, size, .42, .13, .72, .63, cloudAlpha * .9);
    }

    if (isRainCode(code)) {
      final drizzle = [51, 53, 55, 56, 57].contains(code);
      final count = drizzle ? 30 : 48;
      final paint = Paint()
        ..color = const Color(0xFF258FD2)
            .withValues(alpha: drizzle ? .3 : .43)
        ..strokeWidth = drizzle ? 1.1 : 1.6
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < count; i++) {
        final seed = (i * .081 + progress * (drizzle ? .75 : 1.45)) % 1.0;
        final x = ((i * 83.0) % size.width) + math.sin(i.toDouble()) * 18;
        final y = seed * size.height;
        final length = drizzle ? 7.0 : 15.0;
        canvas.drawLine(
          Offset(x, y),
          Offset(x - (drizzle ? 1.5 : 4), y + length),
          paint,
        );
      }
    }

    if (isSnowCode(code)) {
      final paint = Paint()..color = Colors.white.withValues(alpha: .78);
      for (var i = 0; i < 32; i++) {
        final seed = (i * .097 + progress * .43) % 1.0;
        final x = ((i * 67.0) % size.width) + math.sin(progress * 8 + i) * 21;
        final y = seed * size.height;
        canvas.drawCircle(Offset(x, y), 1.4 + (i % 3), paint);
      }
    }
  }

  void _cloud(
    Canvas canvas,
    Size size,
    double baseX,
    double baseY,
    double phase,
    double scale,
    double alpha,
  ) {
    final travel = ((progress + phase) % 1.0) * size.width * .36 -
        size.width * .18;
    final center = Offset(size.width * baseX + travel, size.height * baseY);
    final paint = Paint()..color = Colors.white.withValues(alpha: alpha);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: 150 * scale,
        height: 48 * scale,
      ),
      paint,
    );
    canvas.drawCircle(
      center + Offset(-35 * scale, -17 * scale),
      32 * scale,
      paint,
    );
    canvas.drawCircle(
      center + Offset(10 * scale, -24 * scale),
      39 * scale,
      paint,
    );
    canvas.drawCircle(
      center + Offset(46 * scale, -11 * scale),
      27 * scale,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.code != code ||
      oldDelegate.isDay != isDay;
}
