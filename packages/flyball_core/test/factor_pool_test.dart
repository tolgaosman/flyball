import 'dart:math';

import 'package:flyball_core/flyball_core.dart';
import 'package:test/test.dart';

void main() {
  group('FactorPool.pickAxisValidSix', () {
    test('always returns 3 rows + 3 columns, all six unique', () {
      final rng = Random(1);
      for (var i = 0; i < 200; i++) {
        final axes = FactorPool.pickAxisValidSix(rng);
        expect(axes.rows.length, 3);
        expect(axes.columns.length, 3);
        final all = [...axes.rows, ...axes.columns];
        expect(all.toSet().length, 6);
        expect(FactorPool.axesAreValid(axes.rows, axes.columns), isTrue);
      }
    });
  });

  group('axesAreValid', () {
    test('rejects nationality vs nationality across axes', () {
      final rows = [
        const Factor(type: FactorType.nationality, label: 'France', value: 'France'),
        const Factor(type: FactorType.team, label: 'Played for Arsenal', value: 'Arsenal'),
        const Factor(type: FactorType.team, label: 'Played for Chelsea', value: 'Chelsea'),
      ];
      final columns = [
        const Factor(type: FactorType.nationality, label: 'Spain', value: 'Spain'),
        const Factor(type: FactorType.team, label: 'Played for Roma', value: 'Roma'),
        const Factor(type: FactorType.team, label: 'Played for Lazio', value: 'Lazio'),
      ];
      expect(FactorPool.axesAreValid(rows, columns), isFalse);
    });

    test('rejects Euros and Copa America on the same board', () {
      final rows = [
        const Factor(
            type: FactorType.wonInternational, label: 'Won Euros', value: 'Euros'),
        const Factor(type: FactorType.team, label: 'Played for Arsenal', value: 'Arsenal'),
        const Factor(type: FactorType.team, label: 'Played for Chelsea', value: 'Chelsea'),
      ];
      final columns = [
        const Factor(
            type: FactorType.wonInternational,
            label: 'Won Copa America',
            value: 'Copa America'),
        const Factor(type: FactorType.team, label: 'Played for Roma', value: 'Roma'),
        const Factor(type: FactorType.team, label: 'Played for Lazio', value: 'Lazio'),
      ];
      expect(FactorPool.axesAreValid(rows, columns), isFalse);
    });

    test('rejects a nationality that could never win the crossed tournament', () {
      const usa = Factor(type: FactorType.nationality, label: 'USA', value: 'USA');
      const worldCup = Factor(
          type: FactorType.wonInternational, label: 'Won World Cup', value: 'World Cup');
      expect(FactorPool.isCellPossible(usa, worldCup), isFalse);
    });

    test('accepts a nationality that has actually won the crossed tournament', () {
      const brazil = Factor(type: FactorType.nationality, label: 'Brazil', value: 'Brazil');
      const worldCup = Factor(
          type: FactorType.wonInternational, label: 'Won World Cup', value: 'World Cup');
      expect(FactorPool.isCellPossible(brazil, worldCup), isTrue);
    });
  });
}
