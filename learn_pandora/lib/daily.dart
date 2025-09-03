import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:learn_pandora/home.dart'; // adjust path if needed

void main() => runApp(const MaterialApp(home: WordOfTheDayPage()));

class WordOfTheDayPage extends StatefulWidget {
  const WordOfTheDayPage({super.key});
  @override
  State<WordOfTheDayPage> createState() => _WordOfTheDayPageState();
}

class _WordOfTheDayPageState extends State<WordOfTheDayPage>
    with SingleTickerProviderStateMixin {
  String wordOfTheDay = "Loading…";
  String translation = "Loading…";
  bool isLoading = false;

  late final AnimationController _ctrl;
  final _rand = Random();
  late final List<_Firefly> _flies = List.generate(
    38,
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
    fetchWordOfTheDay();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> fetchWordOfTheDay() async {
    setState(() => isLoading = true);
    try {
      final uri = Uri.parse('https://reykunyu.lu/api/random?holpxay=1');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

      final List<dynamic> arr = json.decode(utf8.decode(res.bodyBytes));
      if (arr.isEmpty) throw Exception('Empty result');

      final Map<String, dynamic> w = (arr.first as Map).map((k, v) => MapEntry(k.toString(), v));

      // Headword (prefer new schema)
      String? navi;
      final wr = w['word_raw'];
      if (wr is Map) navi = (wr['FN'] as String?) ?? (wr['combined'] as String?) ?? (wr['RN'] as String?);
      navi ??= w["na'vi"] as String?;
      navi ??= w['FN'] as String?;
      navi ??= w['word'] as String?;

      // English gloss
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

      setState(() {
        wordOfTheDay = navi ?? "Unknown";
        translation = en ?? "No translation available";
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        wordOfTheDay = "Error fetching word";
        translation = "Please check your internet connection.";
        isLoading = false;
      });
    }
  }

  void _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied to clipboard")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent app bar to keep the immersive background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Na’vi • Word of the Day"),
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Bioluminescent night gradient
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.lerp(
                      Alignment.topLeft, Alignment.bottomRight, (sin(t * 2 * pi) + 1) / 2,
                    )!,
                    radius: 1.3,
                    colors: [
                      const Color(0xFF081C2E),
                      Color.lerp(const Color(0xFF0B3D5F), const Color(0xFF1A2E5A), sin(t * 2 * pi) * .5 + .5)!,
                      const Color(0xFF1D0D3A),
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

              // Content card
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 88, 16, 20),
                  child: _GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Tìfwew lì’u trr-am",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            letterSpacing: .8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Word
                        Row(
                          children: [
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: SelectableText(
                                  key: ValueKey(wordOfTheDay),
                                  wordOfTheDay,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                    shadows: [
                                      Shadow(color: Color(0xAA6CF0FF), blurRadius: 14),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: "Copy word",
                              onPressed: () => _copy(wordOfTheDay),
                              icon: const Icon(Icons.copy, color: Color(0xFF6CF0FF)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Divider glow
                        Container(
                          height: 1.2,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(.35),
                              Colors.transparent
                            ]),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Translation
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF59FFA0)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: SelectableText(
                                  key: ValueKey(translation),
                                  translation,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Color(0xFFE7FFE7),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: "Copy translation",
                              onPressed: () => _copy(translation),
                              icon: const Icon(Icons.copy, color: Color(0xFF59FFA0)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // Refresh
                        _GlowButton(
                          text: isLoading ? "Refreshing…" : "New Word",
                          onTap: isLoading ? null : fetchWordOfTheDay,
                          busy: isLoading,
                        ),
                        const SizedBox(height: 12),
_GlowButton(
  text: "Zola’u nìprrte’  •  Let’s Begin",
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  },
),

                      ],
                    ),
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
              colors: [color.withOpacity(.25), color.withOpacity(.05), Colors.transparent],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------- Visual components (shared with your welcome page style) ---------- */

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
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(.18)),
            color: const Color(0x33121B2C),
            boxShadow: const [
              BoxShadow(color: Color(0x3300FFFF), blurRadius: 22, spreadRadius: 2),
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
  final VoidCallback? onTap;
  final bool busy;
  const _GlowButton({required this.text, required this.onTap, this.busy = false});

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final pulse = (sin(_c.value * 2 * pi) + 1) / 2;
        return GestureDetector(
          onTap: widget.busy ? null : widget.onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
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
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.busy)
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  ),
                if (widget.busy) const SizedBox(width: 10),
                Text(
                  widget.text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/* ----------------------- Firefly particle system ----------------------- */

class _Firefly {
  _Firefly({required this.x, required this.y, required this.r, required this.phase, required this.drift});
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
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

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
