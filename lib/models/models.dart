import 'package:flutter/material.dart';

enum TvProviderId { dstv, gotv, startimes }

class TvPackage {
  const TvPackage({
    required this.id,
    required this.name,
    required this.channels,
    required this.monthlyPrice,
    this.popular = false,
  });

  final String id;
  final String name;
  final String channels;

  /// Price in naira for one month.
  final int monthlyPrice;
  final bool popular;

  int priceFor(int months) => monthlyPrice * months;
}

class TvProvider {
  const TvProvider({
    required this.id,
    required this.name,
    required this.shortName,
    required this.color,
    required this.idLabel,
    required this.idLength,
    required this.packages,
    this.italicWordmark = true,
    this.accentDot,
  });

  final TvProviderId id;
  final String name;
  final String shortName;
  final Color color;

  /// "Smartcard number" or "IUC number".
  final String idLabel;
  final int idLength;
  final List<TvPackage> packages;
  final bool italicWordmark;
  final Color? accentDot;
}

enum PaymentMethod { wallet, card, bank, ussd }

extension PaymentMethodX on PaymentMethod {
  String get title => switch (this) {
        PaymentMethod.wallet => 'Paypoint wallet',
        PaymentMethod.card => 'Debit card',
        PaymentMethod.bank => 'Bank transfer',
        PaymentMethod.ussd => 'USSD',
      };

  IconData get icon => switch (this) {
        PaymentMethod.wallet => Icons.account_balance_wallet_outlined,
        PaymentMethod.card => Icons.credit_card_rounded,
        PaymentMethod.bank => Icons.account_balance_outlined,
        PaymentMethod.ussd => Icons.smartphone_rounded,
      };
}

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

  SavedDecoder copyWith({TvPackage? package, DateTime? expiresOn}) => SavedDecoder(
        nickname: nickname,
        provider: provider,
        number: number,
        accountName: accountName,
        package: package ?? this.package,
        expiresOn: expiresOn ?? this.expiresOn,
      );
}

class TvTransaction {
  const TvTransaction({
    required this.reference,
    required this.provider,
    required this.package,
    required this.months,
    required this.amount,
    required this.smartcard,
    required this.accountName,
    required this.method,
    required this.date,
    required this.activeUntil,
    this.success = true,
  });

  final String reference;
  final TvProvider provider;
  final TvPackage package;
  final int months;
  final int amount;
  final String smartcard;
  final String accountName;
  final PaymentMethod method;
  final DateTime date;
  final DateTime activeUntil;
  final bool success;
}
