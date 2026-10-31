import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mojilearner_flutter/constants/coin_packs.dart';
import 'package:mojilearner_flutter/services/purchase_service.dart';

/// A subscription that ends has to come off.
///
/// Before this, the entitlement stream could only say "active": a player who
/// cancelled, was refunded, or whose card failed kept Plus on the phone for
/// good. The fix asks the store at launch and treats "nothing owned" as the end
/// of the subscription. The dangerous direction is revoking a paying player, so
/// most of what is pinned here is the cases where it must NOT revoke.
void main() {
  const plus = 'mimikin_plus_monthly';

  late _Store store;
  late PurchaseService service;
  late List<bool> changes;

  setUp(() async {
    store = _Store();
    service = PurchaseService(
      store: store,
      plusProductIds: const [plus],
      restoreSettle: Duration.zero,
    );
    await service.load();
    changes = [];
    service.onEntitlementChanged.listen(changes.add);
  });

  tearDown(() => service.dispose());

  test('a launch check that finds no subscription turns Plus off', () async {
    store.owned = [];

    await service.restore(revokeIfLapsed: true);
    await pumpEventQueue();

    expect(changes, [false]);
  });

  test('a launch check that finds the subscription keeps Plus on', () async {
    store.owned = [plus];

    await service.restore(revokeIfLapsed: true);
    await pumpEventQueue();

    expect(changes, [true], reason: 'seen, so never revoked');
  });

  test('the player\'s own restore button never revokes', () async {
    store.owned = [];

    await service.restore();
    await pumpEventQueue();

    expect(changes, isEmpty);
  });

  test('a store that errors is not the store saying it ended', () async {
    store.fail = true;

    await service.restore(revokeIfLapsed: true);
    await pumpEventQueue();

    expect(changes, isEmpty, reason: 'no answer must never cost a paying player');
  });

  test('owning only other things (a pack, a pass) is still "no Plus"', () async {
    store.owned = [coinPacks.first.productId];

    await service.restore(revokeIfLapsed: true);
    await pumpEventQueue();

    expect(changes, [false]);
  });
}

PurchaseDetails _purchase(String id) => PurchaseDetails(
      productID: id,
      purchaseID: 'p-$id',
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'test',
      ),
      transactionDate: null,
      status: PurchaseStatus.restored,
    );

ProductDetails _product(String id) => ProductDetails(
      id: id,
      title: id,
      description: id,
      price: '1',
      rawPrice: 1,
      currencyCode: 'USD',
    );

class _Store extends Fake implements InAppPurchase {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();

  /// What the store reports as owned when asked to restore.
  List<String> owned = [];
  bool fail = false;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    if (fail) throw Exception('store unreachable');
    if (owned.isNotEmpty) {
      _controller.add([for (final id in owned) _purchase(id)]);
    }
  }

  @override
  Future<ProductDetailsResponse> queryProductDetails(
      Set<String> identifiers) async {
    return ProductDetailsResponse(
      productDetails: [for (final id in identifiers) _product(id)],
      notFoundIDs: const [],
    );
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}
}
