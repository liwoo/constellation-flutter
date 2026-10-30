import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/services/services.dart';
import 'package:constellation_app/shared/theme/theme.dart';

const _heartColor = Color(0xFFFF4D6D);

/// Time's up: spend a life to replay the letter round, or - with none left
/// - watch an ad or buy more. Giving up goes on to the final score.
class OutOfTimeOverlay extends StatelessWidget {
  const OutOfTimeOverlay({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GameCubit>();
    final hasLife = state.lives > 0;
    final letter = state.currentLetter ?? '?';
    final canContinueWithStars = state.stars >= StarConfig.continueCost;

    return Container(
      color: AppColors.black.withAlpha(200),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(28),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryPurple.withAlpha(240),
                  AppColors.primaryDarkPurple.withAlpha(240),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.accentPink, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPink.withAlpha(100),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "TIME'S UP!",
                  style: GoogleFonts.orbitron(
                    color: AppColors.accentPink,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 16),
                LivesHearts(lives: state.lives, size: 34),
                const SizedBox(height: 12),
                Text(
                  hasLife
                      ? 'Use a life to replay letter $letter\nfrom the start with ${cubit.replayTime}s'
                      : "You're out of lives!\nWatch an ad or grab more to keep going",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.exo2(
                    color: Colors.white.withAlpha(220),
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 22),
                if (hasLife)
                  _PrimaryButton(
                    icon: Icons.favorite,
                    label: 'USE A LIFE',
                    colors: const [_heartColor, AppColors.accentPink],
                    onTap: cubit.useLife,
                  )
                else ...[
                  _PrimaryButton(
                    icon: Icons.play_circle_fill_rounded,
                    label: 'WATCH AD  +${LivesConfig.adReward}',
                    trailing: Icons.favorite,
                    colors: const [
                      AppColors.accentGold,
                      AppColors.accentOrange,
                    ],
                    dark: true,
                    onTap: () async {
                      final watched = await showRewardedAd(context);
                      if (watched) {
                        cubit.addLives(LivesConfig.adReward, source: 'ad');
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _SecondaryButton(
                    icon: Icons.shopping_bag_rounded,
                    label: 'GET MORE LIVES',
                    onTap: () => showLivesShop(context),
                  ),
                ],
                if (canContinueWithStars) ...[
                  const SizedBox(height: 12),
                  _SecondaryButton(
                    icon: Icons.star,
                    iconColor: AppColors.accentGold,
                    label: 'KEEP GOING +60s (${StarConfig.continueCost}★)',
                    onTap: cubit.continueWithStars,
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: cubit.giveUp,
                  child: Text(
                    'Give up',
                    style: GoogleFonts.exo2(
                      color: Colors.white.withAlpha(150),
                      fontSize: 14,
                    ),
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

/// Row of hearts: filled for lives held, outlined up to the starting count.
/// More than five collapses to one heart and a count.
class LivesHearts extends StatelessWidget {
  const LivesHearts({super.key, required this.lives, this.size = 14});

  final int lives;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (lives > 5) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, color: _heartColor, size: size),
          const SizedBox(width: 3),
          Text(
            'x$lives',
            style: GoogleFonts.exo2(
              color: _heartColor,
              fontSize: size * 0.75,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
    final slots = lives > LivesConfig.startingLives
        ? lives
        : LivesConfig.startingLives;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < slots; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.06),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                i < lives ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(i < lives),
                color: i < lives ? _heartColor : Colors.white.withAlpha(90),
                size: size,
              ),
            ),
          ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
    this.trailing,
    this.dark = false,
  });

  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;
  final IconData? trailing;
  final bool dark; // Dark text on a light button

  @override
  Widget build(BuildContext context) {
    final fg = dark ? AppColors.black : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: colors.first.withAlpha(120),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        // Shrinks rather than overflowing on narrow phones
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg, size: 24),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.orbitron(
                  color: fg,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                Icon(trailing, color: dark ? _heartColor : fg, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withAlpha(150), width: 2),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor ?? Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.orbitron(
                  color: Colors.white.withAlpha(220),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// SIMULATED REWARDED AD
// ============================================

/// Show a rewarded ad. Returns true if it was watched to the end.
///
/// SIMULATED: a full-screen placeholder with a countdown stands in for a
/// real ad network (e.g. google_mobile_ads' RewardedAd).
Future<bool> showRewardedAd(BuildContext context) async {
  final watched = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black,
    pageBuilder: (_, _, _) => const _SimulatedAd(),
  );
  return watched ?? false;
}

class _SimulatedAd extends StatefulWidget {
  const _SimulatedAd();

  @override
  State<_SimulatedAd> createState() => _SimulatedAdState();
}

class _SimulatedAdState extends State<_SimulatedAd> {
  int _left = LivesConfig.adSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        AudioService.instance.play(GameSound.mysteryReward);
        HapticService.instance.success();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _left <= 0;
    return PopScope(
      canPop: false, // The reward only comes at the end
      child: Material(
        color: const Color(0xFF101018),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF3A1C71),
                            Color(0xFFD76D77),
                            Color(0xFFFFAF7B),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: Colors.white,
                        size: 96,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      done ? 'REWARD EARNED!' : 'Your ad here',
                      style: GoogleFonts.orbitron(
                        color: done ? AppColors.accentGold : Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      done
                          ? '+${LivesConfig.adReward} life'
                          : 'Simulated ad - reward in $_left s',
                      style: GoogleFonts.exo2(
                        color: Colors.white.withAlpha(180),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 28),
                    AnimatedOpacity(
                      opacity: done ? 1 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: GestureDetector(
                        onTap: done
                            ? () => Navigator.of(context).pop(true)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_heartColor, AppColors.accentPink],
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'COLLECT',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // "Ad" tag + countdown, as on real rewarded ads
              Positioned(
                top: 12,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'AD',
                    style: TextStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 16,
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: 1 - _left / LivesConfig.adSeconds,
                        strokeWidth: 3,
                        color: Colors.white,
                        backgroundColor: Colors.white.withAlpha(40),
                      ),
                      Text(
                        done ? '✓' : '$_left',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// LIVES SHOP
// ============================================

/// Bottom sheet selling lives packs. Purchases go through [StoreService]
/// (simulated for now) and land straight in the current run.
Future<void> showLivesShop(BuildContext context) {
  final cubit = context.read<GameCubit>();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(value: cubit, child: const _LivesShop()),
  );
}

class _LivesShop extends StatefulWidget {
  const _LivesShop();

  @override
  State<_LivesShop> createState() => _LivesShopState();
}

class _LivesShopState extends State<_LivesShop> {
  String? _buying; // Pack id being purchased

  Future<void> _buy(LifePack pack) async {
    if (_buying != null) return;
    setState(() => _buying = pack.id);
    final cubit = context.read<GameCubit>();
    final navigator = Navigator.of(context);
    final ok = await StoreService.instance.buy(pack);
    if (!mounted) return;
    if (ok) {
      cubit.addLives(pack.lives, source: pack.id);
      AudioService.instance.play(GameSound.mysteryReward);
      HapticService.instance.success();
      navigator.pop();
    } else {
      setState(() => _buying = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryPurple, AppColors.primaryDarkPurple],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'MORE LIVES',
              style: GoogleFonts.orbitron(
                color: AppColors.accentGold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            for (final pack in StoreService.lifePacks) ...[
              _packTile(pack),
              const SizedBox(height: 10),
            ],
            if (StoreService.isSimulated)
              Text(
                'Test mode - purchases are simulated, nothing is charged',
                style: GoogleFonts.exo2(
                  color: Colors.white.withAlpha(130),
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _packTile(LifePack pack) {
    final busy = _buying == pack.id;
    return GestureDetector(
      onTap: () => _buy(pack),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: pack.tag != null
                ? AppColors.accentGold
                : Colors.white.withAlpha(60),
            width: pack.tag != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.favorite, color: _heartColor, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pack.lives} LIVES',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (pack.tag != null)
                    Text(
                      pack.tag!,
                      style: GoogleFonts.exo2(
                        color: AppColors.accentGold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 84,
              padding: const EdgeInsets.symmetric(vertical: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      pack.price,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
