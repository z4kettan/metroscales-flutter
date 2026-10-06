# Metro Scales app

The Flutter app for shop owners and staff. It works with the Metro Scales API
(`metroscales-backend`) and runs on Android and iOS.

## What it does

- Home: sales, bills, discount and GST for any day, last 7 days chart, recent bills
- Items: search, filter by category, sort by PLU or name, add and edit items
  (PLU, barcode scan, per kg or per pack, tare, GST included or extra)
- Categories
- Scales: online status, last seen, send items to the scale or read them back,
  scale details and WiFi, print format and footer lines, shortcut keys, clear PLU
- Update prices and update stock for many items at once
- Purchases from suppliers (adds to stock)
- Reports: today, yesterday, 7 days, this month or a custom range, by day and by
  item, shared as a CSV file that Excel opens
- Bill settings (header and footers printed on bills) with a receipt preview
- Users: owners add staff and choose which branches they see
- Profile and PIN change
- Branch switcher on every main screen

Staff accounts see sales and can update stock and record purchases. Prices,
items, scales, bill settings and users are for owners only.

Changes meant for a scale are queued on the server and delivered when the scale
next connects, so they work even while a scale is offline.

## Run it

1. Install Flutter 3.47 or newer.
2. Start the backend (see `metroscales-backend`).
3. Copy `config.example.json` to `config.json` and set `API_HOST`:
   - Android emulator: `10.0.2.2`
   - iOS simulator or Chrome: `localhost`
   - A real phone on the same WiFi: your computer's LAN IP, for example `192.168.1.20`
4. Run:

```
flutter pub get
flutter run --dart-define-from-file=config.json
```

On Windows, `run.bat` does step 4 for you.

Demo login (after `npm run db:seed` in the backend): `owner@demo.local`, PIN `1234`.
Staff demo: `staff@demo.local`, PIN `1111`.

## Build a release

```
flutter build apk --release --dart-define-from-file=config.json
flutter build ipa --release --dart-define-from-file=config.json
```

## Code layout

```
lib/
  core/         constants, theme (colours, Inter font), router, formatting, toasts
  models/       data classes read from the API
  services/     one class per API area (auth, catalog, scales, stock, reports, users)
  providers/    Riverpod providers: signed-in user, branch, and data lists
  widgets/      shared pieces: cards, empty states, branch switcher, item picker
  features/     one folder per area, one file per screen
```

## Checks

```
flutter analyze
flutter test
```
