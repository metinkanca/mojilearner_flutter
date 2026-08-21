import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../constants/shop.dart';
import '../providers/user_provider.dart';
import '../providers/character_provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/fonts.dart';
import '../utils/shop_item_localizer.dart';
import '../utils/rtl_locale.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';
  bool _hideOwnedCosmetics = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ShopItem> _getFilteredItems() {
    final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
    var items = _selectedCategory == 'all' 
        ? shopItems 
        : shopItems.where((item) => item.type == _selectedCategory).toList();
    
    if (_hideOwnedCosmetics) {
      items = items.where((item) => 
        item.type == 'food' || !characterProvider.unlockedItems.contains(item.id)
      ).toList();
    }
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final characterProvider = Provider.of<CharacterProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);
    
    final fontFunction = settingsProvider.usePixelFont
      ? AppFonts.pressStart2p
      : AppFonts.spaceMono;

    final filteredItems = _getFilteredItems();

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      appBar: AppBar(
        title: Text(
          l10n.shopTitle.toUpperCase(),
          textDirection: textDirection,
          textAlign: TextAlign.center,
          style: fontFunction(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.retroDark,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.retroDark, width: 3),
            boxShadow: const [
              BoxShadow(
                color: AppTheme.retroDark,
                offset: Offset(2, 2),
                blurRadius: 0,
              )
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.retroDark, size: 20),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            padding: EdgeInsets.zero,
            // No round ink ripple inside the square retro frame.
            style: const ButtonStyle(
              overlayColor: WidgetStatePropertyAll(Colors.transparent),
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.retroAccent,
              border: Border.all(color: AppTheme.retroDark, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: AppTheme.retroDark,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: AppTheme.retroDark, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${userProvider.coins}',
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  style: fontFunction(
                    fontSize: 10,
                    color: AppTheme.retroDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Tabs
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.retroDark, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: AppTheme.retroDark,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                )
              ],
            ),
            child: Row(
              children: [
                _buildCategoryTab(l10n.categoryAll, 'all', fontFunction),
                _buildCategoryTab(l10n.categoryFood, 'food', fontFunction),
                _buildCategoryTab(l10n.categoryDecor, 'background', fontFunction),
                _buildCategoryTab(l10n.categoryStyle, 'accessory', fontFunction,
                    isLast: true),
              ],
            ),
          ),

          // Hide Owned Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _hideOwnedCosmetics = !_hideOwnedCosmetics;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _hideOwnedCosmetics ? AppTheme.retroAccent : Colors.white,
                  border: Border.all(color: AppTheme.retroDark, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: AppTheme.retroDark,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _hideOwnedCosmetics ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.retroDark,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.hideOwnedCosmetics.toUpperCase(),
                      textDirection: textDirection,
                      textAlign: textAlign,
                      style: fontFunction(
                        fontSize: 8,
                        color: AppTheme.retroDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Items Grid
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Text(
                      l10n.noItems.toUpperCase(),
                      textDirection: textDirection,
                      textAlign: TextAlign.center,
                      style: fontFunction(
                        fontSize: 12,
                        color: AppTheme.retroDark,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isOwned = item.type != 'food' && characterProvider.unlockedItems.contains(item.id);
                      final canAfford = userProvider.coins >= item.price;

                      return GestureDetector(
                        onTap: () => _showPurchaseDialog(
                          context,
                          item,
                          isOwned,
                          canAfford,
                          fontFunction,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isOwned
                                ? Colors.grey[300]
                                : (canAfford ? Colors.white : Colors.grey[200]),
                            border: Border.all(
                              color: AppTheme.retroDark,
                              width: 4,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppTheme.retroDark,
                                offset: Offset(4, 4),
                                blurRadius: 0,
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon
                              Text(
                                item.icon,
                                style: const TextStyle(fontSize: 48),
                              ),
                              const SizedBox(height: 12),
                              
                              // Name
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  ShopItemLocalizer.localizedName(l10n, item)
                                      .toUpperCase(),
                                  textDirection: textDirection,
                                  textAlign: TextAlign.center,
                                  style: fontFunction(
                                    fontSize: 10,
                                    color: AppTheme.retroDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Price or Status
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isOwned
                                      ? AppTheme.retroGreen
                                      : (canAfford
                                          ? AppTheme.retroAccent
                                          : AppTheme.retroPrimary),
                                  border: Border.all(
                                    color: AppTheme.retroDark,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  isOwned
                                      ? l10n.owned.toUpperCase()
                                      : '${item.price} 🪙',
                                  textDirection: isOwned
                                      ? textDirection
                                      : TextDirection.ltr,
                                  textAlign: isOwned ? textAlign : TextAlign.left,
                                  style: fontFunction(
                                    fontSize: 8,
                                    color: isOwned ? Colors.white : AppTheme.retroDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// [isLast] drops the right-hand divider. Passed in rather than compared
  /// against a category name, which is how adding the style tab left the
  /// divider stranded in the middle of the row.
  Widget _buildCategoryTab(String label, String category, TextStyle Function({required double fontSize, Color? color, FontWeight? fontWeight, double? letterSpacing}) fontFunction, {bool isLast = false}) {
    final isSelected = _selectedCategory == category;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.retroAccent : Colors.white,
            border: Border(
              right: BorderSide(
                color: AppTheme.retroDark,
                width: isLast ? 0 : 3,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              textDirection: textDirection,
              textAlign: TextAlign.center,
              // Four tabs split a handset between them, and the longest
              // locales do not fit one line at that width.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: fontFunction(
                fontSize: 10,
                color: AppTheme.retroDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPurchaseDialog(
    BuildContext context,
    ShopItem item,
    bool isOwned,
    bool canAfford,
    TextStyle Function({required double fontSize, Color? color, FontWeight? fontWeight, double? letterSpacing}) fontFunction,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final currentFullness =
        (100 - Provider.of<CharacterProvider>(context, listen: false).hunger)
            .clamp(0, 100)
            .toInt();
    
    if (isOwned && item.type != 'food') {
      _showInfoDialog(context, l10n.alreadyOwned, l10n.alreadyOwnedMessage, fontFunction);
      return;
    }

    // For food items, show quantity selector
    if (item.type == 'food') {
      _showQuantityDialog(context, item, canAfford, fontFunction);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppTheme.retroDark, width: 4),
          borderRadius: BorderRadius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Item Icon
              Text(
                item.icon,
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              
              // Item Name
              Text(
                ShopItemLocalizer.localizedName(l10n, item).toUpperCase(),
                textDirection: textDirection,
                textAlign: TextAlign.center,
                style: fontFunction(
                  fontSize: 14,
                  color: AppTheme.retroDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                ShopItemLocalizer.localizedDescription(l10n, item),
                textDirection: textDirection,
                textAlign: TextAlign.center,
                style: fontFunction(
                  fontSize: 9,
                  color: AppTheme.retroDark,
                ),
              ),
              const SizedBox(height: 16),
              
              // Stats (if food)
              if (item.type == 'food') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.retroAccent.withValues(alpha: 0.3),
                    border: Border.all(color: AppTheme.retroDark, width: 2),
                  ),
                  child: Column(
                    children: [
                      if (item.hungerRestore != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🍔', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              // Shown as a gain: the care panel measures
                              // Fullness, not hunger, so "-10" here would
                              // contradict the bar it moves.
                              '+${item.hungerRestore}',
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.left,
                              style: fontFunction(
                                fontSize: 10,
                                color: AppTheme.retroDark,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      if (item.happinessRestore != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('❤️', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              '+${item.happinessRestore}',
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.left,
                              style: fontFunction(
                                fontSize: 10,
                                color: AppTheme.retroDark,
                              ),
                            ),
                          ],
                        ),
                      if (item.healthRestore != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('💊', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              '+${item.healthRestore}',
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.left,
                              style: fontFunction(
                                fontSize: 10,
                                color: AppTheme.retroDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (item.hungerRestore != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          // Without this the restore value is unreadable:
                          // you cannot judge "+10" without knowing where
                          // you start from.
                          l10n.careCurrentFullness(currentFullness),
                          textDirection: textDirection,
                          textAlign: TextAlign.center,
                          style: fontFunction(
                            fontSize: 8,
                            color: AppTheme.retroDark.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Price
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on, color: AppTheme.retroAccent, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '${item.price}',
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    style: fontFunction(
                      fontSize: 16,
                      color: AppTheme.retroDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          border: Border.all(color: AppTheme.retroDark, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.retroDark,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          l10n.cancel.toUpperCase(),
                          textDirection: textDirection,
                          textAlign: TextAlign.center,
                          style: fontFunction(
                            fontSize: 10,
                            color: AppTheme.retroDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: canAfford
                          ? () => _handlePurchase(context, item, fontFunction)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: canAfford
                              ? AppTheme.retroGreen
                              : Colors.grey[400],
                          border: Border.all(color: AppTheme.retroDark, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.retroDark,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Text(
                            canAfford ? l10n.buy.toUpperCase() : l10n.tooPoor.toUpperCase(),
                          textDirection: textDirection,
                          textAlign: TextAlign.center,
                          style: fontFunction(
                            fontSize: 10,
                            color: canAfford ? Colors.white : AppTheme.retroDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuantityDialog(
    BuildContext context,
    ShopItem item,
    bool canAfford,
    TextStyle Function({required double fontSize, Color? color, FontWeight? fontWeight, double? letterSpacing}) fontFunction,
  ) {
    int quantity = 1;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final totalPrice = item.price * quantity;
          final canAffordQuantity = userProvider.coins >= totalPrice;
          
          return Dialog(
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              side: BorderSide(color: AppTheme.retroDark, width: 4),
              borderRadius: BorderRadius.zero,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Item Icon
                  Text(
                    item.icon,
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  
                  // Item Name
                  Text(
                    ShopItemLocalizer.localizedName(l10n, item)
                        .toUpperCase(),
                    textDirection: textDirection,
                    textAlign: TextAlign.center,
                    style: fontFunction(
                      fontSize: 14,
                      color: AppTheme.retroDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    ShopItemLocalizer.localizedDescription(l10n, item),
                    textDirection: textDirection,
                    textAlign: TextAlign.center,
                    style: fontFunction(
                      fontSize: 9,
                      color: AppTheme.retroDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.retroAccent.withValues(alpha: 0.3),
                      border: Border.all(color: AppTheme.retroDark, width: 2),
                    ),
                    child: Column(
                      children: [
                        if (item.hungerRestore != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🍔', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                '-${item.hungerRestore}',
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.left,
                                style: fontFunction(
                                  fontSize: 10,
                                  color: AppTheme.retroDark,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        if (item.happinessRestore != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('❤️', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                '+${item.happinessRestore}',
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.left,
                                style: fontFunction(
                                  fontSize: 10,
                                  color: AppTheme.retroDark,
                                ),
                              ),
                            ],
                          ),
                        if (item.healthRestore != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('💊', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                '+${item.healthRestore}',
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.left,
                                style: fontFunction(
                                  fontSize: 10,
                                  color: AppTheme.retroDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Quantity Selector
                  Text(
                    l10n.quantity.toUpperCase(),
                    textDirection: textDirection,
                    textAlign: textAlign,
                    style: fontFunction(
                      fontSize: 10,
                      color: AppTheme.retroDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (quantity > 1) {
                            setDialogState(() {
                              quantity--;
                            });
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: quantity > 1 ? Colors.white : Colors.grey[300],
                            border: Border.all(color: AppTheme.retroDark, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: AppTheme.retroDark,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.remove,
                            color: quantity > 1 ? AppTheme.retroDark : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.retroAccent,
                          border: Border.all(color: AppTheme.retroDark, width: 3),
                        ),
                        child: Text(
                          '$quantity',
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          style: fontFunction(
                            fontSize: 16,
                            color: AppTheme.retroDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          if (quantity < 99) {
                            setDialogState(() {
                              quantity++;
                            });
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: quantity < 99 ? Colors.white : Colors.grey[300],
                            border: Border.all(color: AppTheme.retroDark, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: AppTheme.retroDark,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add,
                            color: quantity < 99 ? AppTheme.retroDark : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Total Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monetization_on, color: AppTheme.retroAccent, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '$totalPrice',
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        style: fontFunction(
                          fontSize: 16,
                          color: canAffordQuantity ? AppTheme.retroDark : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (!canAffordQuantity) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.notEnoughCoins.toUpperCase(),
                      textDirection: textDirection,
                      textAlign: textAlign,
                      style: fontFunction(
                        fontSize: 8,
                        color: Colors.red,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              border: Border.all(color: AppTheme.retroDark, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppTheme.retroDark,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Text(
                            l10n.cancel.toUpperCase(),
                              textDirection: textDirection,
                              textAlign: TextAlign.center,
                              style: fontFunction(
                                fontSize: 10,
                                color: AppTheme.retroDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: canAffordQuantity
                              ? () => _handlePurchase(context, item, fontFunction, quantity: quantity)
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: canAffordQuantity
                                  ? AppTheme.retroGreen
                                  : Colors.grey[400],
                              border: Border.all(color: AppTheme.retroDark, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppTheme.retroDark,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              canAffordQuantity ? l10n.buy.toUpperCase() : l10n.tooPoor.toUpperCase(),
                              textDirection: textDirection,
                              textAlign: TextAlign.center,
                              style: fontFunction(
                                fontSize: 10,
                                color: canAffordQuantity ? Colors.white : AppTheme.retroDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handlePurchase(
    BuildContext context,
    ShopItem item,
    TextStyle Function({required double fontSize, Color? color, FontWeight? fontWeight, double? letterSpacing}) fontFunction,
    {int quantity = 1}
  ) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);
    final localizedItemName = ShopItemLocalizer.localizedName(l10n, item);

    final success = await characterProvider.purchaseItem(item, userProvider, quantity: quantity);
    if (!context.mounted) return;

    if (success) {
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            quantity > 1
                ? l10n.purchaseSuccessMultiple(localizedItemName, quantity)
                : l10n.purchaseSuccessSingle(localizedItemName),
            textDirection: textDirection,
            textAlign: textAlign,
            style: fontFunction(fontSize: 10, color: Colors.white),
          ),
          backgroundColor: AppTheme.retroGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      Navigator.pop(context);
      _showInfoDialog(
        context,
        l10n.purchaseFailed,
        l10n.notEnoughCoinsMessage,
        fontFunction,
      );
    }
  }

  void _showInfoDialog(
    BuildContext context,
    String title,
    String message,
    TextStyle Function({required double fontSize, Color? color, FontWeight? fontWeight, double? letterSpacing}) fontFunction,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppTheme.retroDark, width: 4),
          borderRadius: BorderRadius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(),
                textDirection: textDirection,
                textAlign: TextAlign.center,
                style: fontFunction(
                  fontSize: 14,
                  color: AppTheme.retroDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textDirection: textDirection,
                textAlign: TextAlign.center,
                style: fontFunction(
                  fontSize: 10,
                  color: AppTheme.retroDark,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.retroPrimary,
                    border: Border.all(color: AppTheme.retroDark, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: AppTheme.retroDark,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    l10n.ok.toUpperCase(),
                    textDirection: textDirection,
                    textAlign: TextAlign.center,
                    style: fontFunction(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
