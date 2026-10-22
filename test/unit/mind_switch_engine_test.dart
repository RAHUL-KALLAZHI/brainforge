import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/mind_switch/domain/mind_switch_challenge.dart';
import 'package:brainforge/features/games/mind_switch/domain/mind_switch_config.dart';
import 'package:brainforge/features/games/mind_switch/logic/mind_switch_engine.dart';
import 'package:brainforge/features/games/mind_switch/logic/mind_switch_generator.dart';

void main() {
  group('MindSwitchConfig & Difficulty Mapping Tests', () {
    test('Game ID and Title constants are correct', () {
      expect(MindSwitchConfig.gameId, 'mind_switch');
      expect(MindSwitchConfig.gameTitle, 'Mind Switch');
    });

    test('Trial counts scale progressively across levels 1 to 10', () {
      expect(MindSwitchConfig.totalTrialsForDifficulty(const GameDifficulty(1)),
          10);
      expect(MindSwitchConfig.totalTrialsForDifficulty(const GameDifficulty(5)),
          18);
      expect(
          MindSwitchConfig.totalTrialsForDifficulty(const GameDifficulty(10)),
          25);
    });

    test('Response time limits tighten as level increases', () {
      final l1Limit =
          MindSwitchConfig.trialTimeLimitForDifficulty(const GameDifficulty(1));
      final l5Limit =
          MindSwitchConfig.trialTimeLimitForDifficulty(const GameDifficulty(5));
      final l10Limit = MindSwitchConfig.trialTimeLimitForDifficulty(
          const GameDifficulty(10));

      expect(l1Limit.inMilliseconds, equals(5000));
      expect(l5Limit.inMilliseconds, equals(3000));
      expect(l10Limit.inMilliseconds, equals(1500));
      expect(l1Limit, greaterThan(l5Limit));
      expect(l5Limit, greaterThan(l10Limit));
    });

    test('Mistake tolerances scale from lenient down to strict (0)', () {
      expect(MindSwitchConfig.maxMistakesForDifficulty(const GameDifficulty(1)),
          3);
      expect(MindSwitchConfig.maxMistakesForDifficulty(const GameDifficulty(3)),
          2);
      expect(MindSwitchConfig.maxMistakesForDifficulty(const GameDifficulty(5)),
          1);
      expect(
          MindSwitchConfig.maxMistakesForDifficulty(const GameDifficulty(10)),
          0);
    });

    test('Switch intervals become more frequent at high difficulties', () {
      final l1Interval =
          MindSwitchConfig.switchIntervalForDifficulty(const GameDifficulty(1));
      final l10Interval = MindSwitchConfig.switchIntervalForDifficulty(
          const GameDifficulty(10));

      expect(l1Interval, greaterThanOrEqualTo(4));
      expect(l10Interval, equals(1));
    });

    test('forDifficulty produces valid GameConfig', () {
      final config =
          MindSwitchConfig.forDifficulty(const GameDifficulty(3), seed: 42);
      expect(config.gameId, 'mind_switch');
      expect(config.difficulty.level, 3);
      expect(config.seed, 42);
      expect(config.sequenceLength, 14);
      expect(config.responseTimeLimit?.inMilliseconds, 4000);
      expect(config.targetRounds, 1);
    });
  });

  group('MindSwitchGenerator Tests', () {
    const generator = MindSwitchGenerator();

    test('Deterministic generation: identical seeds produce identical trials',
        () {
      final config =
          MindSwitchConfig.forDifficulty(const GameDifficulty(4), seed: 9999);

      final challengeA = generator.generate(roundIndex: 0, config: config);
      final challengeB = generator.generate(roundIndex: 0, config: config);

      expect(challengeA.trials.length, equals(challengeB.trials.length));
      for (var i = 0; i < challengeA.trials.length; i++) {
        final tA = challengeA.trials[i];
        final tB = challengeB.trials[i];
        expect(tA.rule, equals(tB.rule));
        expect(tA.wordColor, equals(tB.wordColor));
        expect(tA.inkColor, equals(tB.inkColor));
        expect(tA.targetColor, equals(tB.targetColor));
        expect(tA.isRuleSwitch, equals(tB.isRuleSwitch));
      }
    });

    test('Different seeds produce different trial sequences', () {
      final configA =
          MindSwitchConfig.forDifficulty(const GameDifficulty(5), seed: 101);
      final configB =
          MindSwitchConfig.forDifficulty(const GameDifficulty(5), seed: 202);

      final challengeA = generator.generate(roundIndex: 0, config: configA);
      final challengeB = generator.generate(roundIndex: 0, config: configB);

      final targetsA = challengeA.trials.map((t) => t.targetColor).toList();
      final targetsB = challengeB.trials.map((t) => t.targetColor).toList();

      expect(targetsA, isNot(equals(targetsB)));
    });

    test('First trial always has isRuleSwitch == false', () {
      final config =
          MindSwitchConfig.forDifficulty(const GameDifficulty(2), seed: 777);
      final challenge = generator.generate(roundIndex: 0, config: config);

      expect(challenge.trials.first.isRuleSwitch, isFalse);
    });

    test('Target color matches rule condition correctly', () {
      const trialInk = MindSwitchTrial(
        index: 0,
        rule: MindSwitchRule.color,
        wordColor: MindSwitchColor.red,
        inkColor: MindSwitchColor.blue,
        isRuleSwitch: false,
      );
      expect(trialInk.targetColor, equals(MindSwitchColor.blue));

      const trialWord = MindSwitchTrial(
        index: 1,
        rule: MindSwitchRule.word,
        wordColor: MindSwitchColor.red,
        inkColor: MindSwitchColor.blue,
        isRuleSwitch: true,
      );
      expect(trialWord.targetColor, equals(MindSwitchColor.red));
    });
  });

  group('MindSwitchEngine Tests', () {
    const engine = MindSwitchEngine();

    test('evaluateInput validates target color according to active rule', () {
      const trial0 = MindSwitchTrial(
        index: 0,
        rule: MindSwitchRule.color,
        wordColor: MindSwitchColor.green,
        inkColor: MindSwitchColor.yellow,
        isRuleSwitch: false,
      );
      const trial1 = MindSwitchTrial(
        index: 1,
        rule: MindSwitchRule.word,
        wordColor: MindSwitchColor.green,
        inkColor: MindSwitchColor.yellow,
        isRuleSwitch: true,
      );

      const challenge = MindSwitchChallenge(
        roundIndex: 0,
        trials: [trial0, trial1],
        maxMistakesAllowed: 2,
      );

      // Trial 0: rule is color -> target is yellow
      expect(
        engine.evaluateInput(
          challenge: challenge,
          input: MindSwitchColor.yellow,
          stepIndex: 0,
        ),
        isTrue,
      );
      expect(
        engine.evaluateInput(
          challenge: challenge,
          input: MindSwitchColor.green,
          stepIndex: 0,
        ),
        isFalse,
      );

      // Trial 1: rule is word -> target is green
      expect(
        engine.evaluateInput(
          challenge: challenge,
          input: MindSwitchColor.green,
          stepIndex: 1,
        ),
        isTrue,
      );
      expect(
        engine.evaluateInput(
          challenge: challenge,
          input: MindSwitchColor.yellow,
          stepIndex: 1,
        ),
        isFalse,
      );
    });

    test('evaluateInput returns false on out of bounds step index', () {
      const challenge = MindSwitchChallenge(
        roundIndex: 0,
        trials: [
          MindSwitchTrial(
            index: 0,
            rule: MindSwitchRule.color,
            wordColor: MindSwitchColor.red,
            inkColor: MindSwitchColor.red,
            isRuleSwitch: false,
          ),
        ],
        maxMistakesAllowed: 1,
      );

      expect(
        engine.evaluateInput(
          challenge: challenge,
          input: MindSwitchColor.red,
          stepIndex: -1,
        ),
        isFalse,
      );
      expect(
        engine.evaluateInput(
          challenge: challenge,
          input: MindSwitchColor.red,
          stepIndex: 5,
        ),
        isFalse,
      );
    });
  });
}
