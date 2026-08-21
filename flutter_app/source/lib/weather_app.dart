import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'models.dart';
import 'services.dart';
import 'weather_ui.dart';

const _ink = Color(0xFF17324D);
const _muted = Color(0xFF718397);
const _blue = Color(0xFF2698ED);
const _red = Color(0xFFFF6173);

class WeatherNativeApp extends StatelessWidget {
  const WeatherNativeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'هواشناسی',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _blue,
          brightness: Brightness.light,
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: _ink,
              displayColor: _ink,
            ),
      ),
      home: const WeatherShell(),
    );
  }
}

class WeatherShell extends StatefulWidget {
  const WeatherShell({super.key});

  @override
  State<WeatherShell> createState() => _WeatherShellState();
}

class _WeatherShellState extends State<WeatherShell> with WidgetsBindingObserver {
  final _location = LocationService();
  final _weather = const WeatherService();
  final _cache = WeatherCache();

  WeatherSnapshot? _snapshot;
  LocationProblem? _locationProblem;
  String? _error;
  bool _loading = true;
  bool _refreshing = false;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _locationProblem != null) {
      _refresh();
    }
  }

  Future<void> _start() async {
    final cached = await _cache.load();
    if (mounted && cached != null) {
      setState(() => _snapshot = cached);
    }
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _loading = _snapshot == null;
      _error = null;
      _locationProblem = null;
    });
    try {
      final point = await _location.locate();
      final fresh = await _weather.fetch(point);
      await _cache.save(fresh);
      if (!mounted) return;
      setState(() {
        _snapshot = fresh;
        _loading = false;
      });
    } on LocationProblem catch (e) {
      if (!mounted) return;
      setState(() {
        _locationProblem = e;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'دریافت اطلاعات زنده ممکن نشد. اینترنت را بررسی کنید.';
        _loading = false;
      });
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _snapshot;
    final code = s?.current.weatherCode ?? 0;
    final isDay = s?.current.isDay ?? true;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: AnimatedSky(code: code, isDay: isDay)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: .08),
                      const Color(0xFFEAF5FD).withValues(alpha: .3),
                      const Color(0xFFF7FBFE).withValues(alpha: .78),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: _loading && s == null
                  ? const _LoadingView()
                  : s == null
                      ? _ProblemView(
                          problem: _locationProblem,
                          error: _error,
                          retry: _refresh,
                          locationSettings: _location.openLocationSettings,
                          appSettings: _location.openAppSettings,
                        )
                      : Column(
                          children: [
                            _Header(
                              snapshot: s,
                              refreshing: _refreshing,
                              refresh: _refresh,
                              showLocation: () => _showLocation(s.location),
                            ),
                            if (s.fromCache || _error != null || _locationProblem != null)
                              _CachedBanner(onTap: _refresh),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: 350.ms,
                                transitionBuilder: (child, animation) => FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(.03, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                                child: switch (_tab) {
                                  1 => _DailyTab(key: const ValueKey(1), snapshot: s),
                                  2 => _LocationTab(
                                      key: const ValueKey(2),
                                      snapshot: s,
                                      refresh: _refresh,
                                      showLocation: () => _showLocation(s.location),
                                    ),
                                  3 => _DetailsTab(key: const ValueKey(3), snapshot: s),
                                  _ => _HomeTab(key: const ValueKey(0), snapshot: s),
                                },
                              ),
                            ),
                            _Navigation(
                              index: _tab,
                              changed: (v) => setState(() => _tab = v),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocation(GeoPointInfo p) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF5FAFE),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            8,
            22,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _blue.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.my_location_rounded, color: _blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.label,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        if (p.addressLine != null)
                          Text(
                            p.addressLine!,
                            style: const TextStyle(color: _muted, height: 1.5),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _LocationLine('عرض جغرافیایی', faDigits(p.latitude.toStringAsFixed(6))),
              _LocationLine('طول جغرافیایی', faDigits(p.longitude.toStringAsFixed(6))),
              _LocationLine('دقت GPS', '±${faDigits(p.accuracy.round())} متر'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _refresh();
                  },
                  icon: const Icon(Icons.gps_fixed_rounded),
                  label: const Text('دریافت دوباره موقعیت دقیق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.snapshot,
    required this.refreshing,
    required this.refresh,
    required this.showLocation,
  });

  final WeatherSnapshot snapshot;
  final bool refreshing;
  final VoidCallback refresh;
  final VoidCallback showLocation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          _HeaderButton(
            icon: Icons.menu_rounded,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('منوی کامل در نسخه بعدی فعال می‌شود.')),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: showLocation,
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      snapshot.location.label,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.location_on_rounded, color: _blue, size: 20),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  shamsiDate(DateTime.now()),
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 10.5, color: _muted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _HeaderButton(
                icon: refreshing ? Icons.sync_rounded : Icons.notifications_none_rounded,
                onTap: refreshing ? null : refresh,
              ),
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: _ink, size: 23),
          ),
        ),
      );
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({super.key, required this.snapshot});
  final WeatherSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final c = snapshot.current;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
      children: [
        _WeatherClockCard(snapshot: snapshot)
            .animate()
            .fadeIn(duration: 450.ms)
            .slideY(begin: .04, end: 0),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PillMetric(
                icon: Icons.wb_sunny_rounded,
                iconColor: const Color(0xFFF7B719),
                value: formatTemp(c.temperature),
                label: 'دما',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PillMetric(
                icon: Icons.water_drop_rounded,
                iconColor: _blue,
                value: '${faDigits(c.humidity)}٪',
                label: 'رطوبت',
              ),
            ),
          ],
        ).animate().fadeIn(delay: 90.ms),
        const SizedBox(height: 12),
        _HourlyRainCard(items: snapshot.hourly)
            .animate()
            .fadeIn(delay: 150.ms)
            .slideY(begin: .04, end: 0),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 9,
          crossAxisSpacing: 9,
          childAspectRatio: .76,
          children: [
            _MetricTile(
              icon: Icons.device_thermostat_rounded,
              iconColor: const Color(0xFFE69A1F),
              value: formatTemp(c.apparentTemperature),
              label: 'دمای احساسی',
            ),
            _MetricTile(
              icon: Icons.air_rounded,
              iconColor: _blue,
              value: faDigits(c.windSpeed.round()),
              label: 'سرعت باد km/h',
            ),
            _MetricTile(
              icon: Icons.water_drop_outlined,
              iconColor: _blue,
              value: '${faDigits(c.humidity)}٪',
              label: 'رطوبت هوا',
            ),
            _MetricTile(
              icon: Icons.cloud_outlined,
              iconColor: const Color(0xFF78A7C8),
              value: faDigits(c.pressure.round()),
              label: 'فشار هوا hPa',
            ),
          ],
        ).animate().fadeIn(delay: 220.ms),
      ],
    );
  }
}

class _WeatherClockCard extends StatelessWidget {
  const _WeatherClockCard({required this.snapshot});
  final WeatherSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final c = snapshot.current;
    return GlassCard(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        children: [
          SizedBox(
            height: 285,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ClockPainter(now: DateTime.now()),
                  ),
                ),
                Positioned(
                  bottom: 45,
                  child: Column(
                    children: [
                      Text(
                        weatherTitle(c.weatherCode),
                        style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatClock(c.time),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _ink),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 17,
                  right: 36,
                  child: Icon(
                    weatherIcon(c.weatherCode, isDay: c.isDay),
                    color: weatherAccent(c.weatherCode, isDay: c.isDay),
                    size: 34,
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(begin: const Offset(.96, .96), end: const Offset(1.06, 1.06), duration: 1800.ms),
                ),
              ],
            ),
          ),
          Text(
            'به‌روزرسانی ${formatClock(snapshot.fetchedAt)}',
            style: const TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter({required this.now});
  final DateTime now;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 4);
    final radius = math.min(size.width, size.height) * .43;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: .58),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = const Color(0xFFC8D7E3),
    );

    for (var i = 0; i < 60; i++) {
      final angle = i * math.pi / 30 - math.pi / 2;
      final major = i % 5 == 0;
      final start = center + Offset(math.cos(angle), math.sin(angle)) * (radius - (major ? 15 : 9));
      final end = center + Offset(math.cos(angle), math.sin(angle)) * (radius - 3);
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = major ? const Color(0xFF9FB4C6) : const Color(0xFFD5E0E8)
          ..strokeWidth = major ? 2 : 1,
      );
    }

    final textPainter = TextPainter(textDirection: TextDirection.rtl, textAlign: TextAlign.center);
    for (var h = 1; h <= 12; h++) {
      final angle = h * math.pi / 6 - math.pi / 2;
      final pos = center + Offset(math.cos(angle), math.sin(angle)) * (radius - 28);
      textPainter.text = TextSpan(
        text: faDigits(h),
        style: const TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w800),
      );
      textPainter.layout();
      textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    final second = now.second + now.millisecond / 1000;
    final minute = now.minute + second / 60;
    final hour = (now.hour % 12) + minute / 60;
    _hand(canvas, center, hour * math.pi / 6 - math.pi / 2, radius * .48, 5.5, const Color(0xFF1CB1C8));
    _hand(canvas, center, minute * math.pi / 30 - math.pi / 2, radius * .68, 4.2, const Color(0xFFE84D65));
    _hand(canvas, center, second * math.pi / 30 - math.pi / 2, radius * .75, 1.7, const Color(0xFFF1A91A));
    canvas.drawCircle(center, 7, Paint()..color = _ink);
  }

  void _hand(Canvas canvas, Offset center, double angle, double length, double width, Color color) {
    final end = center + Offset(math.cos(angle), math.sin(angle)) * length;
    canvas.drawLine(
      center,
      end,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) => oldDelegate.now.minute != now.minute;
}

class _PillMetric extends StatelessWidget {
  const _PillMetric({required this.icon, required this.iconColor, required this.value, required this.label});
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => GlassCard(
        radius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 31, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  Text(label, style: const TextStyle(fontSize: 11, color: _muted)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _HourlyRainCard extends StatelessWidget {
  const _HourlyRainCard({required this.items});
  final List<HourlyWeather> items;

  @override
  Widget build(BuildContext context) {
    final count = math.min(6, items.length);
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('احتمال بارش در هر ساعت', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 13),
          Row(
            children: List.generate(count, (i) {
              final h = items[i];
              return Expanded(
                child: Column(
                  children: [
                    Text(i == 0 ? 'اکنون' : formatClock(h.time), style: const TextStyle(color: _muted, fontSize: 9.5)),
                    const SizedBox(height: 7),
                    Icon(
                      weatherIcon(h.weatherCode),
                      color: weatherAccent(h.weatherCode),
                      size: 25,
                    ),
                    const SizedBox(height: 5),
                    Text('${faDigits(h.precipitationProbability)}٪', style: const TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Container(
                      width: 21,
                      height: 4 + h.precipitationProbability * .14,
                      constraints: const BoxConstraints(maxHeight: 22),
                      decoration: BoxDecoration(
                        color: _blue.withValues(alpha: .85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.icon, required this.iconColor, required this.value, required this.label});
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => GlassCard(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 25, color: iconColor),
            const SizedBox(height: 8),
            Text(value, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: _muted, height: 1.25)),
          ],
        ),
      );
}

class _DailyTab extends StatelessWidget {
  const _DailyTab({super.key, required this.snapshot});
  final WeatherSnapshot snapshot;

  @override
  Widget build(BuildContext context) => ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
        children: [
          const _PageTitle(title: 'پیش‌بینی ۷ روز آینده', icon: Icons.calendar_month_rounded),
          const SizedBox(height: 12),
          ...List.generate(snapshot.daily.length, (i) {
            final d = snapshot.daily[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: GlassCard(
                radius: 22,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(i == 0 ? 'امروز' : shortWeekday(d.date), style: const TextStyle(fontWeight: FontWeight.w900)),
                          Text(shamsiDate(d.date).split('،').last.trim(), style: const TextStyle(fontSize: 9, color: _muted)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(formatTemp(d.minTemperature), style: const TextStyle(color: _blue, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 16),
                    Text(formatTemp(d.maxTemperature), style: const TextStyle(color: _red, fontSize: 17, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    Column(
                      children: [
                        Icon(weatherIcon(d.weatherCode), color: weatherAccent(d.weatherCode), size: 29),
                        const SizedBox(height: 3),
                        Text('${faDigits(d.precipitationProbability)}٪', style: const TextStyle(color: _blue, fontSize: 9, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (i * 40).ms).slideY(begin: .03, end: 0),
            );
          }),
          if (snapshot.daily.isNotEmpty) ...[
            const SizedBox(height: 4),
            GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.umbrella_rounded, color: _blue, size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('خلاصه وضعیت', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(
                          'بیشترین احتمال بارش هفته ${faDigits(snapshot.daily.map((e) => e.precipitationProbability).reduce(math.max))}٪ است.',
                          style: const TextStyle(fontSize: 11, height: 1.6, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
}

class _LocationTab extends StatelessWidget {
  const _LocationTab({
    super.key,
    required this.snapshot,
    required this.refresh,
    required this.showLocation,
  });

  final WeatherSnapshot snapshot;
  final VoidCallback refresh;
  final VoidCallback showLocation;

  @override
  Widget build(BuildContext context) {
    final p = snapshot.location;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
      children: [
        const _PageTitle(title: 'موقعیت دقیق GPS', icon: Icons.map_rounded),
        const SizedBox(height: 12),
        GlassCard(
          radius: 28,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 360,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _RadarPainter())),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: _blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(color: _blue.withValues(alpha: .35), blurRadius: 25, spreadRadius: 5),
                          ],
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 31),
                      )
                          .animate(onPlay: (controller) => controller.repeat(reverse: true))
                          .scale(begin: const Offset(.96, .96), end: const Offset(1.08, 1.08), duration: 1500.ms),
                      const SizedBox(height: 10),
                      Text(p.label, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                      Text('دقت ±${faDigits(p.accuracy.round())} متر', style: const TextStyle(color: _muted, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _CoordinateCard(label: 'عرض جغرافیایی', value: faDigits(p.latitude.toStringAsFixed(6)))),
            const SizedBox(width: 10),
            Expanded(child: _CoordinateCard(label: 'طول جغرافیایی', value: faDigits(p.longitude.toStringAsFixed(6)))),
          ],
        ),
        if (p.addressLine != null) ...[
          const SizedBox(height: 10),
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.place_outlined, color: _blue),
                const SizedBox(width: 10),
                Expanded(child: Text(p.addressLine!, style: const TextStyle(color: _muted, height: 1.5))),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: refresh,
                icon: const Icon(Icons.gps_fixed_rounded),
                label: const Text('GPS جدید'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: showLocation,
                icon: const Icon(Icons.info_outline_rounded),
                label: const Text('جزئیات'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final base = Paint()..color = const Color(0xFFDBF0FB);
    canvas.drawRect(Offset.zero & size, base);

    final grid = Paint()
      ..color = const Color(0xFF8FC4E6).withValues(alpha: .35)
      ..strokeWidth = 1;
    for (var x = 20.0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 20.0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final rings = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _blue.withValues(alpha: .22);
    for (var r = 45.0; r <= 150; r += 35) {
      canvas.drawCircle(center, r, rings);
    }

    final random = math.Random(15);
    for (var i = 0; i < 26; i++) {
      final px = random.nextDouble() * size.width;
      final py = random.nextDouble() * size.height;
      final radius = 18 + random.nextDouble() * 45;
      canvas.drawCircle(
        Offset(px, py),
        radius,
        Paint()..color = const Color(0xFF58A9E7).withValues(alpha: .035 + random.nextDouble() * .05),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CoordinateCard extends StatelessWidget {
  const _CoordinateCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => GlassCard(
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: _muted)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      );
}

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({super.key, required this.snapshot});
  final WeatherSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final c = snapshot.current;
    final today = snapshot.daily.isNotEmpty ? snapshot.daily.first : null;
    final details = <_DetailData>[
      _DetailData(Icons.cloud_outlined, 'پوشش ابر', '${faDigits(c.cloudCover)}٪', const Color(0xFF759DBB)),
      _DetailData(Icons.air_rounded, 'جهت باد', '${faDigits(c.windDirection.round())}°', _blue),
      _DetailData(Icons.speed_rounded, 'فشار هوا', '${faDigits(c.pressure.round())} hPa', const Color(0xFF6484A0)),
      _DetailData(Icons.water_drop_rounded, 'بارش فعلی', '${faDigits(c.precipitation.toStringAsFixed(1))} mm', _blue),
      _DetailData(Icons.device_thermostat_rounded, 'دمای احساسی', formatTemp(c.apparentTemperature), const Color(0xFFE89B28)),
      _DetailData(Icons.water_drop_outlined, 'رطوبت', '${faDigits(c.humidity)}٪', _blue),
      if (today != null) _DetailData(Icons.wb_twilight_rounded, 'طلوع خورشید', formatClock(today.sunrise), const Color(0xFFF0AA20)),
      if (today != null) _DetailData(Icons.nights_stay_outlined, 'غروب خورشید', formatClock(today.sunset), const Color(0xFF7D79C9)),
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
      children: [
        const _PageTitle(title: 'جزئیات وضعیت', icon: Icons.info_outline_rounded),
        const SizedBox(height: 12),
        GridView.builder(
          itemCount: details.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.28,
          ),
          itemBuilder: (context, i) {
            final d = details[i];
            return GlassCard(
              radius: 22,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(d.icon, color: d.color, size: 30),
                  const SizedBox(height: 9),
                  Text(d.value, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(d.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: _muted)),
                ],
              ),
            ).animate().fadeIn(delay: (i * 35).ms).scale(begin: const Offset(.97, .97));
          },
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: _blue.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.gps_fixed_rounded, color: _blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('منبع موقعیت', style: TextStyle(fontWeight: FontWeight.w900)),
                    Text('GPS دستگاه • دقت ±${faDigits(snapshot.location.accuracy.round())} متر', style: const TextStyle(fontSize: 10, color: _muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailData {
  const _DetailData(this.icon, this.label, this.value, this.color);
  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: _ink, size: 22),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      );
}

class _Navigation extends StatelessWidget {
  const _Navigation({required this.index, required this.changed});
  final int index;
  final ValueChanged<int> changed;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 4, 18, bottom > 10 ? bottom : 10),
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .91),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(color: const Color(0xFF4E7CA5).withValues(alpha: .15), blurRadius: 24, offset: const Offset(0, 9)),
          ],
        ),
        child: Row(
          children: [
            _NavItem(index: 0, selected: index == 0, icon: Icons.schedule_rounded, label: 'ساعتی', changed: changed),
            _NavItem(index: 1, selected: index == 1, icon: Icons.calendar_month_rounded, label: 'روزانه', changed: changed),
            _NavItem(index: 2, selected: index == 2, icon: Icons.map_rounded, label: 'موقعیت', changed: changed),
            _NavItem(index: 3, selected: index == 3, icon: Icons.info_outline_rounded, label: 'اطلاعات', changed: changed),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.selected,
    required this.icon,
    required this.label,
    required this.changed,
  });

  final int index;
  final bool selected;
  final IconData icon;
  final String label;
  final ValueChanged<int> changed;

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: () => changed(index),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: 220.ms,
            decoration: BoxDecoration(
              color: selected ? _blue : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              boxShadow: selected
                  ? [BoxShadow(color: _blue.withValues(alpha: .3), blurRadius: 15, offset: const Offset(0, 6))]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: selected ? Colors.white : _muted, size: 21),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : _muted,
                    fontSize: 9,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _CachedBanner extends StatelessWidget {
  const _CachedBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
        child: Material(
          color: const Color(0xFFFFF4DA),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.cloud_off_rounded, size: 16, color: Color(0xFFC38619)),
                  SizedBox(width: 7),
                  Expanded(child: Text('اطلاعات ذخیره‌شده؛ برای بروزرسانی لمس کنید.', style: TextStyle(fontSize: 10, color: Color(0xFF8B681C)))),
                ],
              ),
            ),
          ),
        ),
      );
}

class _LocationLine extends StatelessWidget {
  const _LocationLine(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: _muted))),
            Text(value, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _ProblemView extends StatelessWidget {
  const _ProblemView({
    required this.problem,
    required this.error,
    required this.retry,
    required this.locationSettings,
    required this.appSettings,
  });

  final LocationProblem? problem;
  final String? error;
  final VoidCallback retry;
  final Future<void> Function() locationSettings;
  final Future<void> Function() appSettings;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_searching_rounded, size: 56, color: _blue),
                const SizedBox(height: 16),
                const Text('موقعیت دقیق برای آب‌وهوای واقعی', textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                const SizedBox(height: 9),
                Text(problem?.message ?? error ?? 'خطایی رخ داده است.', textAlign: TextAlign.center, style: const TextStyle(height: 1.7, color: _muted)),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: retry, icon: const Icon(Icons.gps_fixed), label: const Text('تلاش دوباره'))),
                if (problem != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        if (problem!.permanentlyDenied) {
                          appSettings();
                        } else {
                          locationSettings();
                        }
                      },
                      child: Text(problem!.permanentlyDenied ? 'باز کردن تنظیمات برنامه' : 'باز کردن تنظیمات موقعیت'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => Center(
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_searching_rounded, size: 52, color: _blue)
                  .animate(onPlay: (controller) => controller.repeat())
                  .rotate(duration: 1600.ms),
              const SizedBox(height: 16),
              const Text('در حال یافتن موقعیت دقیق شما…', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              const Text('GPS و اینترنت روشن باشد', style: TextStyle(fontSize: 10, color: _muted)),
            ],
          ),
        ),
      );
}
