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

Color weatherAccent(int code, {bool isDay = true}) {
  if (!isDay) return const Color(0xFF5B72F2);
  if (isRainCode(code)) return const Color(0xFF2C91E8);
  if (isSnowCode(code)) return const Color(0xFF7CB6D9);
  if (code >= 2) return const Color(0xFF6E8BA4);
  return const Color(0xFFF3B218);
}

class WeatherPalette {
  const WeatherPalette({required this.top, required this.bottom, required this.accent});
  final Color top;
  final Color bottom;
  final Color accent;

  static WeatherPalette from(int code, bool isDay) {
    if (!isDay) {
      return const WeatherPalette(
        top: Color(0xFF516A9B),
        bottom: Color(0xFFD6E4F4),
        accent: Color(0xFFE7EFFF),
      );
    }
    if (isRainCode(code)) {
      return const WeatherPalette(
        top: Color(0xFF78A5C7),
        bottom: Color(0xFFE6F2FA),
        accent: Color(0xFFD9F3FF),
      );
    }
    if (code >= 2) {
      return const WeatherPalette(
        top: Color(0xFF9CB9D4),
        bottom: Color(0xFFE9F4FB),
        accent: Color(0xFFF5FBFF),
      );
    }
    return const WeatherPalette(
      top: Color(0xFF8EC8F5),
      bottom: Color(0xFFF2F9FF),
      accent: Color(0xFFFFD86A),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
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
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: .92), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4E7CA5).withValues(alpha: .13),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: .65),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: body,
      ),
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
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
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
      builder: (context, _) => CustomPaint(
        painter: _SkyPainter(
          progress: _controller.value,
          code: widget.code,
          isDay: widget.isDay,
          palette: palette,
        ),
        child: const SizedBox.expand(),
      ),
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
    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.top, palette.bottom],
      ).createShader(rect),
    );

    final haze = Paint()..color = Colors.white.withValues(alpha: .12);
    canvas.drawCircle(Offset(size.width * .18, size.height * .12), size.width * .34, haze);
    canvas.drawCircle(Offset(size.width * .86, size.height * .48), size.width * .48, haze);

    if (isDay) {
      final center = Offset(size.width * .79, size.height * .11);
      final pulse = 1 + math.sin(progress * math.pi * 2) * .055;
      for (var i = 5; i >= 1; i--) {
        canvas.drawCircle(
          center,
          17.0 * i * pulse,
          Paint()..color = palette.accent.withValues(alpha: .028 * (6 - i)),
        );
      }
      canvas.drawCircle(center, 23 * pulse, Paint()..color = palette.accent.withValues(alpha: .96));
    } else {
      final moon = Offset(size.width * .8, size.height * .1);
      canvas.drawCircle(moon, 25, Paint()..color = Colors.white.withValues(alpha: .92));
      canvas.drawCircle(moon + const Offset(9, -6), 23, Paint()..color = palette.top);
      final random = math.Random(9);
      for (var i = 0; i < 36; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height * .45;
        final twinkle = .25 + .5 * ((math.sin(progress * math.pi * 2 + i) + 1) / 2);
        canvas.drawCircle(Offset(x, y), random.nextDouble() * 1.2 + .3, Paint()..color = Colors.white.withValues(alpha: twinkle));
      }
    }

    final cloudy = code >= 2 || isRainCode(code) || isSnowCode(code);
    if (cloudy) {
      _cloud(canvas, size, .15, .22, progress, 0, 1.1);
      _cloud(canvas, size, .68, .3, progress, .38, .8);
      if (code == 3 || isRainCode(code)) _cloud(canvas, size, .42, .15, progress, .7, .68);
    } else {
      _cloud(canvas, size, .12, .3, progress, .16, .55);
    }

    if (isRainCode(code)) {
      final paint = Paint()
        ..color = const Color(0xFF3AA5E8).withValues(alpha: .38)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 38; i++) {
        final seed = (i * .081 + progress * 1.45) % 1.0;
        final x = ((i * 83.0) % size.width) + math.sin(i.toDouble()) * 16;
        final y = seed * size.height;
        canvas.drawLine(Offset(x, y), Offset(x - 4, y + 14), paint);
      }
    }

    if (isSnowCode(code)) {
      final paint = Paint()..color = Colors.white.withValues(alpha: .72);
      for (var i = 0; i < 30; i++) {
        final seed = (i * .097 + progress * .45) % 1.0;
        final x = ((i * 67.0) % size.width) + math.sin(progress * 8 + i) * 20;
        final y = seed * size.height;
        canvas.drawCircle(Offset(x, y), 1.5 + (i % 3), paint);
      }
    }
  }

  void _cloud(Canvas canvas, Size size, double baseX, double baseY, double p, double phase, double scale) {
    final travel = ((p + phase) % 1.0) * size.width * .32 - size.width * .16;
    final center = Offset(size.width * baseX + travel, size.height * baseY);
    final paint = Paint()..color = Colors.white.withValues(alpha: isDay ? .44 : .25);
    canvas.drawOval(Rect.fromCenter(center: center, width: 145 * scale, height: 46 * scale), paint);
    canvas.drawCircle(center + Offset(-34 * scale, -17 * scale), 31 * scale, paint);
    canvas.drawCircle(center + Offset(9 * scale, -24 * scale), 38 * scale, paint);
    canvas.drawCircle(center + Offset(45 * scale, -11 * scale), 26 * scale, paint);
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.code != code || oldDelegate.isDay != isDay;
}
