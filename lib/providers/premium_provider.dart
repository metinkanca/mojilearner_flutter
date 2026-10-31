import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../constants/coin_packs.dart';
import '../services/ai_service.dart';
import '../services/purchase_service.dart';
import 'user_provider.dart';

/// Owns the store connection for the life of the app, and keeps
/// [UserProvider.isPremium] and the owned season passes in step with it.
///
/// Named for Plus but it is really *the store*: there can only be one listener
/// on `in_app_purchase`'s purchase stream, so a second provider for the season
/// pass or for coin packs would either miss purchases or fight this one for
/// them. All three products therefore come through here.
///
/// Deliberately not owned by the paywall screen. Both stores can deliver a
/// purchase long after the screen that started it has gone — the player
/// backgrounds the app during the payment sheet, or Play finishes a deferred
/// purchase hours later — and a listener that lives on a route would miss it
/// and leave someone who paid without the thing they bought.
class PremiumProvider extends ChangeNotifier {
  PremiumProvider({PurchaseService? service})
      : _service = service ?? PurchaseService();

  final PurchaseService _service;

  UserProvider? _user;
  StreamSubscription<bool>? _entitlement;
  StreamSubscription<String>? _passes;
  StreamSubscription<CoinPack>? _coins;
  bool _loading = false;
  bool _restoring = false;

  /// Whether anything can actually be bought right now: the store answered,
  /// and this build has product ids configured.
  bool get isAvailable => _service.isAvailable;

  /// The plans on offer, monthly first.
  List<ProductDetails> get products => _service.products;

  bool get isPurchasePending => _service.isPurchasePending;

  /// The store's listing for a pass, or null when there is none to sell.
  ProductDetails? passProduct(String passId) => _service.passProduct(passId);

  /// Whether this pass can actually be bought right now.
  bool isPassAvailable(String passId) =>
      _service.isAvailable && _service.passProduct(passId) != null;

  /// The store's listing for a coin pack, or null when there is none to sell.
  ProductDetails? coinPackProduct(String packId) =>
      _service.coinPackProduct(packId);

  /// Whether this pack can actually be bought right now.
  bool isCoinPackAvailable(String packId) =>
      _service.isAvailable && _service.coinPackProduct(packId) != null;

  /// True while a restore is in flight, so the button can say so rather than
  /// looking like it did nothing.
  bool get isRestoring => _restoring;

  /// Attaches the provider that actually holds the entitlement.
  ///
  /// Called by the proxy provider on every rebuild, so it has to be cheap and
  /// idempotent — the store is only connected once, on the first attachment.
  void attach(UserProvider user) {
    _user = user;
    if (_loading) return;
    _loading = true;

    _entitlement ??= _service.onEntitlementChanged.listen((active) async {
      // The local flag is a cache of what the store said, never the authority.
      // What has to gate a model call is the proxy against a receipt it
      // verified itself — see `services/purchase_service.dart`.
      await _user?.setPremium(active);
      notifyListeners();
    });

    // A pass is only ever gained, so unlike the entitlement above there is no
    // false case to handle. `grantPass` is idempotent, so a store replaying a
    // restore cannot reset the XP baseline and take back a player's progress.
    _passes ??= _service.onPassPurchased.listen((passId) async {
      await _user?.grantPass(passId);
      notifyListeners();
    });

    // Coins are granted here rather than by the top-up screen, for the reason
    // in this class's doc comment: a deferred purchase can land hours after
    // that screen is gone, and coins that were paid for must arrive anyway.
    _coins ??= _service.onCoinsPurchased.listen((pack) async {
      await _user?.addCoins(pack.coins);
      _lastCoinsGranted = pack.coins;
      notifyListeners();
    });

    // The proxy gives the member allowance only to accounts whose receipt it
    // checked with Google, so every Plus purchase and restore is reported to it.
    _service.onPlusReceipt ??= (productId, token) async {
      await AiService.instance
          .verifyPurchase(productId: productId, purchaseToken: token);
    };

    unawaited(_service.load().then((_) async {
      // A member is re-checked on every launch: the server only remembers a
      // subscription until its expiry (and forgets on restart), so this is what
      // keeps a renewed subscription current and lets a lapsed one end. Android
      // only, since an Apple restore can interrupt with a password prompt.
      if (_user?.isPremium == true &&
          defaultTargetPlatform == TargetPlatform.android) {
        await _service.restore(revokeIfLapsed: true);
      }
      notifyListeners();
    }));
  }

  Future<void> buy(ProductDetails product) async {
    await _service.buy(product);
    notifyListeners();
  }

  /// Starts the purchase for a pass. Does nothing when there is no listing,
  /// which is the state until the store console has one.
  Future<void> buyPass(String passId) async {
    final product = _service.passProduct(passId);
    if (product == null) return;
    await _service.buy(product);
    notifyListeners();
  }

  /// Starts the purchase for a coin pack. Does nothing when there is no
  /// listing, which is the state until the store console has one.
  Future<void> buyCoinPack(String packId) async {
    final product = _service.coinPackProduct(packId);
    if (product == null) return;
    await _service.buy(product);
    notifyListeners();
  }

  /// Coins from the most recent top-up, or null when none has landed since it
  /// was last read.
  ///
  /// Read-and-clear rather than a plain getter: the top-up screen thanks the
  /// player for a purchase, and a value that stayed set would thank them again
  /// on every rebuild — and again on the next visit to the screen.
  int? takeCoinsGranted() {
    final granted = _lastCoinsGranted;
    _lastCoinsGranted = null;
    return granted;
  }

  int? _lastCoinsGranted;

  /// Asks the store what this account already owns.
  ///
  /// Returns whether anything came back, so the screen can tell a player with
  /// nothing to restore that the button worked and found nothing — which is a
  /// different message from silence.
  Future<bool> restore() async {
    if (_restoring) return false;
    _restoring = true;
    notifyListeners();

    final before = _user?.isPremium ?? false;
    try {
      await _service.restore();
      // The store replays through the purchase stream, which is asynchronous;
      // give it a moment before reporting nothing was found.
      await Future<void>.delayed(const Duration(seconds: 2));
    } finally {
      _restoring = false;
      notifyListeners();
    }
    return (_user?.isPremium ?? false) && !before;
  }

  @override
  void dispose() {
    _entitlement?.cancel();
    _passes?.cancel();
    _coins?.cancel();
    _service.dispose();
    super.dispose();
  }
}
