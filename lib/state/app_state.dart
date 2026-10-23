import 'package:flutter/widgets.dart';

import '../data/catalog.dart';
import '../models/models.dart';
import '../services/billing_service.dart';

/// The in-progress subscription the user is building across the pay flow.
class PaymentDraft {
  TvProvider provider = Catalog.dstv;
  String number = '';
  CustomerLookup? customer;
  bool saveDecoder = true;
  TvPackage? package;
  int months = 1;
  PaymentMethod method = PaymentMethod.wallet;

  int get total => package?.priceFor(months) ?? 0;

  DateTime get newExpiry {
    final base = customer?.dueDate ?? DateTime.now();
    final start = base.isBefore(DateTime.now()) ? DateTime.now() : base;
    return start.add(Duration(days: 30 * months));
  }
}

/// App-wide state. Kept dependency-free (ChangeNotifier + InheritedNotifier).
class AppState extends ChangeNotifier {
  AppState({BillingService? billing}) : billing = billing ?? MockBillingService() {
    _seed();
  }

  final BillingService billing;

  String fullName = 'Alusine Barrie';
  String phone = '803 456 7890';
  String countryCode = '+234';
  String email = '';
  double walletBalance = 24500;
  bool remindersOn = true;

  final List<SavedDecoder> decoders = [];
  final List<TvTransaction> transactions = [];

  PaymentDraft draft = PaymentDraft();

  void _seed() {
    final now = DateTime.now();
    decoders.addAll([
      SavedDecoder(
        nickname: 'Living room',
        provider: Catalog.dstv,
        number: '7012345678',
        accountName: fullName.toUpperCase(),
        package: Catalog.dstv.packages[3],
        expiresOn: now.add(const Duration(days: 3)),
      ),
      SavedDecoder(
        nickname: 'Bedroom',
        provider: Catalog.gotv,
        number: '4621907735',
        accountName: fullName.toUpperCase(),
        package: Catalog.gotv.packages[3],
        expiresOn: now.add(const Duration(days: 21)),
      ),
    ]);
    transactions.addAll([
      TvTransaction(
        reference: 'PP-7KD29QWA',
        provider: Catalog.gotv,
        package: Catalog.gotv.packages[3],
        months: 1,
        amount: 8500,
        smartcard: '4621907735',
        accountName: fullName.toUpperCase(),
        method: PaymentMethod.card,
        date: now.subtract(const Duration(days: 9, hours: 6)),
        activeUntil: now.add(const Duration(days: 21)),
      ),
      TvTransaction(
        reference: 'PP-3MZ81RTE',
        provider: Catalog.startimes,
        package: Catalog.startimes.packages[3],
        months: 1,
        amount: 5300,
        smartcard: '02134567890',
        accountName: fullName.toUpperCase(),
        method: PaymentMethod.bank,
        date: now.subtract(const Duration(days: 25, hours: 2)),
        activeUntil: now.add(const Duration(days: 5)),
        success: false,
      ),
      TvTransaction(
        reference: 'PP-9HX45LPC',
        provider: Catalog.dstv,
        package: Catalog.dstv.packages[3],
        months: 1,
        amount: 19000,
        smartcard: '7012345678',
        accountName: fullName.toUpperCase(),
        method: PaymentMethod.wallet,
        date: now.subtract(const Duration(days: 27, hours: 8)),
        activeUntil: now.add(const Duration(days: 3)),
      ),
    ]);
  }

  // ---------- account ----------

  void setAccount({required String name, required String phone, String email = ''}) {
    fullName = name.trim();
    this.phone = phone.trim();
    this.email = email.trim();
    if (billing is MockBillingService) {
      (billing as MockBillingService).accountNameForLookup = fullName;
    }
    notifyListeners();
  }

  void fundWallet(double amount) {
    walletBalance += amount;
    notifyListeners();
  }

  void setReminders(bool on) {
    remindersOn = on;
    notifyListeners();
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
      ..saveDecoder = false
      ..package = d.package
      ..customer = CustomerLookup(
        accountName: d.accountName,
        currentPackage: d.package,
        dueDate: d.expiresOn,
      );
    notifyListeners();
  }

  void setProvider(TvProvider p) {
    if (draft.provider.id == p.id) return;
    draft
      ..provider = p
      ..customer = null
      ..package = null
      ..number = '';
    notifyListeners();
  }

  void setNumber(String n) {
    draft
      ..number = n.replaceAll(RegExp(r'\D'), '')
      ..customer = null;
    notifyListeners();
  }

  Future<void> verifyCustomer() async {
    final result = await billing.verifyCustomer(draft.provider, draft.number);
    draft
      ..customer = result
      ..package ??= result.currentPackage;
    notifyListeners();
  }

  void setSaveDecoder(bool v) {
    draft.saveDecoder = v;
    notifyListeners();
  }

  void setPackage(TvPackage p) {
    draft.package = p;
    notifyListeners();
  }

  void setMonths(int m) {
    draft.months = m;
    notifyListeners();
  }

  void setMethod(PaymentMethod m) {
    draft.method = m;
    notifyListeners();
  }

  bool get walletCanCover => walletBalance >= draft.total;

  /// Sends the payment and records the transaction.
  Future<TvTransaction> pay(String pin) async {
    final d = draft;
    final pkg = d.package!;
    final ref = await billing.pay(
      provider: d.provider,
      number: d.number,
      package: pkg,
      months: d.months,
      method: d.method,
      pin: pin,
    );
    if (d.method == PaymentMethod.wallet) {
      if (walletBalance < d.total) throw BillingException('Insufficient wallet balance.');
      walletBalance -= d.total;
    }
    final tx = TvTransaction(
      reference: ref,
      provider: d.provider,
      package: pkg,
      months: d.months,
      amount: d.total,
      smartcard: d.number,
      accountName: d.customer?.accountName ?? fullName.toUpperCase(),
      method: d.method,
      date: DateTime.now(),
      activeUntil: d.newExpiry,
    );
    transactions.insert(0, tx);

    final i = decoders.indexWhere((x) => x.number == d.number && x.provider.id == d.provider.id);
    if (i >= 0) {
      decoders[i] = decoders[i].copyWith(package: pkg, expiresOn: tx.activeUntil);
    } else if (d.saveDecoder) {
      decoders.add(SavedDecoder(
        nickname: '${d.provider.name} decoder',
        provider: d.provider,
        number: d.number,
        accountName: tx.accountName,
        package: pkg,
        expiresOn: tx.activeUntil,
      ));
    }
    notifyListeners();
    return tx;
  }

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
