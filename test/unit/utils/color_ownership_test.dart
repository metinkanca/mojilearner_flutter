import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/color_ownership.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';

/// The catalogue is part of the contract here, not just the resolver: the
/// split only means anything if the natural coats stay free and the fantasy
/// ones stay priced, and either mistake would be silent.
void main() {
  SwatchStatus statusOf(
    PetSwatch swatch, {
    Set<String> unlocked = const {},
    int coins = 0,
  }) =>
      ColorOwnership.statusFor(
        swatch,
        unlockedItemIds: unlocked,
        coins: coins,
      );

  PetSwatch coat(String id) =>
      kAllBodySwatches.firstWhere((s) => s.id == id);

  group('the palettes', () {
    test('every natural colour is free', () {
      for (final s in [...kBodySwatches, ...kEyeSwatches]) {
        expect(s.price, isNull, reason: '${s.id} is a natural colour');
      }
    });

    test('every fantasy colour has a price', () {
      for (final s in [...kFancyBodySwatches, ...kFancyEyeSwatches]) {
        expect(s.price, isNotNull, reason: '${s.id} is not for sale');
        expect(s.price, greaterThan(0), reason: '${s.id} is free');
      }
    });

    // Ownership is keyed by id, and the ids share a namespace with the shop's
    // item ids, so a duplicate would hand out two things for one purchase.
    test('ids are unique across every palette', () {
      final ids = [...kAllBodySwatches, ...kAllEyeSwatches].map((s) => s.id);
      expect(ids.toSet().length, ids.length);
    });

    // A design stores the hex, not the id, so two swatches sharing a hex
    // would make the owned one unlock the other.
    test('hexes are unique within a palette', () {
      for (final palette in [kAllBodySwatches, kAllEyeSwatches]) {
        final hexes = palette.map((s) => s.hex.toLowerCase());
        expect(hexes.toSet().length, hexes.length);
      }
    });

    test('the paid coats never collide with the natural ones', () {
      final natural = kBodySwatches.map((s) => s.hex.toLowerCase()).toSet();
      for (final s in kFancyBodySwatches) {
        expect(natural.contains(s.hex.toLowerCase()), isFalse,
            reason: '${s.id} repaints a free coat');
      }
    });
  });

  group('resolving a swatch', () {
    test('a natural coat is owned by a player with nothing', () {
      final status = statusOf(coat('coat_smoke'));
      expect(status.isOwned, isTrue);
      expect(status.isForSale, isFalse);
    });

    test('an unbought fantasy coat is for sale', () {
      final status = statusOf(coat('coat_ultraviolet'));
      expect(status.isForSale, isTrue);
      expect(status.affordable, isFalse);
      expect(status.canBuyNow, isFalse);
    });

    test('a price the player can meet is buyable now', () {
      final status = statusOf(coat('coat_ultraviolet'), coins: 999999);
      expect(status.canBuyNow, isTrue);
    });

    test('a bought coat is owned, and stops asking for money', () {
      final status = statusOf(
        coat('coat_ultraviolet'),
        unlocked: {'coat_ultraviolet'},
        coins: 999999,
      );
      expect(status.isOwned, isTrue);
      expect(status.affordable, isFalse);
    });

    // Ownership is global: buying the colour buys it for whichever pet is out.
    test('one unlocked id covers every pet', () {
      expect(
        ColorOwnership.isOwned(
          coat('coat_gold'),
          unlockedItemIds: {'coat_gold'},
        ),
        isTrue,
      );
    });
  });

  group('allowing a hex', () {
    test('a natural coat is always allowed', () {
      expect(
        ColorOwnership.isHexAllowed('#959379', kAllBodySwatches,
            unlockedItemIds: const {}),
        isTrue,
      );
    });

    test('an unbought fantasy coat is not', () {
      expect(
        ColorOwnership.isHexAllowed('#8A4BF0', kAllBodySwatches,
            unlockedItemIds: const {}),
        isFalse,
      );
    });

    test('buying it allows it', () {
      expect(
        ColorOwnership.isHexAllowed('#8A4BF0', kAllBodySwatches,
            unlockedItemIds: const {'coat_ultraviolet'}),
        isTrue,
      );
    });

    test('case does not decide whether a colour is locked', () {
      expect(
        ColorOwnership.isHexAllowed('#8a4bf0', kAllBodySwatches,
            unlockedItemIds: const {}),
        isFalse,
      );
    });

    // A colour no palette knows about is a legacy save or a retired swatch.
    // Refusing it would take a pet's existing coat away on update.
    test('a colour outside the catalogue is left alone', () {
      expect(
        ColorOwnership.isHexAllowed('#123456', kAllBodySwatches,
            unlockedItemIds: const {}),
        isTrue,
      );
    });
  });
}
