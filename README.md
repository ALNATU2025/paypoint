# Paypoint — Cable TV bill payment (Flutter)

A Flutter app for paying DStv, GOtv and StarTimes subscriptions. It is built from the Paypoint UI design (16 screens).

## Screens

| # | Screen | File |
|---|--------|------|
| 01 | Splash (animated logo, auto-advances) | `lib/screens/splash_screen.dart` |
| 02–04 | Onboarding (3-page swipeable carousel) | `lib/screens/onboarding_screen.dart` |
| 05 | Create account (validated form) | `lib/screens/sign_up_screen.dart` |
| 06 | Verify phone (6-digit OTP, resend timer, SMS autofill) | `lib/screens/verify_screen.dart` |
| 07 | Home (wallet, providers, saved decoders, fund wallet sheet) | `lib/screens/home_screen.dart` |
| 08 | Enter smartcard / IUC (provider switcher, live lookup) | `lib/screens/smartcard_screen.dart` |
| 09 | Choose package (1 / 3 / 6 months) | `lib/screens/packages_screen.dart` |
| 10 | Review & confirm | `lib/screens/review_screen.dart` |
| 11 | Payment method (wallet, card, bank, USSD) | `lib/screens/payment_method_screen.dart` |
| 12 | Transaction PIN (custom keypad, error shake) | `lib/screens/pin_screen.dart` |
| 13 | Success (animated) | `lib/screens/success_screen.dart` |
| 14 | Receipt (copy reference, share, download) | `lib/screens/receipt_screen.dart` |
| 15 | History (filters, monthly summary) | `lib/screens/history_screen.dart` |
| 16 | Profile (decoders, reminders, log out) | `lib/screens/profile_screen.dart` |

The bottom navigation (Home · Pay TV · History · Profile) lives in `lib/screens/main_shell.dart`.

## Motion and visual design

All animation is built in Flutter with no extra packages. The building blocks are in `lib/widgets/motion.dart`:

| Widget | What it does | Where it is used |
|---|---|---|
| `FadeSlideIn` + `Stagger` | Fade/slide/scale entrance with staggered delays | Every screen's content |
| `PressScale` | Springy shrink on press, with no gesture conflicts | Buttons, cards, keypad, nav |
| `ShimmerSweep` | Light band sweeping across a surface | Primary CTAs, wallet card, decoder card |
| `AuroraBackground` | Slowly drifting colour glows | Splash, onboarding, review, receipt, profile |
| `PulseRings` / `PulseDot` | Ripples and live indicators | Splash logo, OTP, success, expiry alerts |
| `Floating` | Gentle bobbing | Onboarding illustrations |
| `AnimatedAmount` | Counts money up smoothly | Wallet, totals, success, history |
| `DrawnCheck` | Check mark that draws itself | Verified decoder, success, receipt |
| `ConfettiBurst` | Physics-based confetti | Success screen |
| `SlidingSegments` | Segmented control with a gliding pill | Providers, durations, history filters |
| `Glass` | Frosted blur panel | Wallet chips, onboarding, nav bar |

Some highlights by screen:
- The splash logo draws itself.
- Onboarding has parallax and a background that blends between slides.
- The floating glass navigation bar has a sliding highlight.
- The PIN sheet springs up, and it shakes on error.
- Pages change with a custom fade-and-slide transition; iOS keeps its native swipe-back.

Every looping or entrance animation respects the system **Reduce motion** setting.

## Project structure

```
lib/
  main.dart                 App entry, theme, routing, AppScope
  core/
    theme.dart              Brand colours, shadows, ThemeData (Plus Jakarta Sans)
    routes.dart             Named routes
    formatters.dart         Naira, dates, smartcard grouping, initials
  data/catalog.dart         Providers + bouquets (SAMPLE prices)
  models/models.dart        TvProvider, TvPackage, SavedDecoder, TvTransaction, PaymentMethod
  services/billing_service.dart   BillingService interface + MockBillingService
  state/app_state.dart      ChangeNotifier app state + PaymentDraft + AppScope
  widgets/
    paypoint_logo.dart      Vector Paypoint "P" mark, lockup, ring decoration
    common.dart             Buttons, cards, provider badge, step progress, rows…
    motion.dart             Animation toolkit (entrances, shimmer, aurora, confetti…)
  screens/                  All 16 screens
test/app_test.dart          Formatter and pay-flow unit tests
```

The only extra dependency is `google_fonts`. State management uses plain `ChangeNotifier` and `InheritedNotifier`, so there is no extra state package to learn.

## Getting started

You need Flutter 3.27 or newer.

```bash
cd paypoint
flutter create . --org com.paypoint --project-name paypoint   # generates android/ ios/ web/ folders
flutter pub get
flutter run
flutter test
```

`flutter create .` only adds the platform folders. It does not overwrite `lib/` or `pubspec.yaml`.

### App icon and splash (optional)

The logo is drawn in code, so it is sharp at any size. For the launcher icon, export your Paypoint logo PNG to `assets/icon.png`. Then use `flutter_launcher_icons` and `flutter_native_splash`, with background `#071036`.

### Fonts offline

`google_fonts` downloads Plus Jakarta Sans the first time the app runs. To ship it inside the app instead, follow these steps:

1. Download the `.ttf` files and put them in `assets/google_fonts/`.
2. List that folder under `flutter: assets:` in `pubspec.yaml`.

## Before going to production

1. **Prices.** The bouquet prices and channel counts in `lib/data/catalog.dart` are sample values. Load live prices from your aggregator instead.
2. **Backend.** Write a real `BillingService` that calls your bill-payment API, then pass it in from `main.dart` with `AppState(billing: YourBillingService())`. The interface already covers customer lookup, the package list and payment.
3. **Auth.** Wire the OTP send and verify calls into the `// call your OTP API here` spots in `sign_up_screen.dart` and `verify_screen.dart`.
4. **Payments.** Card, bank and USSD flows should use your payment gateway's SDK. Check the PIN on the server; the mock accepts any 4 digits.
5. **Receipts.** Add `share_plus` to the Share button. Add `pdf` and `printing` to the Download button. The spots are marked in `receipt_screen.dart`.
6. **Persistence.** Store the session, saved decoders and history, for example with `shared_preferences`, `hive` or your API.
7. **Branding.** DStv, GOtv and StarTimes appear as text on their brand colours. Use the official logos only if those providers allow it.
