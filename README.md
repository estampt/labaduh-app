# Labaduh Flutter Scaffold (iOS + Android)

This is a base Flutter app scaffold for Labaduh using:
- Riverpod (state management)
- go_router (routing)
- Dio (API client)
- flutter_secure_storage (token storage)

## How to use

1) Create a Flutter project then copy these files in:

```bash
flutter create labaduh
cd labaduh
# Replace the lib/ folder + pubspec.yaml + analysis_options.yaml with this scaffold
flutter pub get
flutter run
```

## Configure API base URL
Edit: `lib/core/config/env.dart`

## Next steps you can add
- AuthRepository (Laravel login/register)
- Customer order flow (multi-services, separate KGs)
- Vendor pricing + acceptance
- Push notifications + payments
