import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/app_runtime_config.dart';
import 'package:mojilearner_flutter/constants/coin_packs.dart';

/// The ladder is the offer, so these are tests about a promise rather than
/// about arithmetic: the coins double on every rung, the price does not quite
/// keep up, and so every step up is better value than the step below. A pack
/// that quietly stopped obeying any of that is a store listing that charges
/// for one thing and hands over another.
void main() {
  test('the bottom rung is the anchor: about a hundred coins for a dollar', () {
    final base = coinPacks.first;
    expect(base.coins, coinsPerDollar);
    expect(base.usdPrice, r'$0.99');
    // Nothing to advertise on the rung every other rung is measured against.
    expect(base.bonusPercent, 0);
  });

  test('the coins double on every rung', () {
    expect(coinPacks.map((p) => p.coins).toList(),
        [100, 200, 400, 800, 1600, 3200]);
  });

  test('the price rises by less than the coins do', () {
    // The whole discount, in one assertion: doubling the coins costs less than
    // doubling the money, which is what makes the larger pack the better buy.
    for (var i = 1; i < coinPacks.length; i++) {
      final below = coinPacks[i - 1];
      final above = coinPacks[i];
      expect(above.cents, greaterThan(below.cents));
      expect(above.cents, lessThan(below.cents * 2),
          reason: '${above.id} charges full price for double the coins');
    }
  });

  test('climbing the ladder never gets worse value', () {
    for (var i = 1; i < coinPacks.length; i++) {
      final below = coinPacks[i - 1];
      final above = coinPacks[i];
      expect(above.coins / above.cents, greaterThan(below.coins / below.cents),
          reason: '${above.id} costs more but pays no better than ${below.id}');
      expect(above.bonusPercent, greaterThan(below.bonusPercent),
          reason: '${above.id} badges no better than ${below.id}');
    }
  });

  test('the badge matches the price it is printed beside', () {
    // The badge is derived, so this is really a test that the derivation is
    // the one the page claims: X% more coins for the same money as the base
    // rung, rounded to whole per cent.
    for (final pack in coinPacks) {
      final base = coinPacks.first;
      final expected =
          ((pack.coins / pack.cents) / (base.coins / base.cents) * 100 - 100)
              .round();
      expect(pack.bonusPercent, expected, reason: '${pack.id} misbadges');
    }
    expect(coinPacks.map((p) => p.bonusPercent).toList(),
        [0, 5, 10, 17, 24, 32]);
  });

  test('the discount stays a discount and never becomes a giveaway', () {
    // A top rung paying double would make every row beneath it look like a
    // mistake; a top rung paying nothing extra would make the ladder pointless.
    expect(coinPacks.last.bonusPercent, inInclusiveRange(20, 50));
  });

  test('every rung lists a price a console can be set to', () {
    for (final pack in coinPacks) {
      expect(pack.cents % 10, isNot(0),
          reason: '${pack.id} is priced on a round number, not a price point');
      expect(pack.usdPrice, startsWith(r'$'));
      expect(pack.usdPrice, matches(RegExp(r'^\$\d+\.\d\d$')));
    }
  });

  test('ids and product ids are unique', () {
    expect(coinPacks.map((p) => p.id).toSet(), hasLength(coinPacks.length));
    expect(
      coinPacks.map((p) => p.productId).toSet(),
      hasLength(coinPacks.length),
    );
  });

  test('every pack is one of the products the store is asked about', () {
    // Without this a pack has a card, a price slot and no listing to fill it,
    // which shows as a row priced from the list rather than from the store.
    for (final pack in coinPacks) {
      expect(AppRuntimeConfig.storeProductIds, contains(pack.productId));
    }
  });

  test('a pack can be found by its id', () {
    for (final pack in coinPacks) {
      expect(coinPackById(pack.id), same(pack));
    }
    expect(coinPackById('not-a-pack'), isNull);
  });
}
