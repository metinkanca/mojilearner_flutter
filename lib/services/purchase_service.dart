import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../constants/app_runtime_config.dart';
import '../constants/coin_packs.dart';
import '../constants/season_pass.dart';

/// The store, as the rest of the app needs it.
///
/// Wraps `in_app_purchase` so nothing above this layer has to know about
/// purchase streams, pending states or the difference between Play Billing and
/// StoreKit. What it exposes is: what is for sale, whether a purchase is in
/// flight, and a stream of entitlement changes.
///
/// Three things about subscriptions this deliberately does *not* pretend to
/// solve on the client:
///
/// * **The client is not the entitlement.** A purchase here flips a local
///   flag so the app responds immediately, but the flag is a cache. The thing
///   that must actually gate a model call is the proxy, against a receipt it
///   verified itself — see `server/src/limits.js`, which already documents why
///   a token shipped inside the APK cannot be trusted for this.
/// * **Restores are not optional.** Both stores require a way to recover a
///   subscription on a new device, and a player who paid and cannot get it
///   back writes the review that costs the most.
/// * **A cancelled or expired subscription has to come *off*.** Handled by
///   the same stream: `in_app_purchase` reports the current set on restore,
///   and anything not in it is no longer owned.
class PurchaseService {
  PurchaseService({
    InAppPurchase? store,
    List<String>? plusProductIds,
    Duration restoreSettle = const Duration(seconds: 4),
  })  : _store = store ?? InAppPurchase.instance,
        _plusProductIds = plusProductIds ?? AppRuntimeConfig.plusProductIds,
        _restoreSettle = restoreSettle;

  final List<String> _plusProductIds;

  /// How long a restore is given to deliver its purchases before the answer
  /// "none" is believed. They arrive on the purchase stream, not as the return
  /// value of the call that asked for them.
  final Duration _restoreSettle;

  /// Whether a Plus purchase has come through since the current restore began.
  bool _plusSeenInRestore = false;

  final InAppPurchase _store;

  /// Hands a Plus subscription's Google Play purchase token to the proxy, which
  /// checks it with Google. Wired in `main.dart`; null in tests and wherever
  /// there is no proxy. Android only: Apple receipts are a different check the
  /// proxy does not make yet, so iOS members stay on the free server allowance.
  Future<void> Function(String productId, String purchaseToken)? onPlusReceipt;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final StreamController<bool> _entitlementController =
      StreamController<bool>.broadcast();

  /// Fires true when Plus becomes active and false when it stops being.
  ///
  /// A stream rather than a return value because a purchase can complete long
  /// after the button was tapped — the store may show its own sheet, ask for a
  /// password, or finish while the app was backgrounded.
  Stream<bool> get onEntitlementChanged => _entitlementController.stream;

  final StreamController<String> _passController =
      StreamController<String>.broadcast();

  /// Fires the id of a season pass the store says this account owns.
  ///
  /// Separate from [onEntitlementChanged] because the two are different kinds
  /// of thing: Plus is a subscription that can also stop being owned, so it
  /// reports a boolean that goes both ways, while a pass is a non-consumable
  /// that is only ever gained. Nothing revokes a pass -- and nothing should,
  /// since a track with claimed tiers on it has to keep working.
  ///
  /// A restore replays through here too, which is safe: `grantPass` is
  /// idempotent, so a replay cannot reset the XP baseline and take back
  /// progress the player already made.
  Stream<String> get onPassPurchased => _passController.stream;

  final StreamController<CoinPack> _coinController =
      StreamController<CoinPack>.broadcast();

  /// Fires the pack the player just bought, once per completed purchase.
  ///
  /// A pack, not a coin count, so the grant is looked up from the catalogue
  /// rather than taken from anything the store hands back — the store knows
  /// what was paid for, never what it is worth in this app.
  ///
  /// Unlike the two streams above, a restore never fires this one. Coins are a
  /// consumable that has already been spent by the time a restore happens, and
  /// replaying one would mint the balance again on every new device. See
  /// [_onPurchaseUpdates].
  Stream<CoinPack> get onCoinsPurchased => _coinController.stream;

  final Map<String, ProductDetails> _products = {};

  /// The subscription plans, in the order the paywall should show them.
  ///
  /// Empty until [load] has run, and empty forever on a build with no product
  /// ids configured — which is what the paywall reads to decide between an
  /// offer and an honest "not open yet".
  List<ProductDetails> get products => [
        for (final id in AppRuntimeConfig.plusProductIds)
          if (_products[id] != null) _products[id]!,
      ];

  /// The store's listing for one pass, or null when it has none.
  ///
  /// Null is the ordinary state until the listing exists in the console, and
  /// the pass screen reads it exactly as the paywall reads [products]: no
  /// listing, no price, no button.
  ProductDetails? passProduct(String passId) {
    final pass = seasonPassById(passId);
    return pass == null ? null : _products[pass.productId];
  }

  /// The store's listing for one coin pack, or null when it has none.
  ProductDetails? coinPackProduct(String packId) {
    final pack = coinPackById(packId);
    return pack == null ? null : _products[pack.productId];
  }

  bool _available = false;

  /// Whether the store answered at all. False on a desktop build, on a device
  /// with no Play Services, and on any build with no products configured.
  bool get isAvailable => _available && _products.isNotEmpty;

  bool _purchasePending = false;
  bool get isPurchasePending => _purchasePending;

  /// Connects to the store and asks what the configured ids cost.
  ///
  /// Safe to call when nothing is configured: it returns having done nothing,
  /// so a build without store products never blocks startup on a platform
  /// channel that will not answer.
  Future<void> load() async {
    if (!AppRuntimeConfig.storeConfigured) return;

    try {
      _available = await _store.isAvailable();
      if (!_available) return;

      _subscription ??= _store.purchaseStream.listen(
        _onPurchaseUpdates,
        onError: (Object error) {
          // A broken purchase stream must not take the app down. The player
          // keeps the entitlement they already had; the next restore fixes it.
          debugPrint('⚠️ Purchase stream error: $error');
          _purchasePending = false;
        },
      );

      final response = await _store.queryProductDetails(
        AppRuntimeConfig.storeProductIds.toSet(),
      );
      for (final product in response.productDetails) {
        _products[product.id] = product;
      }

      if (response.notFoundIDs.isNotEmpty) {
        // Almost always a product that exists in the build but not yet in the
        // store console. Worth saying out loud: the paywall will silently
        // offer one plan instead of two and nothing else will hint at why.
        debugPrint(
          '⚠️ Store did not recognise: ${response.notFoundIDs.join(', ')}',
        );
      }
    } catch (e) {
      // Includes the platform channel simply not being there, which is the
      // normal case on desktop and in tests.
      debugPrint('⚠️ Store unavailable: $e');
      _available = false;
    }
  }

  /// Starts a purchase. The result arrives on [onEntitlementChanged],
  /// [onPassPurchased] or [onCoinsPurchased], not from this call.
  ///
  /// Which of the store's two buy calls is used is decided here rather than by
  /// the caller, because getting it wrong is not a display bug: a coin pack
  /// bought as a non-consumable is never consumed, and Play then refuses to
  /// sell that pack to that account ever again. So the catalogue answers the
  /// question — a product id that is a coin pack is consumable, and everything
  /// else (subscriptions, passes) is not.
  Future<void> buy(ProductDetails product) async {
    if (_purchasePending) return;
    _purchasePending = true;
    final param = PurchaseParam(productDetails: product);
    try {
      if (_coinPackFor(product.id) != null) {
        await _store.buyConsumable(purchaseParam: param);
      } else {
        await _store.buyNonConsumable(purchaseParam: param);
      }
    } catch (e) {
      debugPrint('⚠️ Purchase failed to start: $e');
      _purchasePending = false;
    }
  }

  /// Asks the store to replay what this account already owns.
  ///
  /// The results arrive through the same stream as a fresh purchase, so a
  /// restore and a purchase are the same code path from here on.
  ///
  /// With [revokeIfLapsed], a restore that finds no Plus subscription reports
  /// that Plus has ended. Without this the entitlement could only ever be
  /// switched on: a subscriber who cancelled, was refunded, or whose card failed
  /// kept the member perks for good. It is only used for the automatic check at
  /// launch, never for the player's own "restore" button, and a restore that
  /// *errors* never revokes: not hearing from the store is not the store saying
  /// the subscription ended.
  Future<void> restore({bool revokeIfLapsed = false}) async {
    if (!isAvailable) return;
    _plusSeenInRestore = false;
    try {
      await _store.restorePurchases();
      if (revokeIfLapsed) {
        await Future<void>.delayed(_restoreSettle);
        if (!_plusSeenInRestore) _entitlementController.add(false);
      }
    } catch (e) {
      debugPrint('⚠️ Restore failed: $e');
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          continue;

        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          _purchasePending = false;
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _purchasePending = false;
          if (_isPlus(purchase)) {
            _plusSeenInRestore = true;
            _entitlementController.add(true);
            _reportReceipt(purchase);
          }
          final passId = _passIdFor(purchase);
          if (passId != null) _passController.add(passId);
          // Coins only on a real purchase. A restore replays everything the
          // account has ever bought, and coins are spent the moment they
          // arrive — so granting on a replay would hand a player the whole
          // history of their top-ups again on every reinstall.
          final pack = _coinPackFor(purchase.productID);
          if (pack != null && purchase.status == PurchaseStatus.purchased) {
            _coinController.add(pack);
          }
          break;
      }

      // Required by both stores, and required even for a failed purchase:
      // an unacknowledged Play purchase is automatically refunded after three
      // days, and an uncompleted StoreKit transaction is replayed forever.
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
  }

  /// Fire and forget: the receipt check is for the server's benefit and must
  /// never hold up, or fail, the purchase the player just made.
  void _reportReceipt(PurchaseDetails purchase) {
    final report = onPlusReceipt;
    if (report == null || defaultTargetPlatform != TargetPlatform.android) return;
    final token = purchase.verificationData.serverVerificationData;
    if (token.isEmpty) return;
    unawaited(report(purchase.productID, token).catchError((Object e) {
      debugPrint('⚠️ Receipt report failed: $e');
    }));
  }

  bool _isPlus(PurchaseDetails purchase) =>
      _plusProductIds.contains(purchase.productID);

  /// The pass this purchase is for, or null when it is not a pass at all.
  String? _passIdFor(PurchaseDetails purchase) {
    for (final pass in seasonPasses) {
      if (pass.productId == purchase.productID) return pass.id;
    }
    return null;
  }

  /// The coin pack a store product id sells, or null when it sells something
  /// else. By product id rather than by pack id, because this is the direction
  /// the store asks in — it reports what was bought, and the catalogue is what
  /// knows how many coins that is.
  CoinPack? _coinPackFor(String productId) {
    for (final pack in coinPacks) {
      if (pack.productId == productId) return pack;
    }
    return null;
  }

  void dispose() {
    _subscription?.cancel();
    _entitlementController.close();
    _passController.close();
    _coinController.close();
  }
}
