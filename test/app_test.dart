import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paypoint/core/formatters.dart';
import 'package:paypoint/data/catalog.dart';
import 'package:paypoint/models/models.dart';
import 'package:paypoint/services/admin_api.dart';
import 'package:paypoint/services/api_client.dart';
import 'package:paypoint/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Fmt', () {
    test('formats naira with grouping', () {
      expect(Fmt.naira(19000), '₦ 19,000');
      expect(Fmt.naira(1234567), '₦ 1,234,567');
      expect(Fmt.naira(24500, kobo: true), '₦ 24,500.00');
    });

    test('formats smartcard numbers', () {
      expect(Fmt.smartcard('7012345678'), '7012 3456 78');
    });
  });

  group('Models', () {
    test('package names from VTPass are cleaned up', () {
      expect(TvPackage.cleanName('DStv Compact N19,000', 'DStv'), 'Compact');
      expect(TvPackage.cleanName('GOtv Max N8,500', 'GOtv'), 'Max');
      expect(TvPackage.cleanName('Classic - 5300 Naira', 'StarTimes'), 'Classic');
      expect(TvPackage.cleanName('DStv Compact + Extra View', 'DStv'), 'Compact + Extra View');
      expect(TvPackage.cleanName('DStv  Compact N7900', 'DStv'), 'Compact');
      expect(TvPackage.cleanName('DStv French 11 N3,260', 'DStv'), 'French 11');
      expect(TvPackage.cleanName('DStv Asian Bouquet E36 N12,400', 'DStv'), 'Asian Bouquet E36');
      expect(TvPackage.cleanName('Showmax Standalone - N3,500', 'DStv'), 'Showmax Standalone');
      expect(TvPackage.cleanName('GOtv Lite (3 Months) N1,080', 'GOtv'), 'Lite (3 Months)');
      expect(TvPackage.cleanName('Nova - 900 Naira - 1 Month', 'StarTimes'), 'Nova · 1 Month');
      expect(TvPackage.cleanName('Classic - 1200 Naira - 1 Week ', 'StarTimes'), 'Classic · 1 Week');
    });

    test('transaction parses from the API', () {
      final tx = TvTransaction.fromJson({
        'id': 't1',
        'type': 'cable',
        'status': 'success',
        'amount': 38000,
        'fee': 0,
        'serviceID': 'dstv',
        'billersCode': '7012345678',
        'customerName': 'ADA OKAFOR',
        'variationCode': 'dstv-compact',
        'packageName': 'DStv Compact N19,000',
        'months': 2,
        'reference': '202610270905abc',
        'createdAt': '2026-10-27T08:05:00Z',
      }, Catalog.byServiceID)!;
      expect(tx.provider.id, TvProviderId.dstv);
      expect(tx.package.name, 'Compact');
      expect(tx.package.monthlyPrice, 19000);
      expect(tx.success, isTrue);
      expect(tx.activeUntil.difference(tx.date).inDays, 60);
    });
  });

  group('Admin', () {
    test('isAdmin comes from the API user', () {
      final u = AppUser.fromJson({'id': '1', 'fullName': 'A', 'email': 'payonpointng@gmail.com', 'isAdmin': true});
      expect(u.isAdmin, isTrue);
      expect(u.copyWith(balance: 5).isAdmin, isTrue);
      expect(AppUser.fromJson({'id': '2'}).isAdmin, isFalse);
    });

    test('stats parse', () {
      final st = AdminStats({
        'users': 12,
        'newUsersToday': 2,
        'walletBalances': 5000.5,
        'salesToday': {'amount': 19000, 'count': 2},
        'salesAll': {'amount': 80000, 'count': 9},
        'pending': 1,
        'failedToday': 0,
        'byProvider': {
          'dstv': {'amount': 60000, 'count': 5},
        },
        'vtpass': {'mode': 'live', 'configured': true, 'balance': null},
      });
      expect(st.users, 12);
      expect(st.salesTodayAmount, 19000);
      expect(st.byProvider['dstv'], (60000.0, 5));
      expect(st.vtpassBalance, isNull);
      expect(st.vtpassConfigured, isTrue);
    });

    test('transaction titles', () {
      expect(AdminTx({'id': '1', 'type': 'cable', 'serviceID': 'gotv', 'packageName': 'GOtv Max N8,500'}).title, 'GOtv Max');
      expect(AdminTx({'id': '2', 'type': 'funding', 'description': 'Debit: correction'}).title, 'Wallet debit');
      expect(AdminTx({'id': '3', 'type': 'funding', 'description': 'Wallet credit'}).title, 'Wallet credit');
    });
  });

  group('AppState with a fake backend', () {
    late List<http.Request> calls;

    AppState build(Map<String, dynamic> Function(http.Request r) handler) {
      calls = [];
      final client = MockClient((r) async {
        calls.add(r);
        final res = handler(r);
        final status = res.remove('_status') as int? ?? 200;
        return http.Response(jsonEncode(res), status, headers: {'content-type': 'application/json'});
      });
      return AppState(api: ApiClient(baseUrl: 'https://api.test', client: client));
    }

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('login stores the token and user', () async {
      final s = build((r) {
        if (r.url.path == '/api/auth/login') {
          return {
            'success': true,
            'data': {
              'token': 'tok',
              'user': {'id': 'u1', 'fullName': 'Ada Okafor', 'phone': '08031234567', 'balance': 5000, 'hasPin': true},
            },
          };
        }
        return {'success': true, 'data': <dynamic>[]};
      });
      await s.init();
      await s.login(email: 'ada@example.com', password: 'secret1');
      expect(jsonDecode(calls.first.body), {'email': 'ada@example.com', 'password': 'secret1'});
      expect(s.loggedIn, isTrue);
      expect(s.walletBalance, 5000);
      expect(s.api.token, 'tok');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'tok');
    });

    test('backend errors surface as readable messages', () async {
      final s = build((r) => {'_status': 401, 'success': false, 'message': 'Incorrect email or password'});
      await s.init();
      await expectLater(
        s.login(email: 'ada@example.com', password: 'x'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Incorrect email or password')),
      );
    });

    test('pay sends the VTPass fields and updates the balance', () async {
      final s = build((r) {
        if (r.url.path == '/api/cable/pay') {
          return {
            'success': true,
            'message': 'Subscription successful',
            'data': {
              'balance': 1000,
              'transaction': {
                'id': 'tx1',
                'status': 'success',
                'amount': 4400,
                'serviceID': 'dstv',
                'billersCode': '7012345678',
                'packageName': 'DStv Padi N4,400',
                'variationCode': 'dstv-padi',
                'months': 1,
                'createdAt': '2026-10-27T08:05:00Z',
              },
            },
          };
        }
        return {'success': true, 'data': <dynamic>[]};
      });
      s.user = const AppUser(id: 'u1', fullName: 'Ada', phone: '0803', email: '', balance: 5400, hasPin: true);
      s.startFlow(Catalog.dstv);
      s.setNumber('7012 3456 78');
      s.setPackage(const TvPackage(id: 'dstv-padi', name: 'Padi', monthlyPrice: 4400));

      final result = await s.pay('1234');
      final body = jsonDecode(calls.last.body) as Map<String, dynamic>;
      expect(body['serviceID'], 'dstv');
      expect(body['billersCode'], '7012345678');
      expect(body['variationCode'], 'dstv-padi');
      expect(body['pin'], '1234');
      expect(result.transaction.success, isTrue);
      expect(s.walletBalance, 1000);
      expect(s.decoders.single.number, '7012345678');
    });

    test('renewal sends mode renew without a package code', () async {
      final s = build((r) {
        if (r.url.path == '/api/cable/pay') {
          return {
            'success': true,
            'data': {
              'balance': 0,
              'transaction': {
                'id': 'tx3',
                'status': 'success',
                'amount': 7900,
                'serviceID': 'dstv',
                'billersCode': '1212121212',
                'packageName': 'DStv Compact (renewal)',
                'months': 1,
              },
            },
          };
        }
        return {'success': true, 'data': <dynamic>[]};
      });
      s.user = const AppUser(id: 'u1', fullName: 'Ada', phone: '0803', email: '', balance: 7900, hasPin: true);
      s.startFlow(Catalog.dstv);
      s.setNumber('1212121212');
      expect(s.canRenew, isFalse);
      s.draft.customer = const CustomerLookup(accountName: 'TEST', currentBouquet: 'DStv Compact', renewalAmount: 7900);
      expect(s.canRenew, isTrue);
      s.selectRenewal();
      expect(s.draft.total, 7900);
      s.setMonths(3);
      expect(s.draft.months, 1, reason: 'renewal is always one period');

      await s.pay('1234');
      final body = jsonDecode(calls.last.body) as Map<String, dynamic>;
      expect(body['mode'], 'renew');
      expect(body.containsKey('variationCode'), isFalse);
      expect(body.containsKey('months'), isFalse);
    });

    test('failed payment throws with the refunded transaction', () async {
      final s = build((r) => {
            '_status': 422,
            'success': false,
            'message': 'Payment failed. Your wallet has been refunded.',
            'data': {
              'balance': 5400,
              'transaction': {
                'id': 'tx2',
                'status': 'failed',
                'refunded': true,
                'amount': 4400,
                'serviceID': 'dstv',
                'billersCode': '7012345678',
                'packageName': 'DStv Padi',
                'months': 1,
              },
            },
          });
      s.user = const AppUser(id: 'u1', fullName: 'Ada', phone: '0803', email: '', balance: 5400, hasPin: true);
      s.startFlow(Catalog.dstv);
      s.setNumber('7012345678');
      s.setPackage(const TvPackage(id: 'dstv-padi', name: 'Padi', monthlyPrice: 4400));
      try {
        await s.pay('1234');
        fail('should throw');
      } on ApiException catch (e) {
        expect((e.data! as TvTransaction).refunded, isTrue);
      }
      expect(s.walletBalance, 5400);
    });
  });
}
