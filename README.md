# Paypoint — Cable TV bill payment (Flutter)

> **Live backend:** the app talks to the Paypoint API (`ALNATU2025/paypoint-backend`, deployed at
> `https://paypoint-backend-aj52.onrender.com`). That API sells DStv, GOtv and StarTimes subscriptions through **VTPass**, and funds wallets through **Paystack**.
> To point the app at a different server, build with `--dart-define=API_BASE_URL=https://…`.

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

## How it connects to the backend

| App | API |
|---|---|
| Sign up and log in | `POST /api/auth/register`, `/api/auth/login`. The token is stored with `shared_preferences` |
| Create or change PIN | `PUT /api/auth/pin` |
| Verify smartcard / IUC | `POST /api/cable/verify`, which returns the real customer name from VTPass |
| Packages | `GET /api/cable/:provider/packages`, with live VTPass prices |
| Pay | `POST /api/cable/pay`. The PIN is checked on the server and the wallet is debited; a failed payment is refunded automatically |
| Processing payments | `POST /api/cable/requery/:id`. The result screen re-checks every 8 seconds |
| Fund wallet | `POST /api/wallet/fund/initialize` opens the Paystack checkout, then `GET /api/wallet/fund/verify/:ref` confirms it |
| History, saved decoders, home | `GET /api/transactions` |

The code is in `lib/services/api_client.dart` and `lib/state/app_state.dart`.

## Still to do before a store release
1. **Signing.** Sign the release with your own keystore. The CI build uses the debug key.
2. **Receipts.** Add `share_plus` to the Share button and `pdf` + `printing` to the Download button. The spots are marked in `receipt_screen.dart`.
3. **Branding.** DStv, GOtv and StarTimes appear as text on their brand colours. Use the official logos only if those providers allow it.
