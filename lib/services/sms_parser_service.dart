import '../models/transaction.dart';
import 'package:uuid/uuid.dart';

class SMSParserService {
  static final uuid = Uuid();

  /// UAE-specific patterns for transaction detection
  static final Map<String, List<RegExp>> _categoryPatterns = {
    // NEEDS (40% CAP)
    'housing': [
      RegExp(r'rent|EMI|Bayut|Noor Bank|mortgage|property', caseSensitive: false),
    ],
    'groceries': [
      RegExp(r'Lulu|Carrefour|Spinneys|Union Coop|Al Maya|Choithrams|supermarket|grocery', caseSensitive: false),
    ],
    'utilities': [
      RegExp(r'DEWA|Etisalat|du|ADDC|water|electricity|gas|telecom|internet', caseSensitive: false),
    ],
    'transport': [
      RegExp(r'Salik|Careem|Uber|taxi|ADNOC|fuel|petrol|ENOC|parking|RTA', caseSensitive: false),
    ],
    'medical': [
      RegExp(r'Thiqa|insurance|pharmacy|Medi|clinic|hospital|doctor|health', caseSensitive: false),
    ],
    'insurance': [
      RegExp(r'AXA|Oman Insurance|home insurance|car insurance|life insurance', caseSensitive: false),
    ],

    // WANTS (20% CAP)
    'dining': [
      RegExp(r'Talabat|Zomato|Noon Food|Deliveroo|restaurant|cafe|coffee|food|McDonald|KFC|Subway', caseSensitive: false),
    ],
    'entertainment': [
      RegExp(r'Vox|Reel|cinema|VOX Cinemas|IMG Worlds|Ferrari World|Yas|Atlantis|theme park|movie', caseSensitive: false),
    ],
    'shopping': [
      RegExp(r'Noon|Amazon\.ae|Mall of Emirates|Dubai Mall|Dragon Mart|Sharaf DG|Carrefour|H&M|Zara|shopping', caseSensitive: false),
    ],
    'subscriptions': [
      RegExp(r'Netflix|Shahid|gym|ClassPass|OSN|beIN|Spotify|Prime|subscription', caseSensitive: false),
    ],
    'travel': [
      RegExp(r'flydubai|Emirates|AirArabia|hotel|resort|booking|Airbnb|flight|airline', caseSensitive: false),
    ],

    // SAVINGS/INVEST (40% MIN)
    'income': [
      RegExp(r'salary|credited|refund|bonus|transfer received|deposit|payment received', caseSensitive: false),
    ],
    'investments': [
      RegExp(r'Sukuk|stocks|FAB saver|Mashreq|dividend|investment|mutual fund', caseSensitive: false),
    ],
  };

  /// Amount patterns for different currencies
  static final List<RegExp> _amountPatterns = [
    RegExp(r'AED\s*(\d+[\.,]?\d*)', caseSensitive: false),
    RegExp(r'\$\s*(\d+[\.,]?\d*)'),
    RegExp(r'د\.إ\s*(\d+[\.,]?\d*)'),
    RegExp(r'(\d+[\.,]?\d*)\s*AED', caseSensitive: false),
    RegExp(r'(\d+[\.,]?\d*)\s*dirham', caseSensitive: false),
  ];

  /// Income/Expense detection patterns
  static final List<RegExp> _incomePatterns = [
    RegExp(r'credited|salary|refund|transfer received|deposit|payment received|bonus', caseSensitive: false),
  ];

  static final List<RegExp> _expensePatterns = [
    RegExp(r'debit|paid|purchased|withdrawn|spent|charged|payment to', caseSensitive: false),
  ];

  /// Parse SMS message and extract transaction
  static Transaction? parseSMS(String smsText, String sender, DateTime date) {
    try {
      // Extract amount
      double? amount = _extractAmount(smsText);
      if (amount == null) return null;

      // Detect if income or expense
      bool? isIncome = _detectTransactionType(smsText);
      if (isIncome == null) return null;

      // Make amount negative if expense
      if (!isIncome) {
        amount = -amount;
      }

      // Extract merchant
      String merchant = _extractMerchant(smsText);

      // Auto-categorize
      TransactionCategory category = _categorizeTransaction(smsText, merchant);

      // Create transaction
      return Transaction(
        id: uuid.v4(),
        date: date,
        amount: amount,
        description: _cleanDescription(smsText),
        merchant: merchant,
        rawText: smsText,
        category: category,
        confirmed: false,
        isIncome: isIncome,
      );
    } catch (e) {
      print('Error parsing SMS: $e');
      return null;
    }
  }

  /// Extract amount from SMS text
  static double? _extractAmount(String text) {
    for (var pattern in _amountPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String amountStr = match.group(1) ?? match.group(0) ?? '';
        amountStr = amountStr.replaceAll(RegExp(r'[^\d.]'), '');
        return double.tryParse(amountStr);
      }
    }
    return null;
  }

  /// Detect if transaction is income or expense
  static bool? _detectTransactionType(String text) {
    // Check for income patterns
    for (var pattern in _incomePatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }

    // Check for expense patterns
    for (var pattern in _expensePatterns) {
      if (pattern.hasMatch(text)) {
        return false;
      }
    }

    return null; // Uncertain
  }

  /// Extract merchant name from SMS
  static String _extractMerchant(String text) {
    // Try to find merchant name between "at" and amount or other keywords
    final merchantPattern = RegExp(r'(?:at|from|to)\s+([A-Z][A-Za-z\s&]+?)(?:\s+for|\s+AED|\s+on|\.|$)', caseSensitive: false);
    final match = merchantPattern.firstMatch(text);
    
    if (match != null && match.group(1) != null) {
      return match.group(1)!.trim();
    }

    // Fallback: check for known merchants in the text
    for (var categoryPatterns in _categoryPatterns.values) {
      for (var pattern in categoryPatterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          return match.group(0) ?? 'Unknown';
        }
      }
    }

    return 'Unknown';
  }

  /// Auto-categorize transaction based on patterns
  static TransactionCategory _categorizeTransaction(String text, String merchant) {
    // First check if this is income
    for (var pattern in _incomePatterns) {
      if (pattern.hasMatch(text)) {
        return TransactionCategory.income;
      }
    }

    // Check each category pattern
    for (var entry in _categoryPatterns.entries) {
      for (var pattern in entry.value) {
        if (pattern.hasMatch(text) || pattern.hasMatch(merchant)) {
          return _stringToCategory(entry.key);
        }
      }
    }

    return TransactionCategory.uncategorized;
  }

  /// Convert category string to enum
  static TransactionCategory _stringToCategory(String categoryStr) {
    switch (categoryStr.toLowerCase()) {
      case 'housing':
        return TransactionCategory.housing;
      case 'groceries':
        return TransactionCategory.groceries;
      case 'utilities':
        return TransactionCategory.utilities;
      case 'transport':
        return TransactionCategory.transport;
      case 'medical':
        return TransactionCategory.medical;
      case 'insurance':
        return TransactionCategory.insurance;
      case 'dining':
        return TransactionCategory.dining;
      case 'entertainment':
        return TransactionCategory.entertainment;
      case 'shopping':
        return TransactionCategory.shopping;
      case 'subscriptions':
        return TransactionCategory.subscriptions;
      case 'travel':
        return TransactionCategory.travel;
      case 'income':
        return TransactionCategory.income;
      case 'investments':
        return TransactionCategory.investments;
      default:
        return TransactionCategory.uncategorized;
    }
  }

  /// Clean and shorten description
  static String _cleanDescription(String text) {
    // Remove extra whitespace and newlines
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Limit to 100 characters
    if (text.length > 100) {
      text = text.substring(0, 97) + '...';
    }
    
    return text;
  }
}
