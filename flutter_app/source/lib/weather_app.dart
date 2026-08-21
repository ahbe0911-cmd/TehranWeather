import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'models.dart';
import 'services.dart';
import 'weather_ui.dart';

class WeatherNativeApp extends StatelessWidget {
  const WeatherNativeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'هواشناسی صفی‌آباد',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D9CDB),
          brightness: Brightness.dark,
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
    if (mounted && cached != null) setState(() => _snapshot = cached);
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
    final day = s?.current.isDay ?? true;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: AnimatedSky(code: code, isDay: day)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(.02), Colors.black.withOpacity(.28)],
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
                                duration: 400.ms,
                                child: switch (_tab) {
                                  1 => _HourlyTab(key: const ValueKey(1), snapshot: s),
                                  2 => _WeeklyTab(key: const ValueKey(2), snapshot: s),
                                  _ => _NowTab(key: const ValueKey(0), snapshot: s),
                                },
                              ),
                            ),
                            _Navigation(index: _tab, changed: (v) => setState(() => _tab = v)),
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
      backgroundColor: const Color(0xFF142D47),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 24, 22, MediaQuery.paddingOf(context).bottom + 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.my_location_rounded, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.label, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                    if (p.addressLine != null)
                      Text(p.addressLine!, style: TextStyle(color: Colors.white.withOpacity(.65), height: 1.6)),
                  ]),
                ),
              ]),
              const SizedBox(height: 20),
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

class _LocationLine extends StatelessWidget {
  const _LocationLine(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(color: Colors.white.withOpacity(.65)))),
          Text(value, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900)),
        ]),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.snapshot, required this.refreshing, required this.refresh, required this.showLocation});
  final WeatherSnapshot snapshot;
  final bool refreshing;
  final VoidCallback refresh;
  final VoidCallback showLocation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(children: [
        IconButton.filledTonal(
          onPressed: refreshing ? null : refresh,
          icon: refreshing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh_rounded),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: showLocation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.location_on_rounded, size: 18),
                const SizedBox(width: 4),
                Text(snapshot.location.label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 2),
              Text(shamsiDate(DateTime.now()), style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(.72))),
            ]),
          ),
        ),
        const Spacer(),
        IconButton.filledTonal(
          onPressed: () => showAboutDialog(
            context: context,
            applicationName: 'هواشناسی صفی‌آباد',
            applicationVersion: '۱.۰.۰ Native',
            children: const [Text('Flutter Native • GPS واقعی • Open-Meteo')],
          ),
          icon: const Icon(Icons.info_outline_rounded),
        ),
      ]),
    );
  }
}

class _CachedBanner extends StatelessWidget {
  const _CachedBanner({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
        child: Material(
          color: Colors.orange.withOpacity(.16),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                Icon(Icons.cloud_off_rounded, size: 16),
                SizedBox(width: 7),
                Expanded(child: Text('اطلاعات ذخیره‌شده؛ برای بروزرسانی لمس کنید.', style: TextStyle(fontSize: 11))),
              ]),
            ),
          ),
        ),
      );
}

class _NowTab extends StatelessWidget {
  const _NowTab({super.key, required this.snapshot});
  final WeatherSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final c = snapshot.current;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      children: [
        const SizedBox(height: 4),
        Center(
          child: Column(children: [
            Icon(
              weatherIcon(c.weatherCode, isDay: c.isDay),
              size: 76,
              color: c.isDay ? const Color(0xFFFFE275) : const Color(0xFFE5EEFF),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(begin: const Offset(.96, .96), end: const Offset(1.05, 1.05), duration: 1700.ms),
            Text(formatTemp(c.temperature), style: const TextStyle(fontSize: 84, height: 1, fontWeight: FontWeight.w200, letterSpacing: -4))
                .animate().fadeIn(duration: 450.ms).slideY(begin: .1, end: 0),
            const SizedBox(height: 5),
            Text(weatherTitle(c.weatherCode), style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
            Text('حس می‌شود ${formatTemp(c.apparentTemperature)}', style: TextStyle(color: Colors.white.withOpacity(.72))),
          ]),
        ),
        const SizedBox(height: 22),
        GlassCard(
          child: Row(children: [
            _Metric(Icons.water_drop_rounded, 'رطوبت', '${faDigits(c.humidity)}٪'),
            _VLine(),
            _Metric(Icons.air_rounded, 'باد', '${faDigits(c.windSpeed.round())} km/h'),
            _VLine(),
            _Metric(Icons.speed_rounded, 'فشار', '${faDigits(c.pressure.round())} hPa'),
          ]),
        ).animate().fadeIn(delay: 120.ms).slideY(begin: .08, end: 0),
        const SizedBox(height: 13),
        _HourStrip(items: snapshot.hourly),
        const SizedBox(height: 13),
        Row(children: [
          Expanded(child: GlassCard(child: _SmallMetric(Icons.grain_rounded, 'بارش', '${faDigits(c.precipitation.toStringAsFixed(1))} mm'))),
          const SizedBox(width: 11),
          Expanded(child: GlassCard(child: _SmallMetric(Icons.cloud_rounded, 'پوشش ابر', '${faDigits(c.cloudCover)}٪'))),
        ]),
        const SizedBox(height: 13),
        GlassCard(
          child: Row(children: [
            const Icon(Icons.gps_fixed_rounded, size: 28),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('موقعیت دقیق GPS', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                '${faDigits(snapshot.location.latitude.toStringAsFixed(5))} , ${faDigits(snapshot.location.longitude.toStringAsFixed(5))}',
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(.7)),
              ),
            ])),
            Text('±${faDigits(snapshot.location.accuracy.round())}m', style: const TextStyle(fontWeight: FontWeight.w900)),
          ]),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.icon, this.title, this.value);
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Icon(icon, size: 22),
          const SizedBox(height: 7),
          Text(value, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(title, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(.63))),
        ]),
      );
}

class _VLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 48, color: Colors.white.withOpacity(.12));
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric(this.icon, this.title, this.value);
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 24),
        const SizedBox(height: 10),
        Text(value, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(.65))),
      ]);
}

class _HourStrip extends StatelessWidget {
  const _HourStrip({required this.items});
  final List<HourlyWeather> items;
  @override
  Widget build(BuildContext context) => GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ساعت‌های آینده', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: math.min(10, items.length),
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (context, i) {
                final h = items[i];
                return Container(
                  width: 65,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(i == 0 ? .15 : .07),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(i == 0 ? 'اکنون' : formatClock(h.time), style: const TextStyle(fontSize: 10)),
                    Icon(weatherIcon(h.weatherCode), size: 22),
                    Text(formatTemp(h.temperature), style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text('${faDigits(h.precipitationProbability)}٪', style: const TextStyle(fontSize: 10, color: Color(0xFFC6EDFF))),
                  ]),
                );
              },
            ),
          ),
        ]),
      );
}

class _HourlyTab extends StatelessWidget {
  const _HourlyTab({super.key, required this.snapshot});
  final WeatherSnapshot snapshot;
  @override
  Widget build(BuildContext context) => ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
        itemCount: snapshot.hourly.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final h = snapshot.hourly[i];
          return GlassCard(
            radius: 21,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            child: Row(children: [
              SizedBox(width: 58, child: Text(i == 0 ? 'اکنون' : formatClock(h.time), style: const TextStyle(fontWeight: FontWeight.w800))),
              Icon(weatherIcon(h.weatherCode), size: 27),
              const SizedBox(width: 10),
              Expanded(child: Text(weatherTitle(h.weatherCode), style: TextStyle(color: Colors.white.withOpacity(.75)))),
              const Icon(Icons.water_drop_rounded, size: 13, color: Color(0xFFC6EDFF)),
              Text('${faDigits(h.precipitationProbability)}٪', style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 12),
              Text(formatTemp(h.temperature), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            ]),
          ).animate().fadeIn(delay: (i * 20).ms).slideX(begin: .04, end: 0);
        },
      );
}

class _WeeklyTab extends StatelessWidget {
  const _WeeklyTab({super.key, required this.snapshot});
  final WeatherSnapshot snapshot;
  @override
  Widget build(BuildContext context) => ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
        itemCount: snapshot.daily.length,
        separatorBuilder: (_, __) => const SizedBox(height: 9),
        itemBuilder: (context, i) {
          final d = snapshot.daily[i];
          return GlassCard(
            radius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(children: [
              SizedBox(width: 76, child: Text(i == 0 ? 'امروز' : shortWeekday(d.date), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
              Icon(weatherIcon(d.weatherCode), size: 30),
              const SizedBox(width: 10),
              Expanded(child: Text(weatherTitle(d.weatherCode), style: TextStyle(color: Colors.white.withOpacity(.74)))),
              const Icon(Icons.water_drop_rounded, size: 13, color: Color(0xFFC6EDFF)),
              Text('${faDigits(d.precipitationProbability)}٪', style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 12),
              Text(formatTemp(d.minTemperature), style: TextStyle(color: Colors.white.withOpacity(.6))),
              const SizedBox(width: 5),
              Text(formatTemp(d.maxTemperature), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            ]),
          ).animate().fadeIn(delay: (i * 45).ms).slideY(begin: .05, end: 0);
        },
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
      padding: EdgeInsets.fromLTRB(18, 3, 18, bottom > 10 ? bottom : 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D253D).withOpacity(.76),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: Colors.white.withOpacity(.12)),
        ),
        child: NavigationBar(
          height: 64,
          backgroundColor: Colors.transparent,
          indicatorColor: Colors.white.withOpacity(.14),
          selectedIndex: index,
          onDestinationSelected: changed,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), selectedIcon: Icon(Icons.wb_sunny_rounded), label: 'اکنون'),
            NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule_rounded), label: 'ساعتی'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'هفت‌روزه'),
          ],
        ),
      ),
    );
  }
}

class _ProblemView extends StatelessWidget {
  const _ProblemView({required this.problem, required this.error, required this.retry, required this.locationSettings, required this.appSettings});
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
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.location_searching_rounded, size: 58),
              const SizedBox(height: 16),
              const Text('موقعیت دقیق برای آب‌وهوای واقعی', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 9),
              Text(problem?.message ?? error ?? 'خطایی رخ داده است.', textAlign: TextAlign.center, style: TextStyle(height: 1.7, color: Colors.white.withOpacity(.75))),
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
            ]),
          ),
        ),
      );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.location_searching_rounded, size: 54)
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 1600.ms),
          const SizedBox(height: 17),
          const Text('در حال یافتن موقعیت دقیق شما…', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('GPS و اینترنت روشن باشد', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(.65))),
        ]),
      );
}
