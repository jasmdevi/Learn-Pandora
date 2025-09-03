// home.dart
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:learn_pandora/daily.dart';

// TODO: update this path to wherever your WordOfTheDayPage lives.
//import 'word_of_the_day.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _rand = Random();

  // Fireflies
  late final List<_Firefly> _flies = List.generate(
    40,
    (_) => _Firefly(
      x: _rand.nextDouble(),
      y: _rand.nextDouble(),
      r: 2.0 + _rand.nextDouble() * 3.5,
      phase: _rand.nextDouble() * 2 * pi,
      drift: 0.002 + _rand.nextDouble() * 0.006,
    ),
  );

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 18))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _fetchWotDPreview() async {
    final uri = Uri.parse('https://reykunyu.lu/api/random?holpxay=1');
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    final List<dynamic> arr = json.decode(utf8.decode(res.bodyBytes));
    if (arr.isEmpty) throw Exception('Empty result');

    final Map<String, dynamic> w =
        (arr.first as Map).map((k, v) => MapEntry(k.toString(), v));

    // Na’vi headword (prefer new schema)
    String? navi;
    final wr = w['word_raw'];
    if (wr is Map) {
      navi = (wr['FN'] as String?) ??
          (wr['combined'] as String?) ??
          (wr['RN'] as String?);
    }
    navi ??= w["na'vi"] as String?;
    navi ??= w['FN'] as String?;
    navi ??= w['word'] as String?;

    // English translation
    String? en;
    final translations = w['translations'];
    if (translations is List && translations.isNotEmpty && translations.first is Map) {
      final Map first = translations.first as Map;
      en = (first['en'] as String?) ??
          (first.values.cast<String?>().firstWhere((e) => e != null, orElse: () => null));
    }
    if (en == null) {
      final st = w['short_translation'];
      if (st is String) en = st;
      if (st is Map) en = st['en'] as String?;
    }

    return {
      'navi': navi ?? 'Unknown',
      'en': en ?? 'No translation',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Pandora"),
      ),
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Bioluminescent sky
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.lerp(
                      Alignment.topLeft,
                      Alignment.bottomRight,
                      (sin(t * 2 * pi) + 1) / 2,
                    )!,
                    radius: 1.3,
                    colors: const [
                      Color(0xFF081C2E),
                      Color(0xFF0B3D5F),
                      Color(0xFF1D0D3A),
                    ],
                    stops: const [0.1, 0.6, 1.0],
                  ),
                ),
              ),
              // Fireflies
              CustomPaint(painter: _FireflyPainter(flies: _flies, t: t)),
              // Soft glows
              _glowBlob(const Offset(-120, -60), const Color(0xFF6CF0FF), 240),
              _glowBlob(const Offset(320, 680), const Color(0xFF7C4DFF), 260),
              _glowBlob(const Offset(-40, 760), const Color(0xFF59FFA0), 220),

              // Content
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 88, 16, 24),
                  child: Column(
                    children: [
                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              "Kaltxì!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.0,
                                shadows: [
                                  Shadow(
                                      color: Color(0xAA6CF0FF), blurRadius: 14),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Welcome back, explorer.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(.8),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Quick actions
                            Row(
                              children: [
                                Expanded(
                                  child: _NavTile(
                                    icon: Icons.auto_awesome,
                                    label: "Word of the Day",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const WordOfTheDayPage(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _NavTile(
                                    icon: Icons.menu_book_rounded,
                                    label: "Lessons",
                                    onTap: () => _comingSoon(context),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _NavTile(
                                    icon: Icons.quiz_rounded,
                                    label: "Quiz",
                                    onTap: () => _comingSoon(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // WotD preview card
                      _GlassCard(
                        child: FutureBuilder<Map<String, String>>(
                          future: _fetchWotDPreview(),
                          builder: (context, snap) {
                            final loading = snap.connectionState ==
                                ConnectionState.waiting;
                            final hasData =
                                snap.hasData && snap.data != null;

                            final navi = hasData
                                ? snap.data!['navi']!
                                : (loading ? "Loading…" : "Error");
                            final en = hasData
                                ? snap.data!['en']!
                                : (loading
                                    ? "Fetching translation…"
                                    : "Tap to try again");

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: Color(0xFF59FFA0)),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Word of the Day",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(.9),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      tooltip: "Refresh preview",
                                      onPressed: loading
                                          ? null
                                          : () => setState(() {}),
                                      icon: const Icon(Icons.refresh,
                                          color: Color(0xFF6CF0FF)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  navi,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                    shadows: [
                                      Shadow(
                                          color: Color(0xAA6CF0FF),
                                          blurRadius: 14),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  en,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFFE7FFE7),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _GlowButton(
                                  text: "Open Word of the Day",
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const WordOfTheDayPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Explore row
                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.travel_explore_rounded,
                                    color: Color(0xFF6CF0FF)),
                                const SizedBox(width: 8),
                                Text(
                                  "Explore",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _ChipButton(
                                  label: "Phrasebook",
                                  onTap: () => _comingSoon(context),
                                ),
                                _ChipButton(
                                  label: "Pronunciation",
                                  onTap: () => _comingSoon(context),
                                ),
                                _ChipButton(
                                  label: "Grammar",
                                  onTap: () => _comingSoon(context),
                                ),
                                _ChipButton(
                                  label: "Favorites",
                                  onTap: () => _comingSoon(context),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _glowBlob(Offset offset, Color color, double size) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withOpacity(.25),
                color.withOpacity(.05),
                Colors.transparent
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Coming soon ✨")),
    );
  }
}

/* ------------------- Shared visual pieces ------------------- */

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(.18)),
            color: const Color(0x33121B2C),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3300FFFF),
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlowButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const _GlowButton({required this.text, required this.onTap});

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulse = (sin(_c.value * 2 * pi) + 1) / 2;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Color.lerp(const Color(0xFF6CF0FF), const Color(0xFF59FFA0), .4)!,
            Color.lerp(const Color(0xFF7C4DFF), const Color(0xFF6CF0FF), .6)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6CF0FF).withOpacity(.45 + .25 * pulse),
            blurRadius: 24 + 12 * pulse,
            spreadRadius: 1 + 1 * pulse,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                "Open Word of the Day",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: .5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0x33121B2C),
              border: Border.all(color: Colors.white.withOpacity(.14)),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFF6CF0FF)),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ChipButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(.18)),
          color: const Color(0x22121B2C),
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
      ),
    );
  }
}

/* ---------------- Fireflies ---------------- */

class _Firefly {
  _Firefly(
      {required this.x,
      required this.y,
      required this.r,
      required this.phase,
      required this.drift});
  double x, y; // normalized [0..1]
  double r;
  double phase;
  double drift;
}

class _FireflyPainter extends CustomPainter {
  final List<_Firefly> flies;
  final double t; // 0..1
  _FireflyPainter({required this.flies, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final time = t * 2 * pi;
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    for (final f in flies) {
      final dx = sin(time + f.phase) * f.drift * size.width;
      final dy = cos(time * 0.8 + f.phase) * f.drift * size.height;
      final x = f.x * size.width + dx;
      final y = f.y * size.height + dy;
      final twinkle = (sin(time * 1.3 + f.phase) + 1) / 2 * 0.75 + 0.25;

      paint.color = Color.lerp(const Color(0xFF6CF0FF), const Color(0xFF59FFA0),
              (sin(f.phase) + 1) / 2)!
          .withOpacity(twinkle);

      canvas.drawCircle(Offset(x, y), f.r + 1.5 * twinkle, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FireflyPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.flies != flies;
}
