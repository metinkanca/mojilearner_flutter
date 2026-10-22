import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mojilearner_flutter/constants/season_pass.dart';
import 'package:mojilearner_flutter/services/purchase_service.dart';

/// How a bought season pass gets from the store to the app.
///
/// Worth pinning separately from the subscription path because the two are
/// different kinds of thing and the service reports them on different streams:
/// Plus is a subscription that can also stop being owned, a pass is a
/// non-consumable that is only ever gained. A pass arriving on the entitlement
/// stream would silently make the buyer a Plus subscriber.
void main() {
  final pass = seasonPasses.first;

  late _FakeStore store;
  late PurchaseService service;

  setUp(() {
    store = _FakeStore();
    service = PurchaseService(store: store);
  });

  tearDown(() => service.dispose());

  test('asks the store about the pass as well as the subscriptions', () async {
    await service.load();

    expect(store.queried, contains(pass.productId));
  });

  test('a bought pass is reported as a pass, not as an entitlement', () async {
    await service.load();

    final passes = <String>[];
    final entitlements = <bool>[];
    service.onPassPurchased.listen(passes.add);
    service.onEntitlementChanged.listen(entitlements.add);

    store.emit(_purchase(pass.productId, PurchaseStatus.purchased));
    await pumpEventQueue();

    expect(passes, [pass.id]);
    expect(entitlements, isEmpty, reason: 'a pass is not a subscription');
  });

  test('a restore replays as the same pass', () async {
    await service.load();

    final passes = <String>[];
    service.onPassPurchased.listen(passes.add);

    store.emit(_purchase(pass.productId, PurchaseStatus.restored));
    await pumpEventQueue();

    expect(passes, [pass.id]);
  });

  // Both stores require this and it is not optional: an unacknowledged Play
  // purchase is refunded automatically after three days, so a pass that is
  // granted but never completed is one the player stops owning and paying for.
  test('completes the purchase with the store', () async {
    await service.load();

    store.emit(_purchase(pass.productId, PurchaseStatus.purchased));
    await pumpEventQueue();

    expect(store.completed, [pass.productId]);
  });

  test('something the catalogue does not sell is reported as neither',
      () async {
    await service.load();

    final passes = <String>[];
    final entitlements = <bool>[];
    service.onPassPurchased.listen(passes.add);
    service.onEntitlementChanged.listen(entitlements.add);

    store.emit(_purchase('com.example.something.else',
        PurchaseStatus.purchased));
    await pumpEventQueue();

    expect(passes, isEmpty);
    expect(entitlements, isEmpty);
  });

  test('the pass listing is exposed once the store answers', () async {
    store.listed = [pass.productId];
    await service.load();

    expect(service.passProduct(pass.id), isNotNull);
    expect(service.passProduct('no-such-pass'), isNull);
  });

  test('no listing means no product, which is what draws no price', () async {
    store.listed = const [];
    await service.load();

    expect(service.passProduct(pass.id), isNull);
  });
}

PurchaseDetails _purchase(String productId, PurchaseStatus status) =>
    PurchaseDetails(
      productID: productId,
      purchaseID: 'p1',
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'test',
      ),
      transactionDate: null,
      status: status,
    )..pendingCompletePurchase = true;

class _FakeStore extends Fake implements InAppPurchase {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();

  /// Ids the service asked about, and the ids the store admits to having.
  Set<String> queried = {};
  List<String>? listed;
  final List<String> completed = [];

  void emit(PurchaseDetails purchase) => _controller.add([purchase]);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
      Set<String> identifiers) async {
    queried = identifiers;
    final sell = listed ?? identifiers.toList();
    return ProductDetailsResponse(
      productDetails: [
        for (final id in sell)
          ProductDetails(
            id: id,
            title: id,
            description: id,
            price: '£4.99',
            rawPrice: 4.99,
            currencyCode: 'GBP',
          ),
      ],
      notFoundIDs: [for (final id in identifiers) if (!sell.contains(id)) id],
    );
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase.productID);
}
