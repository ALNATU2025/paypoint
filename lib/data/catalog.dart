import 'package:flutter/material.dart';

import '../models/models.dart';

/// Provider branding. Packages and prices are loaded live from the backend
/// (which gets them from VTPass), so nothing here goes stale.
class Catalog {
  Catalog._();

  static const TvProvider dstv = TvProvider(
    id: TvProviderId.dstv,
    name: 'DStv',
    shortName: 'DStv',
    color: Color(0xFF0E6FD8),
    idLabel: 'Smartcard number',
    idLength: 10,
    supportsMonths: true,
  );

  static const TvProvider gotv = TvProvider(
    id: TvProviderId.gotv,
    name: 'GOtv',
    shortName: 'GOtv',
    color: Color(0xFF1E9A3E),
    idLabel: 'IUC number',
    idLength: 10,
    supportsMonths: true,
  );

  static const TvProvider startimes = TvProvider(
    id: TvProviderId.startimes,
    name: 'StarTimes',
    shortName: 'Star',
    color: Color(0xFF12245E),
    idLabel: 'Smartcard number',
    idLength: 11,
    supportsMonths: false,
    italicWordmark: false,
    accentDot: Color(0xFFF28C1B),
  );

  static const List<TvProvider> providers = [dstv, gotv, startimes];

  static TvProvider byId(TvProviderId id) => providers.firstWhere((p) => p.id == id);

  static TvProvider? byServiceID(String? serviceID) {
    for (final p in providers) {
      if (p.serviceID == serviceID) return p;
    }
    return null;
  }
}
