import '../data/catalog.dart';
import '../models/models.dart';
import 'api_client.dart';

/// Overview numbers for the admin dashboard.
class AdminStats {
  AdminStats(this._j);
  final Map<String, dynamic> _j;

  num _n(Object? v) => v is num ? v : 0;
  Map<String, dynamic> _m(String k) => (_j[k] as Map<String, dynamic>?) ?? const {};

  int get users => _n(_j['users']).toInt();
  int get newUsersToday => _n(_j['newUsersToday']).toInt();
  double get walletBalances => _n(_j['walletBalances']).toDouble();
  double get salesTodayAmount => _n(_m('salesToday')['amount']).toDouble();
  int get salesTodayCount => _n(_m('salesToday')['count']).toInt();
  double get salesAllAmount => _n(_m('salesAll')['amount']).toDouble();
  int get salesAllCount => _n(_m('salesAll')['count']).toInt();
  int get pending => _n(_j['pending']).toInt();
  int get failedToday => _n(_j['failedToday']).toInt();
  bool get vtpassConfigured => _m('vtpass')['configured'] == true;
  String get vtpassMode => (_m('vtpass')['mode'] ?? 'live').toString();
  double? get vtpassBalance => (_m('vtpass')['balance'] as num?)?.toDouble();

  /// serviceID → (amount, count)
  Map<String, (double, int)> get byProvider => {
        for (final e in _m('byProvider').entries)
          e.key: (
            _n((e.value as Map<String, dynamic>)['amount']).toDouble(),
            _n((e.value as Map<String, dynamic>)['count']).toInt(),
          ),
      };
}

class AdminUser {
  AdminUser(Map<String, dynamic> j)
      : id = j['id'] as String,
        fullName = (j['fullName'] ?? '') as String,
        email = (j['email'] ?? '') as String,
        phone = (j['phone'] ?? '') as String,
        balance = (j['balance'] as num? ?? 0).toDouble(),
        hasPin = j['hasPin'] == true,
        pinLocked = j['pinLocked'] == true,
        isAdmin = j['isAdmin'] == true,
        createdAt = DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal();

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final double balance;
  final bool hasPin;
  final bool pinLocked;
  final bool isAdmin;
  final DateTime? createdAt;
}

/// A transaction as the admin sees it (any user's).
class AdminTx {
  AdminTx(Map<String, dynamic> j)
      : id = j['id'] as String,
        type = (j['type'] ?? 'cable') as String,
        status = (j['status'] ?? 'pending') as String,
        amount = (j['amount'] as num? ?? 0).toDouble(),
        description = (j['description'] ?? '') as String,
        serviceID = j['serviceID'] as String?,
        packageName = j['packageName'] as String?,
        billersCode = j['billersCode'] as String?,
        customerName = j['customerName'] as String?,
        reference = (j['reference'] ?? '') as String,
        message = j['message'] as String?,
        refunded = j['refunded'] == true,
        userName = j['userName'] as String?,
        userEmail = j['userEmail'] as String?,
        createdAt = DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal() ?? DateTime.now();

  final String id;
  final String type;
  final String status;
  final double amount;
  final String description;
  final String? serviceID;
  final String? packageName;
  final String? billersCode;
  final String? customerName;
  final String reference;
  final String? message;
  final bool refunded;
  final String? userName;
  final String? userEmail;
  final DateTime createdAt;

  bool get isCable => type == 'cable';
  bool get isDebit => description.startsWith('Debit:');
  String get title {
    if (!isCable) return isDebit ? 'Wallet debit' : 'Wallet credit';
    final p = Catalog.byServiceID(serviceID);
    final name = p?.name ?? serviceID ?? 'Cable';
    final pkg = packageName == null ? '' : TvPackage.cleanName(packageName!, name);
    return '$name $pkg'.trim();
  }
}

/// Calls to /api/admin/*. Only works for accounts the backend marks as admin.
class AdminApi {
  AdminApi(this.api);
  final ApiClient api;

  Future<AdminStats> stats() async => AdminStats(await api.get('/api/admin/stats') as Map<String, dynamic>);

  Future<List<AdminUser>> users({String q = ''}) async {
    final list = await api.get('/api/admin/users?limit=100&q=${Uri.encodeQueryComponent(q)}') as List<dynamic>;
    return list.cast<Map<String, dynamic>>().map(AdminUser.new).toList();
  }

  Future<(AdminUser, List<AdminTx>)> user(String id) async {
    final d = await api.get('/api/admin/users/$id') as Map<String, dynamic>;
    return (
      AdminUser(d['user'] as Map<String, dynamic>),
      (d['transactions'] as List<dynamic>).cast<Map<String, dynamic>>().map(AdminTx.new).toList(),
    );
  }

  Future<AdminUser> credit(String userId, double amount, String note) async {
    final d = await api.post('/api/admin/wallet/credit', {'userId': userId, 'amount': amount, 'note': note})
        as Map<String, dynamic>;
    return AdminUser(d['user'] as Map<String, dynamic>);
  }

  Future<AdminUser> debit(String userId, double amount, String note) async {
    final d = await api.post('/api/admin/wallet/debit', {'userId': userId, 'amount': amount, 'note': note})
        as Map<String, dynamic>;
    return AdminUser(d['user'] as Map<String, dynamic>);
  }

  Future<AdminUser> unlockPin(String userId) async =>
      AdminUser(await api.post('/api/admin/users/$userId/unlock-pin') as Map<String, dynamic>);

  Future<List<AdminTx>> transactions({String? status, String? type}) async {
    final q = [
      'limit=100',
      if (status != null) 'status=$status',
      if (type != null) 'type=$type',
    ].join('&');
    final list = await api.get('/api/admin/transactions?$q') as List<dynamic>;
    return list.cast<Map<String, dynamic>>().map(AdminTx.new).toList();
  }

  Future<AdminTx> requery(String txId) async =>
      AdminTx(await api.post('/api/admin/transactions/$txId/requery') as Map<String, dynamic>);
}
