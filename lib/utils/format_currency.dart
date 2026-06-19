const Map<String, String> kCurrencySymbols = {
  'GBP': '£',
  'USD': '\$',
  'EUR': '€',
  'JPY': '¥',
  'CNY': '¥',
  'INR': '₹',
  'CHF': '₣',
  'AUD': 'A\$',
  'CAD': 'C\$',
};

 String formatCurrency(num value, String? isoCode) {
    final isNegative = value < 0;
    final abs = value.abs();
    String formatted;
    String symbol='';
    if (abs >= 1000000) {
      formatted = '${(abs / 1000000).toStringAsFixed(2)}M';
    } else if (abs >= 1000) {
      formatted = '${(abs / 1000).toStringAsFixed(1)}K';
    } else {
      formatted = abs.toStringAsFixed(2);
    }
    symbol=kCurrencySymbols[isoCode] ?? '\$'  ;

    return '${isNegative ? '-' : ''}$symbol$formatted';
  }
