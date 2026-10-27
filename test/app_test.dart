import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paypoint/core/formatters.dart';
import 'package:paypoint/data/catalog.dart';
import 'package:paypoint/models/models.dart';
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
      await s.login(phone: '08031234567', password: 'secret1');
      expect(s.loggedIn, isTrue);
      expect(s.walletBalance, 5000);
      expect(s.api.token, 'tok');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'tok');
    });

    test('backend errors surface as readable messages', () async {
      final s = build((r) => {'_status': 401, 'success': false, 'message': 'Incorrect phone number or password'});
      await s.init();
      await expectLater(
        s.login(phone: '08031234567', password: 'x'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Incorrect phone number or password')),
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
