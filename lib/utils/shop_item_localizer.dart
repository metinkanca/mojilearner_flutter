import '../constants/shop.dart';
import '../l10n/app_localizations.dart';

class ShopItemLocalizer {
  static String localizedName(AppLocalizations l10n, ShopItem item) {
    switch (item.id) {
      case 'apple':
        return l10n.shopItemAppleName;
      case 'croissant':
        return l10n.shopItemCroissantName;
      case 'pizza':
        return l10n.shopItemPizzaName;
      case 'sushi':
        return l10n.shopItemSushiName;
      case 'coffee':
        return l10n.shopItemCoffeeName;
      case 'bg_blue':
        return l10n.shopItemBgBlueName;
      case 'bg_forest':
        return l10n.shopItemBgForestName;
      case 'bg_sunset':
        return l10n.shopItemBgSunsetName;
      case 'bg_galaxy':
        return l10n.shopItemBgGalaxyName;
      default:
        return item.name;
    }
  }

  static String localizedDescription(AppLocalizations l10n, ShopItem item) {
    switch (item.id) {
      case 'apple':
        return l10n.shopItemAppleDescription;
      case 'croissant':
        return l10n.shopItemCroissantDescription;
      case 'pizza':
        return l10n.shopItemPizzaDescription;
      case 'sushi':
        return l10n.shopItemSushiDescription;
      case 'coffee':
        return l10n.shopItemCoffeeDescription;
      case 'bg_blue':
        return l10n.shopItemBgBlueDescription;
      case 'bg_forest':
        return l10n.shopItemBgForestDescription;
      case 'bg_sunset':
        return l10n.shopItemBgSunsetDescription;
      case 'bg_galaxy':
        return l10n.shopItemBgGalaxyDescription;
      default:
        return item.description;
    }
  }
}
