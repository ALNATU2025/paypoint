import 'dart:math';

import '../data/catalog.dart';
import '../models/models.dart';

/// Result of looking up a decoder with the provider.
class CustomerLookup {
  const CustomerLookup({
    required this.accountName,
    required this.currentPackage,
    required this.dueDate,
  });

  final String accountName;
  final TvPackage currentPackage;
  final DateTime dueDate;
}

class BillingException implements Exception {
  BillingException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The contract the UI talks to. Swap [MockBillingService] for a real
/// implementation that calls your bill-payment aggregator / backend.
abstract class BillingService {
  Future<CustomerLookup> verifyCustomer(TvProvider provider, String number);
  Future<List<TvPackage>> fetchPackages(TvProvider provider);
  Future<String> pay({
    required TvProvider provider,
    required String number,
    required TvPackage package,
    required int months,
    required PaymentMethod method,
    required String pin,
  });
}

class MockBillingService implements BillingService {
  MockBillingService({this.accountNameForLookup = 'PAYPOINT CUSTOMER'});

  String accountNameForLookup;
  final _rand = Random();

  @override
  Future<CustomerLookup> verifyCustomer(TvProvider provider, String number) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.length < provider.idLength) {
      throw BillingException('Enter a valid ${provider.idLabel.toLowerCase()}.');
    }
    final pkg = provider.packages.firstWhere((p) => p.popular, orElse: () => provider.packages.first);
    return CustomerLookup(
      accountName: accountNameForLookup.toUpperCase(),
      currentPackage: pkg,
      dueDate: DateTime.now().add(const Duration(days: 3)),
    );
  }

  @override
  Future<List<TvPackage>> fetchPackages(TvProvider provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return Catalog.byId(provider.id).packages;
  }

  @override
  Future<String> pay({
    required TvProvider provider,
    required String number,
    required TvPackage package,
    required int months,
    required PaymentMethod method,
    required String pin,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (pin.length != 4) throw BillingException('Incorrect PIN.');
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final ref = List.generate(8, (_) => chars[_rand.nextInt(chars.length)]).join();
    return 'PP-$ref';
  }
}
