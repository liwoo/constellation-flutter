/// A bundle of lives on sale
class LifePack {
  const LifePack({
    required this.id,
    required this.lives,
    required this.price,
    this.tag,
  });

  /// Store product id
  final String id;
  final int lives;

  /// Display price
  final String price;

  /// Optional callout, e.g. "BEST VALUE"
  final String? tag;
}

/// Lives shop. Purchases are SIMULATED - they always succeed after a short
/// delay and nothing is charged. Swap [buy] for a real store (e.g. the
/// in_app_purchase package) before shipping.
class StoreService {
  StoreService._();
  static final StoreService instance = StoreService._();

  /// Purchases complete instantly without a real store behind them
  static const bool isSimulated = true;

  static const lifePacks = [
    LifePack(id: 'lives_3', lives: 3, price: r'$0.99'),
    LifePack(id: 'lives_10', lives: 10, price: r'$2.99', tag: 'BEST VALUE'),
  ];

  /// Buy [pack]. Returns true once the lives are paid for.
  Future<bool> buy(LifePack pack) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return true;
  }
}
