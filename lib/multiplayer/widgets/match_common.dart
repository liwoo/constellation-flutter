import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:constellation_app/multiplayer/models/match_models.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/services/services.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// Each seat at the table gets its own colour
const _seatColors = [
  AppColors.accentCyan,
  AppColors.accentPink,
  AppColors.accentGold,
  AppColors.accentPurple,
  AppColors.accentOrange,
  Color(0xFF69F0AE),
];

/// A player's colour: by seat, so it's the same on every screen
Color seatColor(MatchRoom room, String uid) {
  final seat = room.roster.indexWhere((p) => p.uid == uid);
  return _seatColors[(seat < 0 ? 0 : seat) % _seatColors.length];
}

/// What friends need to join: the code, and on web a link straight in
String inviteMessage(String code) {
  final buffer = StringBuffer('Join my Constellation game! Room code: $code');
  if (kIsWeb) {
    final base = Uri.base;
    buffer.write('\n${base.origin}${base.path}#/multiplayer/$code');
  }
  return buffer.toString();
}

/// Round initial in the player's colour; dimmed while they're away
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.player,
    required this.color,
    this.size = 36,
    this.badge,
  });

  final MatchPlayer player;
  final Color color;
  final double size;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final initial = player.name.isEmpty ? '?' : player.name.characters.first.toUpperCase();
    return Opacity(
      opacity: player.online ? 1 : 0.4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color, color.withAlpha(150)]),
              border: Border.all(color: AppColors.white.withAlpha(200), width: 2),
              boxShadow: [BoxShadow(color: color.withAlpha(110), blurRadius: 10)],
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: GoogleFonts.orbitron(
                color: AppColors.black,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (badge != null) Positioned(right: -6, top: -6, child: badge!),
        ],
      ),
    );
  }
}

/// Frosted panel the multiplayer screens are built from
class MatchPanel extends StatelessWidget {
  const MatchPanel({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpacing.md)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryDarkPurple.withAlpha(200),
            AppColors.primaryNavy.withAlpha(200),
          ],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: Border.all(color: AppColors.accentGold.withAlpha(90), width: 1.5),
      ),
      child: child,
    );
  }
}

/// Screen heading in the game's display face
class MatchHeading extends StatelessWidget {
  const MatchHeading(this.text, {super.key, this.size = 22, this.color = AppColors.white});

  final String text;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.orbitron(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }
}

/// Small round icon button, as in the game's top bar
class MatchIconButton extends StatelessWidget {
  const MatchIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AudioService.instance.play(GameSound.buttonTap);
        HapticService.instance.selection();
        onTap();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryDarkPurple.withAlpha(200),
          border: Border.all(color: AppColors.white.withAlpha(80), width: 1.5),
        ),
        child: Icon(icon, color: AppColors.white, size: 20),
      ),
    );
  }
}

/// Ask before walking away from a match
Future<bool> confirmLeaveMatch(BuildContext context, {required bool midMatch}) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.primaryDarkPurple,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.accentGold.withAlpha(100)),
      ),
      title: Text('Leave game?', style: GoogleFonts.orbitron(color: AppColors.white)),
      content: Text(
        midMatch
            ? 'The match carries on without you. Rejoin with the room code to pick up where you left off.'
            : 'You\'ll give up your seat in the lobby.',
        style: GoogleFonts.exo2(color: AppColors.white.withAlpha(200)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('STAY', style: GoogleFonts.exo2(color: AppColors.white.withAlpha(150))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('LEAVE', style: GoogleFonts.exo2(color: AppColors.accentOrange)),
        ),
      ],
    ),
  );
  return leave ?? false;
}

/// What the host chose to do from the in-match exit menu
enum MatchExit { stay, leaveSeat, endGame }

/// The host's exit menu mid-match: end the game for everyone (jump to the
/// final scores), just leave their own seat, or stay
Future<MatchExit> chooseMatchExit(BuildContext context) async {
  final choice = await showDialog<MatchExit>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.primaryDarkPurple,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.accentGold.withAlpha(100)),
      ),
      title: Text('Leave game?', style: GoogleFonts.orbitron(color: AppColors.white)),
      content: Text(
        "You're the host. End the game for everyone and jump to the final scores, "
        'or just leave your own seat and let the match carry on.',
        style: GoogleFonts.exo2(color: AppColors.white.withAlpha(200)),
      ),
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, MatchExit.stay),
          child: Text('STAY', style: GoogleFonts.exo2(color: AppColors.white.withAlpha(150))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, MatchExit.leaveSeat),
          child: Text('LEAVE SEAT', style: GoogleFonts.exo2(color: AppColors.white.withAlpha(200))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, MatchExit.endGame),
          child: Text('END GAME', style: GoogleFonts.exo2(color: AppColors.accentOrange, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
  return choice ?? MatchExit.stay;
}

/// Body text for the multiplayer screens
TextStyle matchBodyStyle({double size = 14, Color? color, FontWeight? weight}) => GoogleFonts.exo2(
      color: color ?? AppColors.white.withAlpha(210),
      fontSize: size,
      fontWeight: weight,
    );
