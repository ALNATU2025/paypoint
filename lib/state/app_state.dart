import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';
import '../models/models.dart';
import '../services/api_client.dart';

/// Marker id for "renew current bouquet" in [PaymentDraft.package].
const kRenewalPackageId = '__renew__';

/// The in-progress subscription the user is building across the pay flow.
class PaymentDraft {
  TvProvider provider = Catalog.dstv;
  String number = '';
  CustomerLookup? customer;
  TvPackage? package;
  int months = 1;
  PaymentMethod method = PaymentMethod.wallet;

  /// Renew the current bouquet at the provider's renewal price
  /// (DStv / GOtv), instead of buying a specific package.
  bool renew = false;

  /// Flat fee the backend adds per payment (from the packages response).
  int serviceFee = 0;

  int get subtotal => package?.priceFor(months) ?? 0;
  int get total => package == null ? 0 : subtotal + serviceFee;

  DateTime get newExpiry {
    final now = DateTime.now();
    final due = customer?.dueDate;
    final start = due != null && due.isAfter(now) ? due : now;
    return start.add(Duration(days: 30 * months));
  }
}

/// Outcome of a payment attempt.
class PayResult {
  const PayResult(this.transaction, this.message);
  final TvTransaction transaction;
  final String message;
}

/// App-wide state backed by the Paypoint API. Kept dependency-free
/// (ChangeNotifier + InheritedNotifier).
class AppState extends ChangeNotifier {
  AppState({ApiClient? api}) : api = api ?? ApiClient();

  final ApiClient api;

  static const _kToken = 'auth_token';
  static const _kUser = 'auth_user';
  static const _kOnboarded = 'onboarding_seen';
  static const _kReminders = 'renewal_reminders';

  SharedPreferences? _prefs;
  AppUser? user;
  bool onboardingSeen = false;
  bool remindersOn = true;

  final List<TvTransaction> transactions = [];
  final List<FundingTransaction> fundings = [];
  bool loadingHistory = false;

  final Map<TvProviderId, List<TvPackage>> _packages = {};
  final Map<TvProviderId, int> _fees = {};

  PaymentDraft draft = PaymentDraft();

  // ---------- convenience getters used by the UI ----------

  bool get loggedIn => user != null;
  String get fullName => user?.fullName ?? '';
  String get phone => user?.phone ?? '';
  String get email => user?.email ?? '';
  double get walletBalance => user?.balance ?? 0;
  bool get hasPin => user?.hasPin ?? false;
  bool get walletCanCover => walletBalance >= draft.total;

  /// Decoders paid for before: the latest successful payment per number.
  List<SavedDecoder> get decoders {
    final seen = <String>{};
    final out = <SavedDecoder>[];
    for (final t in transactions) {
      if (!t.success) continue;
      final key = '${t.provider.serviceID}:${t.smartcard}';
      if (!seen.add(key)) continue;
      out.add(SavedDecoder(
        nickname: t.accountName.isEmpty ? t.provider.name : _titleCase(t.accountName.split(' ').first),
        provider: t.provider,
        number: t.smartcard,
        accountName: t.accountName,
        package: t.package,
        expiresOn: t.activeUntil,
      ));
    }
    return out;
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  // ---------- session ----------

  /// Loads the saved session. Returns true when the user is logged in.
  ///
  /// Uses the cached profile so the app opens instantly, then refreshes from
  /// the server in the background (Render can take ~50s to wake up).
  Future<bool> init() async {
    _prefs = await SharedPreferences.getInstance();
    onboardingSeen = _prefs!.getBool(_kOnboarded) ?? false;
    remindersOn = _prefs!.getBool(_kReminders) ?? true;
    final token = _prefs!.getString(_kToken);
    final cached = _prefs!.getString(_kUser);
    if (token == null || cached == null) return false;
    api.token = token;
    try {
      user = AppUser.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    } catch (_) {
      await _clearSession();
      return false;
    }
    notifyListeners();
    refresh().catchError((Object e) async {
      if (e is ApiException && e.unauthorized) {
        await _clearSession();
        notifyListeners();
      }
    });
    return true;
  }

  Future<void> markOnboardingSeen() async {
    onboardingSeen = true;
    await _prefs?.setBool(_kOnboarded, true);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final data = await api.post('/api/auth/register', {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
    });
    await _startSession(data as Map<String, dynamic>);
  }

  Future<void> login({required String email, required String password}) async {
    final data = await api.post('/api/auth/login', {'email': email, 'password': password});
    await _startSession(data as Map<String, dynamic>);
    refreshHistory();
  }

  Future<void> _startSession(Map<String, dynamic> data) async {
    api.token = data['token'] as String;
    await _prefs?.setString(_kToken, api.token!);
    _setUser(AppUser.fromJson(data['user'] as Map<String, dynamic>));
    await markOnboardingSeen();
    notifyListeners();
  }

  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  Future<void> _clearSession() async {
    api.token = null;
    user = null;
    transactions.clear();
    fundings.clear();
    draft = PaymentDraft();
    await _prefs?.remove(_kToken);
    await _prefs?.remove(_kUser);
  }

  Future<void> refreshMe() async {
    final data = await api.get('/api/auth/me');
    _setUser(AppUser.fromJson(data as Map<String, dynamic>));
    notifyListeners();
  }

  /// Sets the PIN, or changes it when [currentPin] is given.
  Future<void> setPin(String pin, {String? currentPin}) async {
    final data = await api.put('/api/auth/pin', {
      'pin': pin,
      if (currentPin != null) 'currentPin': currentPin,
    });
    _setUser(AppUser.fromJson(data as Map<String, dynamic>));
    notifyListeners();
  }

  void _setUser(AppUser u) {
    user = u;
    _prefs?.setString(
      _kUser,
      jsonEncode({
        'id': u.id,
        'fullName': u.fullName,
        'phone': u.phone,
        'email': u.email,
        'balance': u.balance,
        'hasPin': u.hasPin,
      }),
    );
  }

  Future<void> refresh() async {
    await Future.wait([refreshMe(), refreshHistory()]);
  }

  Future<void> refreshHistory() async {
    if (!loggedIn) return;
    loadingHistory = true;
    notifyListeners();
    try {
      final list = (await api.get('/api/transactions?limit=100')) as List<dynamic>;
      transactions
        ..clear()
        ..addAll(list
            .cast<Map<String, dynamic>>()
            .where((j) => j['type'] == 'cable')
            .map((j) => TvTransaction.fromJson(j, Catalog.byServiceID))
            .whereType<TvTransaction>());
      fundings
        ..clear()
        ..addAll(list.cast<Map<String, dynamic>>().where((j) => j['type'] == 'funding').map(FundingTransaction.fromJson));
    } finally {
      loadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> setReminders(bool on) async {
    remindersOn = on;
    notifyListeners();
    await _prefs?.setBool(_kReminders, on);
  }

  // ---------- pay flow ----------

  void startFlow(TvProvider provider) {
    draft = PaymentDraft()..provider = provider;
    notifyListeners();
  }

  void startRenewal(SavedDecoder d) {
    draft = PaymentDraft()
      ..provider = d.provider
      ..number = d.number
      ..customer = CustomerLookup(accountName: d.accountName, dueDate: d.expiresOn)
      ..package = d.package;
    notifyListeners();
    // Refresh the real customer details in the background.
    verifyCustomer().catchError((_) {});
  }

  void setProvider(TvProvider p) {
    if (draft.provider.id == p.id) return;
    draft
      ..provider = p
      ..customer = null
      ..package = null
      ..renew = false
      ..months = 1
      ..number = '';
    notifyListeners();
  }

  void setNumber(String n) {
    final digits = n.replaceAll(RegExp(r'\D'), '');
    if (digits == draft.number) return;
    draft
      ..number = digits
      ..customer = null
      ..renew = false;
    notifyListeners();
  }

  Future<void> verifyCustomer() async {
    final number = draft.number;
    final provider = draft.provider;
    final data = await api.post('/api/cable/verify', {
      'serviceID': provider.serviceID,
      'billersCode': number,
    }) as Map<String, dynamic>;
    // Ignore stale answers if the user changed the number meanwhile.
    if (draft.number != number || draft.provider.id != provider.id) return;
    draft.customer = CustomerLookup.fromJson(data);
    notifyListeners();
  }

  /// Live packages for a provider (cached for the session).
  List<TvPackage>? packagesFor(TvProvider p) => _packages[p.id];

  Future<List<TvPackage>> loadPackages(TvProvider p, {bool force = false}) async {
    if (!force && _packages[p.id] != null) return _packages[p.id]!;
    final body = await api.getRaw('/api/cable/${p.serviceID}/packages');
    final list = (body['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((j) => TvPackage.fromJson(j, providerName: p.name))
        .toList();
    _packages[p.id] = list;
    _fees[p.id] = (body['serviceFee'] as num? ?? 0).round();
    if (draft.provider.id == p.id) draft.serviceFee = _fees[p.id]!;
    notifyListeners();
    return list;
  }

  /// Flat service fee for a provider (reported with its packages).
  int feeFor(TvProvider p) => _fees[p.id] ?? 0;

  /// True when VTPass offered a renewal price for the verified decoder.
  bool get canRenew =>
      draft.provider.supportsMonths && (draft.customer?.renewalAmount ?? 0) > 0;

  void selectRenewal() {
    final c = draft.customer;
    if (c == null || !canRenew) return;
    draft
      ..renew = true
      ..months = 1
      ..serviceFee = feeFor(draft.provider)
      ..package = TvPackage(
        id: kRenewalPackageId,
        name: c.currentBouquet?.isNotEmpty == true ? c.currentBouquet! : 'Current bouquet',
        monthlyPrice: c.renewalAmount!.round(),
      );
    notifyListeners();
  }

  void setPackage(TvPackage p) {
    draft
      ..renew = false
      ..package = p
      ..serviceFee = feeFor(draft.provider);
    notifyListeners();
  }

  void setMonths(int m) {
    draft.months = draft.provider.supportsMonths && !draft.renew ? m : 1;
    notifyListeners();
  }

  void setMethod(PaymentMethod m) {
    draft.method = m;
    notifyListeners();
  }

  /// Sends the payment. Returns the transaction (success or pending).
  /// Throws [ApiException] on wrong PIN, insufficient funds or a failed
  /// payment (in which case the wallet has already been refunded).
  Future<PayResult> pay(String pin) async {
    final d = draft;
    final pkg = d.package!;
    final body = await api.postRaw('/api/cable/pay', {
      'serviceID': d.provider.serviceID,
      'billersCode': d.number,
      'pin': pin,
      if (d.renew) 'mode': 'renew' else ...{'variationCode': pkg.id, 'months': d.months},
      if (d.customer != null) 'customerName': d.customer!.accountName,
    });
    final data = body['data'] as Map<String, dynamic>?;
    final message = (body['message'] as String?) ?? '';
    if (data != null && data['balance'] != null && user != null) {
      user = user!.copyWith(balance: (data['balance'] as num).toDouble());
    }
    final txJson = data?['transaction'] as Map<String, dynamic>?;
    final tx = txJson == null ? null : TvTransaction.fromJson(txJson, Catalog.byServiceID);
    if (tx != null) {
      transactions.removeWhere((t) => t.id == tx.id);
      transactions.insert(0, tx);
    }
    notifyListeners();
    if (body['success'] == true && tx != null) return PayResult(tx, message);
    throw ApiException(message.isEmpty ? 'Payment failed' : message, code: body['code'] as String?, data: tx);
  }

  /// Asks the backend for the latest status of a pending payment.
  Future<TvTransaction> requery(TvTransaction tx) async {
    final data = await api.post('/api/cable/requery/${tx.id}') as Map<String, dynamic>;
    final updated = TvTransaction.fromJson(data['transaction'] as Map<String, dynamic>, Catalog.byServiceID) ?? tx;
    if (user != null && data['balance'] != null) {
      user = user!.copyWith(balance: (data['balance'] as num).toDouble());
    }
    final i = transactions.indexWhere((t) => t.id == tx.id);
    if (i >= 0) transactions[i] = updated;
    notifyListeners();
    return updated;
  }

  // ---------- stats ----------

  int spentThisMonth() {
    final n = DateTime.now();
    return transactions
        .where((t) => t.success && t.date.year == n.year && t.date.month == n.month)
        .fold(0, (sum, t) => sum + t.amount);
  }

  int renewalsThisMonth() {
    final n = DateTime.now();
    return transactions.where((t) => t.success && t.date.year == n.year && t.date.month == n.month).length;
  }
}

/// Exposes [AppState] to the widget tree.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }

  /// Read without subscribing to rebuilds (for callbacks).
  static AppState read(BuildContext context) {
    final el = context.getElementForInheritedWidgetOfExactType<AppScope>();
    return (el!.widget as AppScope).notifier!;
  }
}
