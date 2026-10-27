import 'package:flutter/material.dart';

enum TvProviderId { dstv, gotv, startimes }

extension TvProviderIdX on TvProviderId {
  /// VTPass serviceID.
  String get serviceID => switch (this) {
        TvProviderId.dstv => 'dstv',
        TvProviderId.gotv => 'gotv',
        TvProviderId.startimes => 'startimes',
      };
}

/// A bouquet as returned by the backend (prices are live from VTPass).
class TvPackage {
  const TvPackage({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    this.channels = '',
    this.popular = false,
  });

  /// VTPass variation_code.
  final String id;
  final String name;
  final String channels;

  /// Price in naira for one month.
  final int monthlyPrice;
  final bool popular;

  int priceFor(int months) => monthlyPrice * months;

  /// "DStv Compact N19,000" → "Compact"; "Classic - 5300 Naira" → "Classic".
  static String cleanName(String raw, String providerName) {
    var n = raw.trim();
    // StarTimes: "Nova - 900 Naira - 1 Month" → "Nova · 1 Month"
    n = n.replaceAll(
      RegExp(r'\s*-\s*(N|₦)?[\d,]+(\.\d+)?\s*Naira\s*-\s*', caseSensitive: false),
      ' · ',
    );
    // Trailing price, only when marked as money so "French 11" / "E36" survive:
    // "DStv Compact N19,000", "Showmax Standalone - N3,500", "Classic - 5300 Naira"
    n = n.replaceAll(RegExp(r'\s*[-–:]?\s*(N|₦|NGN)\s?\d[\d,]*(\.\d+)?\s*$'), '');
    n = n.replaceAll(RegExp(r'\s*[-–:]?\s*\d[\d,]*(\.\d+)?\s*Naira\s*$', caseSensitive: false), '');
    n = n.replaceFirst(RegExp('^${RegExp.escape(providerName)}\\s+', caseSensitive: false), '');
    n = n.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return n.isEmpty ? raw.trim() : n;
  }

  factory TvPackage.fromJson(Map<String, dynamic> j, {required String providerName}) => TvPackage(
        id: j['code'] as String,
        name: cleanName((j['name'] ?? j['code']).toString(), providerName),
        monthlyPrice: (j['amount'] as num).round(),
      );

  TvPackage copyWith({bool? popular}) =>
      TvPackage(id: id, name: name, monthlyPrice: monthlyPrice, channels: channels, popular: popular ?? this.popular);
}

class TvProvider {
  const TvProvider({
    required this.id,
    required this.name,
    required this.shortName,
    required this.color,
    required this.idLabel,
    required this.idLength,
    required this.supportsMonths,
    this.italicWordmark = true,
    this.accentDot,
  });

  final TvProviderId id;
  final String name;
  final String shortName;
  final Color color;

  /// "Smartcard number" or "IUC number".
  final String idLabel;

  /// Usual length of the number; verification starts automatically at this length.
  final int idLength;

  /// DStv and GOtv can be paid for several months at once; StarTimes cannot.
  final bool supportsMonths;
  final bool italicWordmark;
  final Color? accentDot;

  String get serviceID => id.serviceID;
}

enum PaymentMethod { wallet }

extension PaymentMethodX on PaymentMethod {
  String get title => 'Paypoint wallet';
  IconData get icon => Icons.account_balance_wallet_outlined;
}

/// The signed-in user, as returned by /api/auth/me.
class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.balance,
    required this.hasPin,
  });

  final String id;
  final String fullName;
  final String phone;
  final String email;
  final double balance;
  final bool hasPin;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        fullName: (j['fullName'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        balance: (j['balance'] as num? ?? 0).toDouble(),
        hasPin: j['hasPin'] == true,
      );

  AppUser copyWith({double? balance, bool? hasPin}) => AppUser(
        id: id,
        fullName: fullName,
        phone: phone,
        email: email,
        balance: balance ?? this.balance,
        hasPin: hasPin ?? this.hasPin,
      );
}

/// Result of verifying a smartcard / IUC number with the provider.
class CustomerLookup {
  const CustomerLookup({
    required this.accountName,
    this.currentBouquet,
    this.currentBouquetCode,
    this.dueDate,
    this.renewalAmount,
    this.status,
  });

  final String accountName;
  final String? currentBouquet;
  final String? currentBouquetCode;
  final DateTime? dueDate;
  final num? renewalAmount;
  final String? status;

  factory CustomerLookup.fromJson(Map<String, dynamic> j) => CustomerLookup(
        accountName: (j['customerName'] ?? '').toString(),
        currentBouquet: j['currentBouquet']?.toString(),
        currentBouquetCode: j['currentBouquetCode']?.toString(),
        dueDate: DateTime.tryParse((j['dueDate'] ?? '').toString()),
        renewalAmount: j['renewalAmount'] as num?,
        status: j['status']?.toString(),
      );
}

enum TxStatus { pending, success, failed }

TxStatus _status(Object? s) => switch (s) {
      'success' => TxStatus.success,
      'failed' => TxStatus.failed,
      _ => TxStatus.pending,
    };

/// A cable TV payment.
class TvTransaction {
  const TvTransaction({
    required this.id,
    required this.reference,
    required this.provider,
    required this.package,
    required this.months,
    required this.amount,
    required this.smartcard,
    required this.accountName,
    required this.date,
    required this.status,
    this.message,
    this.refunded = false,
  });

  final String id;
  final String reference;
  final TvProvider provider;
  final TvPackage package;
  final int months;
  final int amount;
  final String smartcard;
  final String accountName;
  final DateTime date;
  final TxStatus status;
  final String? message;
  final bool refunded;

  PaymentMethod get method => PaymentMethod.wallet;
  bool get success => status == TxStatus.success;
  bool get pending => status == TxStatus.pending;
  bool get failed => status == TxStatus.failed;

  /// Estimated end of the subscription period (30 days per month paid).
  DateTime get activeUntil => date.add(Duration(days: 30 * months));

  /// Returns null for unknown providers (should not happen).
  static TvTransaction? fromJson(Map<String, dynamic> j, TvProvider? Function(String?) providerFor) {
    final provider = providerFor(j['serviceID'] as String?);
    if (provider == null) return null;
    final months = (j['months'] as num? ?? 1).toInt();
    final amount = (j['amount'] as num? ?? 0).round();
    final fee = (j['fee'] as num? ?? 0).round();
    return TvTransaction(
      id: j['id'] as String,
      reference: (j['reference'] ?? j['id']).toString(),
      provider: provider,
      package: TvPackage(
        id: (j['variationCode'] ?? '').toString(),
        name: TvPackage.cleanName((j['packageName'] ?? '').toString(), provider.name),
        monthlyPrice: months > 0 ? ((amount - fee) / months).round() : amount,
      ),
      months: months,
      amount: amount,
      smartcard: (j['billersCode'] ?? '').toString(),
      accountName: (j['customerName'] ?? '').toString(),
      date: DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal() ?? DateTime.now(),
      status: _status(j['status']),
      message: j['message'] as String?,
      refunded: j['refunded'] == true,
    );
  }
}

/// A wallet top-up.
class FundingTransaction {
  const FundingTransaction({
    required this.id,
    required this.reference,
    required this.amount,
    required this.date,
    required this.status,
    required this.channel,
  });

  final String id;
  final String reference;
  final int amount;
  final DateTime date;
  final TxStatus status;
  final String channel;

  factory FundingTransaction.fromJson(Map<String, dynamic> j) => FundingTransaction(
        id: j['id'] as String,
        reference: (j['reference'] ?? j['id']).toString(),
        amount: (j['amount'] as num? ?? 0).round(),
        date: DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal() ?? DateTime.now(),
        status: _status(j['status']),
        channel: (j['channel'] ?? 'paystack').toString(),
      );
}

/// A decoder the user has paid for before (derived from history).
class SavedDecoder {
  const SavedDecoder({
    required this.nickname,
    required this.provider,
    required this.number,
    required this.accountName,
    required this.package,
    required this.expiresOn,
  });

  final String nickname;
  final TvProvider provider;
  final String number;
  final String accountName;
  final TvPackage package;
  final DateTime expiresOn;

  int daysLeft([DateTime? now]) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final end = DateTime(expiresOn.year, expiresOn.month, expiresOn.day);
    return end.difference(today).inDays;
  }
}
