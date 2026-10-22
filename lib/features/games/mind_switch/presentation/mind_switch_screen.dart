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
import 'package:brainforge/features/games/mind_switch/logic/mind_switch_cubit.dart';
import 'package:brainforge/features/games/mind_switch/logic/mind_switch_state.dart';
import 'widgets/mind_switch_board.dart';
import 'widgets/mind_switch_header.dart';
import 'widgets/mind_switch_ready_view.dart';
import 'widgets/mind_switch_result_view.dart';

/// Top-level playable screen for the Mind Switch cognitive mini-game.
class MindSwitchScreen extends StatelessWidget {
  final MindSwitchCubit? cubit;
  final GameDifficulty? initialDifficulty;
  final int? initialSeed;
  final GameAttemptRepository? attemptRepository;
  final AdaptiveDifficultyService? adaptiveService;
  final bool fastPreviewForTesting;

  const MindSwitchScreen({
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
      return BlocProvider<MindSwitchCubit>.value(
        value: cubit!,
        child: const _MindSwitchContent(),
      );
    }

    return BlocProvider<MindSwitchCubit>(
      create: (context) => MindSwitchCubit(
        initialDifficulty: initialDifficulty,
        seed: initialSeed,
        attemptRepository: attemptRepository,
        adaptiveService: adaptiveService,
        fastPreviewForTesting: fastPreviewForTesting,
      ),
      child: const _MindSwitchContent(),
    );
  }
}

class _MindSwitchContent extends StatelessWidget {
  const _MindSwitchContent();

  Future<void> _handleExit(BuildContext context, MindSwitchCubit cubit) async {
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
            title: const Text('Exit Mind Switch?'),
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
    final cubit = context.read<MindSwitchCubit>();
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return BlocBuilder<MindSwitchCubit, MindSwitchState>(
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
                  // 1. Initial Readiness Screen
                  if (status == GameStatus.initial) {
                    return MindSwitchReadyView(
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
                    return MindSwitchResultView(
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
                      MindSwitchHeader(
                        state: state,
                        onExitPressed: () => _handleExit(context, cubit),
                      ),
                      Expanded(
                        child: MindSwitchBoard(
                          state: state,
                          onColorSelected: (c) => cubit.onColorSelected(c),
                        ),
                      ),
                      if (status == GameStatus.paused) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                          child: AppButton(
                            label: 'Resume Game',
                            icon: Icons.play_arrow_rounded,
                            isFullWidth: true,
                            onPressed: () => cubit.resume(),
                          ),
                        ),
                      ],
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
