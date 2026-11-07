import 'dart:math';

import 'package:cilgin_kafalar/data/content.dart';
import 'package:cilgin_kafalar/game/engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('her maç 5 tanıma + 4 bilgi + 3 şamata turu, ilk bilgi turu "Gerçek mi uydurma mı?"', () {
    for (var seed = 0; seed < 200; seed++) {
      final plan = GameEngine(rng: Random(seed)).buildPlan();
      expect(plan.length, 12);
      expect(plan.where((t) => t.category == Category.knowing).length, 5);
      expect(plan.where((t) => t.category == Category.info).length, 4);
      expect(plan.where((t) => t.category == Category.shamata).length, 3);
      expect(plan.first, RoundType.fact);
      expect(plan.where((t) => t == RoundType.starRain).length, greaterThanOrEqualTo(1));
      expect(plan.where((t) => t == RoundType.memo).length, greaterThanOrEqualTo(1));
      expect(plan.where((t) => t == RoundType.majority).length, greaterThanOrEqualTo(1));
    }
  });

  test('farklı maçlarda farklı oyun dizilimleri çıkar', () {
    final plans = {for (var seed = 0; seed < 50; seed++) GameEngine(rng: Random(seed)).buildPlan().map((t) => t.name).join(',')};
    expect(plans.length, greaterThan(20));
  });

  test('puan formülleri', () {
    final g = GameEngine(rng: Random(1));
    final fact = Round(type: RoundType.fact, prompt: 'x', options: const ['Gerçek', 'Uydurma'], correct: 0)..duration = 16;
    expect(g.pointsFor(fact, const Answer(0, 16)), 140);
    expect(g.pointsFor(fact, const Answer(0, 0)), 100);
    expect(g.pointsFor(fact, const Answer(1, 16)), 0);

    final est = Round(type: RoundType.estimate, prompt: 'x', estimate: estimates.first)..duration = 20; // 8 bacak, 0–20
    expect(g.pointsFor(est, const Answer(0, 5, value: 8)), 130);
    expect(g.pointsFor(est, const Answer(0, 5, value: 9)), 80); // %5 hata
    expect(g.pointsFor(est, const Answer(0, 5, value: 20)), 0);

    final ord = Round(type: RoundType.order, prompt: 'x', options: const ['a', 'b', 'c', 'd'], correctOrder: const [2, 0, 3, 1])..duration = 20;
    expect(g.pointsFor(ord, const Answer(0, 0, order: [2, 0, 3, 1])), 120);
    expect(g.pointsFor(ord, const Answer(0, 0, order: [0, 2, 3, 1])), 50);

    final star = Round(type: RoundType.starRain, prompt: 'x')..duration = 12;
    expect(g.pointsFor(star, const Answer(0, 0, value: 9)), 90);
    expect(g.pointsFor(star, const Answer(0, 0, value: 40)), 150);

    final maj = Round(type: RoundType.majority, prompt: 'x', options: const ['a', 'b', 'c', 'd'], correctSet: {1, 2}, correct: 1)..duration = 18;
    expect(g.pointsFor(maj, const Answer(2, 0)), 100);
    expect(g.pointsFor(maj, const Answer(0, 0)), 0);
  });

  test('içerik havuzları yeterli ve sıralama bulmacaları 4 maddeli', () {
    expect(allPrefQuestions.length, greaterThanOrEqualTo(18));
    expect(facts.length, greaterThanOrEqualTo(24));
    expect(estimates.every((e) => e.answer >= e.min && e.answer <= e.max), isTrue);
    expect(orderPuzzles.every((o) => o.items.length == 4), isTrue);
  });
}
