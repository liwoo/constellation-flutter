import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:constellation_app/shared/services/services.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';

/// Dismissable modal with a looping demo of how to connect letters.
/// Shown before a game starts until the player opts out.
class HowToConnectDialog extends StatefulWidget {
  const HowToConnectDialog({super.key});

  static const _hidePrefKey = 'hide_how_to_connect';

  /// Show the modal unless the player ticked "don't show again"
  static Future<void> showIfWanted(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_hidePrefKey) ?? false) return;
    if (!context.mounted) return;
    final hide = await showDialog<bool>(
      context: context,
      builder: (_) => const HowToConnectDialog(),
    );
    if (hide ?? false) await prefs.setBool(_hidePrefKey, true);
  }

  @override
  State<HowToConnectDialog> createState() => _HowToConnectDialogState();
}

class _HowToConnectDialogState extends State<HowToConnectDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryPurple.withAlpha(250),
              AppColors.primaryDarkPurple.withAlpha(250),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.accentGold, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGold.withAlpha(80),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HOW TO CONNECT',
              style: GoogleFonts.orbitron(
                color: AppColors.accentGold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            const ConnectDemo(),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Checkbox(
                    value: _dontShowAgain,
                    onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
                    activeColor: AppColors.accentGold,
                    checkColor: AppColors.black,
                    side: BorderSide(color: Colors.white.withAlpha(150)),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
                    child: Text(
                      "Don't show this again",
                      style: GoogleFonts.exo2(
                        color: Colors.white.withAlpha(170),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    AudioService.instance.play(GameSound.buttonTap);
                    Navigator.of(context).pop(_dontShowAgain);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentGold, AppColors.accentOrange],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      'GOT IT',
                      style: GoogleFonts.orbitron(
                        color: AppColors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Looping animation of the connect gesture on a tiny three-star board:
/// touch C, slide to A and hold until the ring fills and clicks, same for
/// T, then tap GO.
class ConnectDemo extends StatefulWidget {
  const ConnectDemo({super.key});

  @override
  State<ConnectDemo> createState() => _ConnectDemoState();
}

class _ConnectDemoState extends State<ConnectDemo>
    with SingleTickerProviderStateMixin {
  static const _loopMs = 5600.0;

  // Timeline (ms): each "click" lands one full dwell after arriving
  static const _touchC = 400.0;
  static const _arriveA = 900.0;
  static const _clickA = _arriveA + 1000; // dwell = 1s, as in the game
  static const _arriveT = 2400.0;
  static const _clickT = _arriveT + 1000;
  static const _arriveGo = 3900.0;
  static const _tapGo = 4100.0;

  static const _size = Size(280, 250);
  static const _starSize = 48.0;
  static const _c = Offset(48, 120);
  static const _a = Offset(140, 48);
  static const _t = Offset(232, 120);
  static const _go = Offset(236, 214);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5600),
  )..addListener(_playCues)..repeat();

  double _lastMs = 0;

  double get _ms => _controller.value * _loopMs;

  /// Click sounds land with the visuals - "wait for the click"
  void _playCues() {
    final ms = _ms;
    bool crossed(double t) => _lastMs < t && ms >= t;
    if (crossed(_touchC)) AudioService.instance.playSnap(1, volume: 0.5);
    if (crossed(_clickA)) AudioService.instance.playSnap(2, volume: 0.5);
    if (crossed(_clickT)) AudioService.instance.playSnap(3, volume: 0.5);
    if (crossed(_tapGo)) AudioService.instance.play(GameSound.buttonTap);
    _lastMs = ms;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Fingertip position along the scripted path
  Offset _finger(double ms) {
    Offset lerp(Offset a, Offset b, double from, double to) => Offset.lerp(
          a,
          b,
          Curves.easeInOut.transform(((ms - from) / (to - from)).clamp(0.0, 1.0)),
        )!;
    if (ms < _clickA) return lerp(_c, _a, _touchC + 100, _arriveA);
    if (ms < _clickT) return lerp(_a, _t, _clickA + 100, _arriveT);
    return lerp(_t, _go, _clickT + 100, _arriveGo);
  }

  String _caption(double ms) {
    if (ms < _arriveA) return 'Touch the first letter';
    if (ms < _clickT) return 'Slide to the next star and HOLD\nuntil the ring fills and it clicks';
    if (ms < _arriveGo) return 'Lift your finger - letters stay connected';
    return 'Tap GO to submit';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final ms = _ms;
        final fingerDown = ms >= _touchC && ms < _clickT + 150;
        final finger = _finger(ms);
        final selected = [
          if (ms >= _touchC) 'C',
          if (ms >= _clickA) 'A',
          if (ms >= _clickT) 'T',
        ];
        final submitted = ms >= _tapGo;
        // Whole demo fades out at the end of the loop
        final opacity = ms < 200
            ? ms / 200
            : ms > _loopMs - 300
                ? (_loopMs - ms) / 300
                : 1.0;

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.fromSize(
                size: _size,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Connection line, trailing the finger while it's down
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DemoLinePainter(
                          points: [
                            if (selected.contains('C')) _c,
                            if (selected.contains('A')) _a,
                            if (selected.contains('T')) _t,
                          ],
                          finger: fingerDown ? finger : null,
                        ),
                      ),
                    ),
                    _star('C', _c, ms, selected, arrive: 0, click: _touchC),
                    _star('A', _a, ms, selected, arrive: _arriveA, click: _clickA),
                    _star('T', _t, ms, selected, arrive: _arriveT, click: _clickT),
                    // Word so far
                    Positioned(
                      left: 0,
                      top: 194,
                      child: Row(
                        children: [
                          for (final l in selected) _chip(l, submitted),
                          if (submitted) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 22),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      left: _go.dx - 20,
                      top: _go.dy - 20,
                      child: AnimatedScale(
                        scale: ms >= _tapGo && ms < _tapGo + 180 ? 0.85 : 1.0,
                        duration: const Duration(milliseconds: 90),
                        child: AttentionPulse(
                          active: ms >= _clickT && ms < _tapGo,
                          color: const Color(0xFF4CAF50),
                          child: ActionBubble(
                            label: 'GO',
                            isSubmit: true,
                            isActive: selected.length == 3,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    if (ms >= _touchC - 250 && ms < _tapGo + 500) _fingerIcon(finger, fingerDown || (ms >= _tapGo && ms < _tapGo + 180)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: Text(
                  _caption(ms),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.exo2(
                    color: Colors.white.withAlpha(225),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _star(
    String letter,
    Offset center,
    double ms,
    List<String> selected, {
    required double arrive,
    required double click,
  }) {
    return Positioned(
      left: center.dx - _starSize / 2,
      top: center.dy - _starSize / 2,
      child: LetterBubble(
        letter: letter,
        points: 1,
        isSelected: selected.contains(letter),
        // Ring fills while the finger rests here, exactly as in the game
        isApproaching: ms >= arrive && ms < click && letter != 'C',
        justConnected: ms >= click && ms < click + 300,
        size: _starSize,
      ),
    );
  }

  Widget _chip(String letter, bool submitted) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: submitted ? const Color(0xFF4CAF50) : Colors.white,
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: submitted ? Colors.white : AppColors.black,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _fingerIcon(Offset tip, bool pressed) {
    return Positioned(
      // Fingertip rests just below-right of centre so the letter stays visible
      left: tip.dx - 4,
      top: tip.dy + 8,
      child: IgnorePointer(
        child: AnimatedScale(
          scale: pressed ? 0.9 : 1.05,
          duration: const Duration(milliseconds: 120),
          child: Icon(
            Icons.touch_app_rounded,
            size: 40,
            color: Colors.white,
            shadows: [Shadow(color: AppColors.black.withAlpha(170), blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}

class _DemoLinePainter extends CustomPainter {
  _DemoLinePainter({required this.points, required this.finger});

  final List<Offset> points;
  final Offset? finger;

  @override
  void paint(Canvas canvas, Size size) {
    final all = [...points, ?finger];
    if (all.length < 2) return;
    final path = Path()..moveTo(all.first.dx, all.first.dy);
    for (final p in all.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.accentGold.withAlpha(90)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.accentGold,
    );
  }

  @override
  bool shouldRepaint(_DemoLinePainter old) => true;
}
