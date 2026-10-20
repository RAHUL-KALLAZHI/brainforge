import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/core/widgets/app_button.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/logic/adaptive_difficulty_service.dart';
import '../logic/focus_hunter_cubit.dart';
import '../logic/focus_hunter_state.dart';
import 'widgets/focus_hunter_board.dart';
import 'widgets/focus_hunter_header.dart';
import 'widgets/focus_hunter_ready_view.dart';
import 'widgets/focus_hunter_result_view.dart';
import 'widgets/focus_hunter_target_bar.dart';

/// Top-level playable screen for the Focus Hunter mini-game.
class FocusHunterScreen extends StatelessWidget {
  final FocusHunterCubit? cubit;
  final GameDifficulty? initialDifficulty;
  final int? initialSeed;
  final GameAttemptRepository? attemptRepository;
  final AdaptiveDifficultyService? adaptiveService;

  const FocusHunterScreen({
    super.key,
    this.cubit,
    this.initialDifficulty,
    this.initialSeed,
    this.attemptRepository,
    this.adaptiveService,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<FocusHunterCubit>.value(
        value: cubit!,
        child: const _FocusHunterContent(),
      );
    }

    return BlocProvider<FocusHunterCubit>(
      create: (context) => FocusHunterCubit(
        initialDifficulty: initialDifficulty,
        initialSeed: initialSeed,
        attemptRepository: attemptRepository,
        adaptiveService: adaptiveService,
      ),
      child: const _FocusHunterContent(),
    );
  }
}

class _FocusHunterContent extends StatelessWidget {
  const _FocusHunterContent();

  Future<void> _handleExit(BuildContext context, FocusHunterCubit cubit) async {
    final status = cubit.state.sessionState.status;

    // During active gameplay, confirm before abandoning
    if (status == GameStatus.playing ||
        status == GameStatus.countdown ||
        status == GameStatus.paused) {
      cubit.pause();
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final customTheme = dialogContext.brainForgeTheme;
          return AlertDialog(
            backgroundColor: customTheme.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.roundedXl,
              side: BorderSide(color: customTheme.cardBorder),
            ),
            title: const Text('Exit Focus Hunter?'),
            content: const Text(
              'Your active attempt will be abandoned and no completion score will be recorded.',
            ),
            actions: [
              TextButton(
                key: const Key('dialog_cancel_exit_button'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Resume'),
              ),
              AppButton(
                key: const Key('dialog_confirm_exit_button'),
                label: 'Exit',
                variant: AppButtonVariant.primary,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          );
        },
      );

      if (shouldExit == true) {
        cubit.abandonGame();
        if (context.mounted) {
          context.pop();
        }
      } else {
        cubit.resume();
      }
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final customTheme = context.brainForgeTheme;
    final cubit = context.read<FocusHunterCubit>();
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return BlocBuilder<FocusHunterCubit, FocusHunterState>(
      builder: (context, state) {
        final status = state.sessionState.status;
        final isPlayingActive = status == GameStatus.playing ||
            status == GameStatus.countdown ||
            status == GameStatus.paused;

        return PopScope(
          canPop: !isPlayingActive,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              _handleExit(context, cubit);
            }
          },
          child: Scaffold(
            backgroundColor: scaffoldBg,
            body: SafeArea(
              child: Builder(
                builder: (context) {
                  // 1. Initial Readiness / Instructions Screen
                  if (status == GameStatus.initial) {
                    return FocusHunterReadyView(
                      state: state,
                      onDifficultyChanged: (newDiff) {
                        cubit.restart(difficulty: newDiff);
                      },
                      onStartPressed: () => cubit.startGame(),
                      onExitPressed: () => Navigator.of(context).maybePop(),
                    );
                  }

                  // 2. Terminal Result Screen (Completed, Failed, Abandoned)
                  if (status.isTerminal) {
                    return FocusHunterResultView(
                      state: state,
                      onProceedToNextLevelPressed: () =>
                          cubit.proceedToRecommendedLevel(),
                      onPlayAgainPressed: () =>
                          cubit.playAgainAtCompletedDifficulty(),
                      onReturnToGamePressed: () => cubit.returnToReadyView(),
                    );
                  }

                  // 3. Active Gameplay Screen (Countdown, Playing, Paused)
                  return Column(
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      FocusHunterHeader(
                        state: state,
                        onExitPressed: () => _handleExit(context, cubit),
                      ),
                      FocusHunterTargetBar(state: state),
                      Expanded(
                        child: FocusHunterBoard(
                          state: state,
                          onItemTapped: (index) => cubit.onItemTapped(index),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.sm,
                        ),
                        child: status == GameStatus.paused
                            ? AppButton(
                                label: 'Resume Game',
                                icon: Icons.play_arrow_rounded,
                                isFullWidth: true,
                                onPressed: () => cubit.resume(),
                              )
                            : state.isInputAllowed
                                ? Text(
                                    'Spot all matching targets while ignoring distractors.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: customTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
