import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mojilearner_flutter/constants/coin_packs.dart';
import 'package:mojilearner_flutter/constants/season_pass.dart';
import 'package:mojilearner_flutter/services/purchase_service.dart';

/// How bought coins get from the store to the app, and the two ways that
/// differ from a pass.
///
/// Coins are the only *consumable* the app sells, and both halves of that word
/// matter here: the store has to be told to consume the purchase (or Play
/// refuses to sell the same pack twice), and the app must not pay out again
/// when a restore replays it (or a reinstall mints every top-up the account
/// ever made). Neither failure is visible in a screenshot, which is why they
/// are pinned here.
void main() {
  final pack = coinPacks.first;
  final pass = seasonPasses.first;

  late _FakeStore store;
  late PurchaseService service;

  setUp(() {
    store = _FakeStore();
    service = PurchaseService(store: store);
  });

  tearDown(() => service.dispose());

  test('asks the store about every coin pack', () async {
    await service.load();

    for (final p in coinPacks) {
      expect(store.queried, contains(p.productId));
    }
  });

  test('a bought pack is reported as coins, not as an entitlement', () async {
    await service.load();

    final coins = <CoinPack>[];
    final entitlements = <bool>[];
    final passes = <String>[];
    service.onCoinsPurchased.listen(coins.add);
    service.onEntitlementChanged.listen(entitlements.add);
    service.onPassPurchased.listen(passes.add);

    store.emit(_purchase(pack.productId, PurchaseStatus.purchased));
    await pumpEventQueue();

    expect(coins.map((c) => c.id), [pack.id]);
    expect(entitlements, isEmpty, reason: 'coins are not a subscription');
    expect(passes, isEmpty, reason: 'coins are not a pass');
  });

  test('a restore does not pay the coins out again', () async {
    await service.load();

    final coins = <CoinPack>[];
    service.onCoinsPurchased.listen(coins.add);

    store.emit(_purchase(pack.productId, PurchaseStatus.restored));
    await pumpEventQueue();

    expect(coins, isEmpty,
        reason: 'a replayed top-up would mint the balance on every reinstall');
  });

  test('a pack is bought as a consumable', () async {
    await service.load();

    await service.buy(_product(pack.productId));

    expect(store.boughtConsumable, [pack.productId]);
    expect(store.boughtNonConsumable, isEmpty,
        reason: 'an unconsumed pack can never be bought a second time');
  });

  test('a pass is still bought as a non-consumable', () async {
    await service.load();

    await service.buy(_product(pass.productId));

    expect(store.boughtNonConsumable, [pass.productId]);
    expect(store.boughtConsumable, isEmpty);
  });

  test('the purchase is completed, as both stores require', () async {
    await service.load();

    store.emit(_purchase(pack.productId, PurchaseStatus.purchased));
    await pumpEventQueue();

    expect(store.completed, [pack.productId]);
  });

  test('a pack with no listing has no price to show', () async {
    store.listed = [];
    await service.load();

    expect(service.coinPackProduct(pack.id), isNull);
  });
}

ProductDetails _product(String id) => ProductDetails(
      id: id,
      title: id,
      description: id,
      price: '£0.99',
      rawPrice: 0.99,
      currencyCode: 'GBP',
    );

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
  final List<String> boughtConsumable = [];
  final List<String> boughtNonConsumable = [];

  void emit(PurchaseDetails purchase) => _controller.add([purchase]);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    boughtConsumable.add(purchaseParam.productDetails.id);
    return true;
  }

  @override
  Future<bool> buyNonConsumable({
    required PurchaseParam purchaseParam,
  }) async {
    boughtNonConsumable.add(purchaseParam.productDetails.id);
    return true;
  }

  @override
  Future<ProductDetailsResponse> queryProductDetails(
      Set<String> identifiers) async {
    queried = identifiers;
    final sell = listed ?? identifiers.toList();
    return ProductDetailsResponse(
      productDetails: [for (final id in sell) _product(id)],
      notFoundIDs: [for (final id in identifiers) if (!sell.contains(id)) id],
    );
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase.productID);
}
