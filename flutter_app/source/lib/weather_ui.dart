import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

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

String formatClock(DateTime value) {
  final h = value.hour.toString().padLeft(2, '0');
  final m = value.minute.toString().padLeft(2, '0');
  return faDigits('$h:$m');
}

String shamsiDate(DateTime value) {
  final j = Jalali.fromDateTime(value);
  const months = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];
  const weekdays = [
    'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه', 'یکشنبه',
  ];
  final weekday = weekdays[value.weekday - 1];
  return '$weekday، ${faDigits(j.day)} ${months[j.month - 1]} ${faDigits(j.year)}';
}

String shortWeekday(DateTime value) {
  const names = ['دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه', 'یکشنبه'];
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

bool isRainCode(int code) => [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82, 95, 96, 99].contains(code);
bool isSnowCode(int code) => [71, 73, 75, 77, 85, 86].contains(code);

class WeatherPalette {
  const WeatherPalette({required this.top, required this.bottom, required this.accent});
  final Color top;
  final Color bottom;
  final Color accent;

  static WeatherPalette from(int code, bool isDay) {
    if (!isDay) {
      return const WeatherPalette(
        top: Color(0xFF09142D),
        bottom: Color(0xFF172B55),
        accent: Color(0xFF8FB5FF),
      );
    }
    if (isRainCode(code)) {
      return const WeatherPalette(
        top: Color(0xFF456C89),
        bottom: Color(0xFF89AFC4),
        accent: Color(0xFFBDE9FF),
      );
    }
    if (code >= 2) {
      return const WeatherPalette(
        top: Color(0xFF7194B5),
        bottom: Color(0xFFBFD4E5),
        accent: Color(0xFFE5F2FF),
      );
    }
    return const WeatherPalette(
      top: Color(0xFF2687E8),
      bottom: Color(0xFF85C9FF),
      accent: Color(0xFFFFD66B),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 28,
    this.opacity = .13,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AnimatedSky extends StatefulWidget {
  const AnimatedSky({super.key, required this.code, required this.isDay});
  final int code;
  final bool isDay;

  @override
  State<AnimatedSky> createState() => _AnimatedSkyState();
}

class _AnimatedSkyState extends State<AnimatedSky> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = WeatherPalette.from(widget.code, widget.isDay);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _SkyPainter(
            progress: _controller.value,
            code: widget.code,
            isDay: widget.isDay,
            palette: palette,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter({required this.progress, required this.code, required this.isDay, required this.palette});
  final double progress;
  final int code;
  final bool isDay;
  final WeatherPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [palette.top, palette.bottom],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    if (isDay) {
      final center = Offset(size.width * .79, size.height * .15);
      final pulse = 1 + math.sin(progress * math.pi * 2) * .06;
      for (var i = 5; i >= 1; i--) {
        canvas.drawCircle(
          center,
          18.0 * i * pulse,
          Paint()..color = palette.accent.withOpacity(.035 * (6 - i)),
        );
      }
      canvas.drawCircle(center, 26 * pulse, Paint()..color = palette.accent.withOpacity(.95));
    } else {
      final moon = Offset(size.width * .8, size.height * .13);
      canvas.drawCircle(moon, 28, Paint()..color = Colors.white.withOpacity(.92));
      canvas.drawCircle(moon + const Offset(10, -7), 25, Paint()..color = palette.top);
      final random = math.Random(9);
      for (var i = 0; i < 45; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height * .55;
        final twinkle = .35 + .65 * ((math.sin(progress * math.pi * 2 + i) + 1) / 2);
        canvas.drawCircle(Offset(x, y), random.nextDouble() * 1.5 + .4, Paint()..color = Colors.white.withOpacity(twinkle));
      }
    }

    final cloudy = code >= 2 || isRainCode(code) || isSnowCode(code);
    if (cloudy) {
      _cloud(canvas, size, .22, .26, progress, 0, 1.0);
      _cloud(canvas, size, .69, .37, progress, .38, .78);
      if (code == 3 || isRainCode(code)) _cloud(canvas, size, .42, .16, progress, .7, .62);
    }

    if (isRainCode(code)) {
      final paint = Paint()
        ..color = const Color(0xFFD6F4FF).withOpacity(.65)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 46; i++) {
        final seed = (i * 0.071 + progress * 1.6) % 1.0;
        final x = ((i * 83.0) % size.width) + math.sin(i.toDouble()) * 18;
        final y = seed * size.height;
        canvas.drawLine(Offset(x, y), Offset(x - 5, y + 17), paint);
      }
    }

    if (isSnowCode(code)) {
      final paint = Paint()..color = Colors.white.withOpacity(.8);
      for (var i = 0; i < 34; i++) {
        final seed = (i * .097 + progress * .45) % 1.0;
        final x = ((i * 67.0) % size.width) + math.sin(progress * 8 + i) * 22;
        final y = seed * size.height;
        canvas.drawCircle(Offset(x, y), 1.8 + (i % 3), paint);
      }
    }
  }

  void _cloud(Canvas canvas, Size size, double baseX, double baseY, double p, double phase, double scale) {
    final travel = ((p + phase) % 1.0) * size.width * .36 - size.width * .18;
    final center = Offset(size.width * baseX + travel, size.height * baseY);
    final paint = Paint()..color = Colors.white.withOpacity(isDay ? .33 : .13);
    canvas.drawOval(Rect.fromCenter(center: center, width: 150 * scale, height: 50 * scale), paint);
    canvas.drawCircle(center + Offset(-35 * scale, -18 * scale), 34 * scale, paint);
    canvas.drawCircle(center + Offset(10 * scale, -25 * scale), 42 * scale, paint);
    canvas.drawCircle(center + Offset(48 * scale, -12 * scale), 28 * scale, paint);
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.code != code || oldDelegate.isDay != isDay;
}
