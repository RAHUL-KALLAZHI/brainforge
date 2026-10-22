import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/core/widgets/app_button.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/logic/adaptive_difficulty_service.dart';
import 'package:brainforge/features/games/reverse_recall/logic/reverse_recall_cubit.dart';
import 'package:brainforge/features/games/reverse_recall/logic/reverse_recall_state.dart';
import 'widgets/reverse_recall_board.dart';
import 'widgets/reverse_recall_header.dart';
import 'widgets/reverse_recall_presentation_view.dart';
import 'widgets/reverse_recall_ready_view.dart';
import 'widgets/reverse_recall_result_view.dart';

/// Top-level playable screen for the Reverse Recall cognitive mini-game.
class ReverseRecallScreen extends StatelessWidget {
  final ReverseRecallCubit? cubit;
  final GameDifficulty? initialDifficulty;
  final int? initialSeed;
  final GameAttemptRepository? attemptRepository;
  final AdaptiveDifficultyService? adaptiveService;
  final bool fastPreviewForTesting;

  const ReverseRecallScreen({
    super.key,
    this.cubit,
    this.initialDifficulty,
    this.initialSeed,
    this.attemptRepository,
    this.adaptiveService,
    this.fastPreviewForTesting = false,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<ReverseRecallCubit>.value(
        value: cubit!,
        child: const _ReverseRecallContent(),
      );
    }

    return BlocProvider<ReverseRecallCubit>(
      create: (context) => ReverseRecallCubit(
        initialDifficulty: initialDifficulty,
        initialSeed: initialSeed,
        attemptRepository: attemptRepository,
        adaptiveService: adaptiveService,
        fastPreviewForTesting: fastPreviewForTesting,
      ),
      child: const _ReverseRecallContent(),
    );
  }
}

class _ReverseRecallContent extends StatelessWidget {
  const _ReverseRecallContent();

  Future<void> _handleExit(
      BuildContext context, ReverseRecallCubit cubit) async {
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
            title: const Text('Exit Reverse Recall?'),
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
    final cubit = context.read<ReverseRecallCubit>();
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return BlocBuilder<ReverseRecallCubit, ReverseRecallState>(
      builder: (context, state) {
        final status = state.sessionState.status;
        final phase = state.sessionState.phase;
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
                  // 1. Initial Readiness Screen
                  if (status == GameStatus.initial) {
                    return ReverseRecallReadyView(
                      state: state,
                      onDifficultyChanged: (newDiff) {
                        cubit.restart(difficulty: newDiff);
                      },
                      onStartPressed: () => cubit.startGame(),
                      onExitPressed: () => Navigator.of(context).maybePop(),
                    );
                  }

                  // 2. Terminal Result Screen
                  if (status.isTerminal) {
                    return ReverseRecallResultView(
                      state: state,
                      onProceedToNextLevelPressed: () =>
                          cubit.proceedToRecommendedLevel(),
                      onPlayAgainPressed: () =>
                          cubit.playAgainAtCompletedDifficulty(),
                      onReturnToGamePressed: () => cubit.returnToReadyView(),
                    );
                  }

                  // 3. Active Gameplay Screen
                  return Column(
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      ReverseRecallHeader(
                        state: state,
                        onExitPressed: () => _handleExit(context, cubit),
                      ),
                      const Spacer(),

                      // Countdown State
                      if (status == GameStatus.countdown) ...[
                        Center(
                          child: Text(
                            '${state.sessionState.countdownSecondsRemaining}',
                            style: AppTypography.displayLarge.copyWith(
                              fontSize: 96,
                              fontWeight: FontWeight.bold,
                              color: customTheme.accentCyan,
                            ),
                          ),
                        ),
                      ]
                      // Presentation Phase (Preview)
                      else if (phase == GamePhase.preview) ...[
                        ReverseRecallPresentationView(state: state),
                      ]
                      // Interactive Recall Phase (Input)
                      else ...[
                        ReverseRecallBoard(
                          state: state,
                          onDigitTapped: (digit) => cubit.onDigitEntered(digit),
                        ),
                      ],

                      const Spacer(),

                      // Bottom State Action / Paused Overlay
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md,
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
                                    'Enter all digits in reverse order before time runs out.',
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
