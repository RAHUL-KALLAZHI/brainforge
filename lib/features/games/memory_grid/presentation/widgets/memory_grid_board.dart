import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/features/games/memory_grid/logic/memory_grid_state.dart';
import 'memory_grid_tile.dart';

/// Responsive, aspect-ratio locked tile board for Memory Grid.
class MemoryGridBoard extends StatelessWidget {
  final MemoryGridState state;
  final ValueChanged<int> onTileTapped;

  const MemoryGridBoard({
    super.key,
    required this.state,
    required this.onTileTapped,
  });

  @override
  Widget build(BuildContext context) {
    final rows = state.config.gridRows ?? 3;
    final columns = state.config.gridColumns ?? 3;
    final totalTiles = rows * columns;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 420,
          maxHeight: 420,
        ),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.0,
              ),
              itemCount: totalTiles,
              itemBuilder: (context, index) {
                final row = index ~/ columns;
                final col = index % columns;
                final isHighlighted = state.activePreviewTileIndex == index;
                final isSelected = state.playerSelections.contains(index);

                bool? isCorrect;
                if (state.lastTappedTile == index) {
                  isCorrect = state.lastInputCorrect;
                } else if (isSelected) {
                  isCorrect = true;
                }

                // Disallow re-tapping a tile that was already selected
                final canTap = state.isInputAllowed && !isSelected;

                return MemoryGridTile(
                  key: ValueKey('tile_$index'),
                  index: index,
                  row: row,
                  column: col,
                  isHighlighted: isHighlighted,
                  isSelected: isSelected,
                  isCorrect: isCorrect,
                  isInputAllowed: canTap,
                  onTap: () => onTileTapped(index),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
