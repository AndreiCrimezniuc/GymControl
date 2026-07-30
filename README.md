# GymControl mobile

Flutter client for GymControl.

Canonical documentation is maintained in the
[platform repository](https://github.com/Control-Labs-Holding/backend-api/tree/main/docs):

- [Product](https://github.com/Control-Labs-Holding/backend-api/blob/main/docs/FUNCTIONALITY.md)
- [Mobile architecture](https://github.com/Control-Labs-Holding/backend-api/blob/main/docs/MOBILE.md)
- [Analytics](https://github.com/Control-Labs-Holding/backend-api/blob/main/docs/ANALYTICS.md)
- [Diagnostics and crash reporting](https://github.com/Control-Labs-Holding/backend-api/blob/main/docs/OBSERVABILITY.md)
- [Testing](https://github.com/Control-Labs-Holding/backend-api/blob/main/docs/QUALITY.md)
- [Beta distribution](https://github.com/Control-Labs-Holding/backend-api/blob/main/docs/BETA_DISTRIBUTION.md)
- [Store readiness](https://github.com/Control-Labs-Holding/backend-api/blob/main/docs/RELEASE_PLAN.md)

Quick validation:

```bash
flutter pub get
flutter analyze
flutter test
flutter build ios --release --no-codesign
```
