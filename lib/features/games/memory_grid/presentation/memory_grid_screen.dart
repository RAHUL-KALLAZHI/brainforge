import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/core/widgets/app_button.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import '../logic/memory_grid_cubit.dart';
import '../logic/memory_grid_state.dart';
import 'package:brainforge/features/games/shared/logic/adaptive_difficulty_service.dart';
import 'widgets/memory_grid_board.dart';
import 'widgets/memory_grid_header.dart';
import 'widgets/memory_grid_ready_view.dart';
import 'widgets/memory_grid_result_view.dart';

/// Top-level playable screen for the Memory Grid mini-game.
class MemoryGridScreen extends StatelessWidget {
  final MemoryGridCubit? cubit;
  final GameDifficulty? initialDifficulty;
  final int? initialSeed;
  final GameAttemptRepository? attemptRepository;
  final AdaptiveDifficultyService? adaptiveService;
  final bool fastPreviewForTesting;

  const MemoryGridScreen({
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
      return BlocProvider<MemoryGridCubit>.value(
        value: cubit!,
        child: const _MemoryGridContent(),
      );
    }

    return BlocProvider<MemoryGridCubit>(
      create: (context) => MemoryGridCubit(
        initialDifficulty: initialDifficulty,
        initialSeed: initialSeed,
        attemptRepository: attemptRepository,
        adaptiveService: adaptiveService,
        fastPreviewForTesting: fastPreviewForTesting,
      ),
      child: const _MemoryGridContent(),
    );
  }
}

class _MemoryGridContent extends StatelessWidget {
  const _MemoryGridContent();

  Future<void> _handleExit(BuildContext context, MemoryGridCubit cubit) async {
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
            title: const Text('Exit Memory Grid?'),
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
    final cubit = context.read<MemoryGridCubit>();
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return BlocBuilder<MemoryGridCubit, MemoryGridState>(
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
                    return MemoryGridReadyView(
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
                    return MemoryGridResultView(
                      state: state,
                      onProceedToNextLevelPressed: () =>
                          cubit.proceedToRecommendedLevel(),
                      onPlayAgainPressed: () =>
                          cubit.playAgainAtCompletedDifficulty(),
                      onReturnToGamePressed: () => cubit.returnToReadyView(),
                    );
                  }

                  // 3. Active Gameplay Screen (Countdown, Preview, Recall, Paused)
                  return Column(
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      MemoryGridHeader(
                        state: state,
                        onExitPressed: () => _handleExit(context, cubit),
                      ),
                      const Spacer(),
                      MemoryGridBoard(
                        state: state,
                        onTileTapped: (index) => cubit.onTileTapped(index),
                      ),
                      const Spacer(),
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
                                    'Memorized tiles will not light up during input.',
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
