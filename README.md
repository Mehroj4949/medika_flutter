# MEDIKA Flutter

Flutter client migration for the MEDIKA medical-equipment marketplace.

## Why this structure

The code is intentionally separated into small editable files:

- `lib/core/app_config.dart` — API URL and MEDIKA constants
- `lib/core/app_theme.dart` — all MEDIKA brand colors/theme
- `lib/core/localization.dart` — RU/TJ text
- `lib/models/product.dart` — product model
- `lib/data/catalog_repository.dart` — loads the existing MEDIKA catalog
- `lib/data/medika_api.dart` — Quote and Service API
- `lib/screens/` — one file per screen
- `lib/widgets/` — reusable product cards/dialogs/images

This makes future edits much easier than keeping all UI in one large JavaScript file.

## What already works in this Flutter source

- Responsive Flutter UI: mobile bottom navigation / desktop NavigationRail
- Home marketplace storefront
- Full catalog loader from current MEDIKA `products.json` + compact expanded catalog A/B
- Catalog overrides from the existing MEDIKA backend
- Search, category, brand and availability filters
- Product details
- Exact-image-safe behavior: if the product has no image, MEDIKA fallback is shown; no neighboring model is substituted
- Favorites stored locally
- Compare: up to 3 products in the same category
- MEDIKA SELECT basic recommendation flow
- Quote requests through existing `POST /api/quotes`
- Service requests through existing `POST /api/service`
- RU/TJ switching
- Responsive phone / tablet / desktop layout

## Important migration note

The old web client used AppDeploy's browser auth SDK for Google/Apple sign-in, My MEDIKA cloud sync, owner/admin identity and native notifications. That SDK is web-specific.

Therefore authenticated **My MEDIKA + Google/Apple sign-in + MEDIKA ADMIN + native push notifications** should be reconnected with a Flutter-native auth/push layer in the next pass. Anonymous Quote and Service already use the existing MEDIKA backend directly.

The current web app is not removed or modified by this Flutter source.

## Run locally

Flutter SDK is not installed in the generation environment, so Android/iOS platform folders are intentionally not fabricated.

On your computer:

```bash
unzip medika_flutter_source.zip
cd medika_flutter
flutter create . --platforms=android,ios
flutter pub get
flutter run
```

If `flutter create .` asks about organization/package, use a package matching your release plan, e.g. `tj.medika.app`.

## Build Android

```bash
flutter build appbundle --release
```

## Build iOS

```bash
flutter build ios --release
```

(iOS release build requires macOS + Xcode.)

## Change backend URL

Edit only:

`lib/core/app_config.dart`

```dart
static const String apiBase = 'https://medika-ffqkww.v2.appdeploy.ai';
```
