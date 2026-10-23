import 'package:flutter_test/flutter_test.dart';
import 'package:paypoint/core/formatters.dart';
import 'package:paypoint/data/catalog.dart';
import 'package:paypoint/models/models.dart';
import 'package:paypoint/state/app_state.dart';

void main() {
  group('Fmt', () {
    test('formats naira with grouping', () {
      expect(Fmt.naira(19000), '₦ 19,000');
      expect(Fmt.naira(4400), '₦ 4,400');
      expect(Fmt.naira(1234567), '₦ 1,234,567');
      expect(Fmt.naira(24500, kobo: true), '₦ 24,500.00');
    });

    test('formats smartcard numbers', () {
      expect(Fmt.smartcard('7012345678'), '7012 3456 78');
    });

    test('initials', () {
      expect(Fmt.initials('Alusine Barrie'), 'AB');
      expect(Fmt.initials('Ada'), 'A');
    });
  });

  group('AppState pay flow', () {
    test('wallet payment deducts balance and records a transaction', () async {
      final s = AppState();
      final before = s.walletBalance;
      final txCount = s.transactions.length;

      s.startFlow(Catalog.dstv);
      s.setNumber('7012345678');
      await s.verifyCustomer();
      s.setPackage(Catalog.dstv.packages.first); // Padi
      s.setMonths(1);
      s.setMethod(PaymentMethod.wallet);

      final tx = await s.pay('1234');

      expect(tx.amount, Catalog.dstv.packages.first.monthlyPrice);
      expect(s.walletBalance, before - tx.amount);
      expect(s.transactions.length, txCount + 1);
      expect(tx.reference, startsWith('PP-'));
    });

    test('package price scales with months', () {
      final pkg = Catalog.gotv.packages.first;
      expect(pkg.priceFor(3), pkg.monthlyPrice * 3);
    });
  });
}
