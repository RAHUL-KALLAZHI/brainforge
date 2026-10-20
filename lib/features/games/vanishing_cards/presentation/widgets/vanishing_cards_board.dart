import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import '../../logic/vanishing_cards_state.dart';
import 'vanishing_cards_tile.dart';

/// Responsive board grid rendering card positions for Vanishing Cards.
class VanishingCardsBoard extends StatelessWidget {
  final VanishingCardsState state;
  final ValueChanged<int> onCardTapped;

  const VanishingCardsBoard({
    super.key,
    required this.state,
    required this.onCardTapped,
  });

  @override
  Widget build(BuildContext context) {
    final columns = state.challenge.gridColumns;
    final rows = state.challenge.gridRows;
    final cards = state.challenge.cards;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth = constraints.maxWidth;
            final double availableHeight = constraints.maxHeight;

            // Compute ideal cell dimension preserving aspect ratio without overflow
            final double horizontalSpacing = (columns - 1) * AppSpacing.sm;
            final double verticalSpacing = (rows - 1) * AppSpacing.sm;

            final double maxTileWidth =
                (availableWidth - horizontalSpacing) / columns;
            final double maxTileHeight =
                (availableHeight - verticalSpacing) / rows;

            // Ideal card aspect ratio: ~0.8 (slightly taller than wide)
            final double tileSize = maxTileWidth.clamp(48.0, 96.0);
            final double childAspectRatio =
                (maxTileWidth / maxTileHeight).clamp(0.72, 1.15).toDouble();

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (tileSize * columns) + horizontalSpacing + 32,
              ),
              child: GridView.builder(
                key: const Key('vanishing_cards_grid'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  final isFound = state.foundCardPositions.contains(index);
                  final isMistake = state.mistakePositions.contains(index);

                  return VanishingCardsTile(
                    key: Key('vanishing_cards_tile_$index'),
                    card: card,
                    isPreviewing: state.isPreviewing,
                    isFound: isFound,
                    isMistake: isMistake,
                    isInteractive: state.isInputAllowed,
                    onTap: () => onCardTapped(index),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
