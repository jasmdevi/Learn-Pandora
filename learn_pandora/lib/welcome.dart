import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:learn_pandora/daily.dart';

class AvatarLoginPage extends StatefulWidget {
  const AvatarLoginPage({super.key});
  @override
  State<AvatarLoginPage> createState() => _AvatarLoginPageState();
}

class _AvatarLoginPageState extends State<AvatarLoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _rand = Random();

  // Lightweight particle field (fireflies)
  late final List<_Firefly> _flies = List.generate(
    36,
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
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // immersive; no AppBar so colors fill edge-to-edge
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
                    colors: [
                      const Color(0xFF081C2E),              // deep night blue
                      Color.lerp(const Color(0xFF0B3D5F),
                          const Color(0xFF1A2E5A), sin(t * 2 * pi) * .5 + .5)!,
                      const Color(0xFF1D0D3A),              // purple depth
                    ],
                    stops: const [0.1, 0.6, 1.0],
                  ),
                ),
              ),

              // Drifting fireflies
              CustomPaint(
                painter: _FireflyPainter(flies: _flies, t: t),
              ),

              // Soft fog/glow layers
              _glowBlob(const Offset(-120, -80), const Color(0xFF6CF0FF), 240),
              _glowBlob(const Offset(320, 680), const Color(0xFF7C4DFF), 260),
              _glowBlob(const Offset(-40, 760), const Color(0xFF59FFA0), 220),

              // Content card
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Spacer(),
                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Na'vi greeting + title
                            const Text(
                              "Kaltxì!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.0,
                                shadows: [
                                  Shadow(
                                      color: Color(0xAA6CF0FF),
                                      blurRadius: 14,
                                      offset: Offset(0, 0)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Welcome to Pandora",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white.withOpacity(.90),
                                letterSpacing: .6,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Learn Na’vi.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(.75),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Glowing CTA
                            _GlowButton(
                              text: "Zola’u nìprrte’  •  Let’s Begin",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WordOfTheDayPage(),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: Color(0xFF6CF0FF),
                                  shadows: [
                                    Shadow(
                                        color: Color(0x556CF0FF),
                                        blurRadius: 12),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
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

  // Soft glowing blob helper
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
}

/// Frosted-glass card with subtle border + glow
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
            color: const Color(0x33121B2C), // translucent ink
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

/// Neon/glow button with gradient and animated shadow
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
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final pulse = (sin(_c.value * 2 * pi) + 1) / 2;
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
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
            child: const Text(
              "Zola’u nìprrte’  •  Let’s Begin",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: .5,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Firefly {
  _Firefly({
    required this.x,
    required this.y,
    required this.r,
    required this.phase,
    required this.drift,
  });

  double x, y;     // normalized [0..1] positions
  double r;        // radius in px
  double phase;    // initial phase
  double drift;    // movement magnitude
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

      // Twinkle opacity between 0.25 and 1.0
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

void main() {
  runApp(const MaterialApp(home: AvatarLoginPage()));
}
