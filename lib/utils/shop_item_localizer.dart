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
      case 'medicine':
        return l10n.shopItemMedicineName;
      case 'bg_blue':
        return l10n.shopItemBgBlueName;
      case 'bg_forest':
        return l10n.shopItemBgForestName;
      case 'bg_sunset':
        return l10n.shopItemBgSunsetName;
      case 'bg_galaxy':
        return l10n.shopItemBgGalaxyName;
      case 'cap':
        return l10n.accessoryCapName;
      case 'tophat':
        return l10n.accessoryTopHatName;
      case 'cowboyhat':
        return l10n.accessoryCowboyHatName;
      case 'crown':
        return l10n.accessoryCrownName;
      case 'partyhat':
        return l10n.accessoryPartyHatName;
      case 'bowtie':
        return l10n.accessoryBowTieName;
      case 'necklace':
        return l10n.accessoryNecklaceName;
      case 'mustache':
        return l10n.accessoryMustacheName;
      case 'beanie':
        return l10n.accessoryBeanieName;
      case 'collar':
        return l10n.accessoryCollarName;
      case 'glasses':
        return l10n.accessoryGlassesName;
      case 'sunglasses':
        return l10n.accessorySunglassesName;
      case 'mask':
        return l10n.accessoryMaskName;
      case 'scarf':
        return l10n.accessoryScarfName;
      case 'headphones':
        return l10n.accessoryHeadphonesName;
      case 'wizardhat':
        return l10n.accessoryWizardHatName;
      case 'flowercrown':
        return l10n.accessoryFlowerCrownName;
      case 'devilhorns':
        return l10n.accessoryDevilHornsName;
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
      case 'medicine':
        return l10n.shopItemMedicineDescription;
      case 'bg_blue':
        return l10n.shopItemBgBlueDescription;
      case 'bg_forest':
        return l10n.shopItemBgForestDescription;
      case 'bg_sunset':
        return l10n.shopItemBgSunsetDescription;
      case 'bg_galaxy':
        return l10n.shopItemBgGalaxyDescription;
      // Accessories share one line — they are chosen by how they look on the
      // pet, and eight variations on "a nice hat" would say nothing.
      default:
        return item.type == 'accessory'
            ? l10n.accessoryDescription
            : item.description;
    }
  }
}
