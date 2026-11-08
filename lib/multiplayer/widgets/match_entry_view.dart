import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:constellation_app/multiplayer/cubit/multiplayer_cubit.dart';
import 'package:constellation_app/multiplayer/widgets/match_common.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';

/// Pick a name, then open a game or join a friend's with their code
class MatchEntryView extends StatefulWidget {
  const MatchEntryView({super.key});

  @override
  State<MatchEntryView> createState() => _MatchEntryViewState();
}

class _MatchEntryViewState extends State<MatchEntryView> {
  late final MultiplayerCubit _cubit = context.read<MultiplayerCubit>();
  late final _name = TextEditingController(text: _cubit.state.name);
  late final _code = TextEditingController(text: _cubit.state.pendingCode ?? '');

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MultiplayerCubit, MultiplayerState>(
      // The saved name loads after the first frame
      listenWhen: (previous, current) =>
          previous.name != current.name || previous.pendingCode != current.pendingCode,
      listener: (context, state) {
        if (_name.text.isEmpty) _name.text = state.name;
        if (_code.text.isEmpty && state.pendingCode != null) _code.text = state.pendingCode!;
      },
      builder: (context, state) {
        final busy = state.connection == MultiplayerConnection.connecting;
        final invited = state.pendingCode != null;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  MatchIconButton(icon: Icons.arrow_back, onTap: () => context.go('/')),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    children: [
                      const MatchHeading('MULTIPLAYER', size: 26, color: AppColors.accentGold),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Race your friends through ${MultiplayerConfig.rounds} rounds on the same stars',
                        textAlign: TextAlign.center,
                        style: matchBodyStyle(size: 14),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      MatchPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _label('YOUR NAME'),
                            const SizedBox(height: AppSpacing.xs),
                            _field(
                              controller: _name,
                              hint: 'Star gazer',
                              maxLength: MultiplayerConfig.maxNameLength,
                              enabled: !busy,
                              capitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            if (!invited) ...[
                              GameButton(
                                text: 'CREATE GAME',
                                onPressed: busy ? null : () => _cubit.createRoom(_name.text),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: AppColors.white.withAlpha(60))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                    child: Text('OR JOIN A FRIEND', style: matchBodyStyle(size: 11)),
                                  ),
                                  Expanded(child: Divider(color: AppColors.white.withAlpha(60))),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ] else ...[
                              Text(
                                'You\'ve been invited to a game',
                                textAlign: TextAlign.center,
                                style: matchBodyStyle(size: 14, color: AppColors.accentGold),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            _label('ROOM CODE'),
                            const SizedBox(height: AppSpacing.xs),
                            _field(
                              controller: _code,
                              hint: 'ABCDE',
                              maxLength: MultiplayerConfig.codeLength,
                              enabled: !busy,
                              code: true,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            GameButton(
                              text: 'JOIN',
                              isPrimary: invited,
                              onPressed: busy ? null : () => _cubit.joinRoom(_code.text, _name.text),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (busy)
                        const CircularProgressIndicator(color: AppColors.accentGold)
                      else if (state.error != null)
                        Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: matchBodyStyle(size: 14, color: AppColors.accentPink, weight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.exo2(
          color: AppColors.white.withAlpha(160),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required int maxLength,
    required bool enabled,
    bool code = false,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLength: maxLength,
      textAlign: code ? TextAlign.center : TextAlign.start,
      textCapitalization: code ? TextCapitalization.characters : capitalization,
      inputFormatters: [
        if (code) ...[
          FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
          TextInputFormatter.withFunction(
            (oldValue, newValue) => newValue.copyWith(text: newValue.text.toUpperCase()),
          ),
        ],
      ],
      onChanged: (_) => _cubit.clearError(),
      style: code
          ? GoogleFonts.orbitron(color: AppColors.white, fontSize: 22, letterSpacing: 6)
          : GoogleFonts.exo2(color: AppColors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.white.withAlpha(70)),
        counterText: '',
        filled: true,
        fillColor: AppColors.black.withAlpha(70),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: BorderSide(color: AppColors.white.withAlpha(60)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: BorderSide(color: AppColors.white.withAlpha(60)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: const BorderSide(color: AppColors.accentGold, width: 2),
        ),
      ),
    );
  }
}
