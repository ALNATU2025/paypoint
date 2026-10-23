import 'package:flutter/material.dart';

import '../models/models.dart';

/// Provider catalogue.
///
/// IMPORTANT: bouquet prices and channel counts below are SAMPLE values for the
/// prototype. Bouquet prices change often — load live prices from your billing
/// API (see `lib/services/billing_service.dart`) before going to production.
class Catalog {
  Catalog._();

  static const TvProvider dstv = TvProvider(
    id: TvProviderId.dstv,
    name: 'DStv',
    shortName: 'DStv',
    color: Color(0xFF0E6FD8),
    idLabel: 'Smartcard number',
    idLength: 10,
    packages: [
      TvPackage(id: 'dstv-padi', name: 'Padi', channels: '40+ channels', monthlyPrice: 4400),
      TvPackage(id: 'dstv-yanga', name: 'Yanga', channels: '90+ channels', monthlyPrice: 6000),
      TvPackage(id: 'dstv-confam', name: 'Confam', channels: '105+ channels', monthlyPrice: 11000),
      TvPackage(id: 'dstv-compact', name: 'Compact', channels: '135+ channels', monthlyPrice: 19000, popular: true),
      TvPackage(id: 'dstv-compact-plus', name: 'Compact Plus', channels: '155+ channels', monthlyPrice: 30000),
      TvPackage(id: 'dstv-premium', name: 'Premium', channels: '175+ channels', monthlyPrice: 44500),
    ],
  );

  static const TvProvider gotv = TvProvider(
    id: TvProviderId.gotv,
    name: 'GOtv',
    shortName: 'GOtv',
    color: Color(0xFF1E9A3E),
    idLabel: 'IUC number',
    idLength: 10,
    packages: [
      TvPackage(id: 'gotv-smallie', name: 'Smallie', channels: '30+ channels', monthlyPrice: 1900),
      TvPackage(id: 'gotv-jinja', name: 'Jinja', channels: '45+ channels', monthlyPrice: 3900),
      TvPackage(id: 'gotv-jolli', name: 'Jolli', channels: '65+ channels', monthlyPrice: 5800),
      TvPackage(id: 'gotv-max', name: 'Max', channels: '75+ channels', monthlyPrice: 8500, popular: true),
      TvPackage(id: 'gotv-supa', name: 'Supa', channels: '85+ channels', monthlyPrice: 11400),
      TvPackage(id: 'gotv-supa-plus', name: 'Supa+', channels: '95+ channels', monthlyPrice: 16800),
    ],
  );

  static const TvProvider startimes = TvProvider(
    id: TvProviderId.startimes,
    name: 'StarTimes',
    shortName: 'Star',
    color: Color(0xFF12245E),
    idLabel: 'Smartcard number',
    idLength: 11,
    italicWordmark: false,
    accentDot: Color(0xFFF28C1B),
    packages: [
      TvPackage(id: 'st-nova', name: 'Nova', channels: '40+ channels', monthlyPrice: 1900),
      TvPackage(id: 'st-basic', name: 'Basic', channels: '60+ channels', monthlyPrice: 3700),
      TvPackage(id: 'st-smart', name: 'Smart', channels: '75+ channels', monthlyPrice: 4700),
      TvPackage(id: 'st-classic', name: 'Classic', channels: '85+ channels', monthlyPrice: 5300, popular: true),
      TvPackage(id: 'st-super', name: 'Super', channels: '100+ channels', monthlyPrice: 8800),
    ],
  );

  static const List<TvProvider> providers = [dstv, gotv, startimes];

  static TvProvider byId(TvProviderId id) => providers.firstWhere((p) => p.id == id);
}
