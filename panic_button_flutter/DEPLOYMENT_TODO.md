# App Store Deployment TODO List

## Security Tasks

| Task | Priority | Est. Time | Notes |
|------|----------|-----------|-------|
| Remove hardcoded Supabase credentials | HIGH | 1 hour | Update `supabase_config.dart` to use `flutter_dotenv` properly |
| Implement `flutter_secure_storage` | HIGH | 2 hours | Store auth tokens securely in Keychain |
| Update dependencies | MEDIUM | 1 hour | Run `flutter pub upgrade` for security updates |
| Remove debug print statements | HIGH | 1 hour | Remove or limit debug prints that might leak credentials |

## iOS Configuration Tasks

| Task | Priority | Est. Time | Notes |
|------|----------|-----------|-------|
| Update minimum iOS version to 14.0 | HIGH | 15 min | Edit Xcode project settings |
| Create Runner.entitlements file | HIGH | 15 min | For Keychain access |
| Update Info.plist with privacy descriptions | HIGH | 30 min | Add required permission descriptions |
| Configure code obfuscation | MEDIUM | 30 min | Add flags to build command |

## App Store Submission Assets

| Task | Priority | Est. Time | Notes |
|------|----------|-----------|-------|
| Generate screenshots (all sizes) | HIGH | 2 hours | iPhone 14/15 (Pro/Max), iPhone SE, iPad |
| Create app icon variations | HIGH | 1 hour | All required sizes for iOS |
| Write App Store description | HIGH | 1 hour | Include medical disclaimer |
| Create privacy policy | HIGH | 2 hours | Host on company website with accessible URL |
| Prepare app preview video | MEDIUM | 3 hours | 30 second demonstration of key features |

## Legal & Compliance

| Task | Priority | Est. Time | Notes |
|------|----------|-----------|-------|
| Add medical disclaimer to app | HIGH | 30 min | Add to onboarding and settings |
| Prepare GDPR compliance statement | HIGH | 2 hours | Document all data usage |
| Complete App Store privacy questionnaire | HIGH | 1 hour | Detail all data usage for App Privacy section |

## Testing

| Task | Priority | Est. Time | Notes |
|------|----------|-----------|-------|
| Create integration tests | HIGH | 4 hours | Basic user journeys |
| Test on various iOS devices | HIGH | 3 hours | Test on real devices, particularly notch models |
| Fix SafeArea issues | MEDIUM | 2 hours | Ensure UI respects safe areas on all devices |
| Test dynamic type | MEDIUM | 2 hours | Verify app works with larger accessibility text |

## Distribution

| Task | Priority | Est. Time | Notes |
|------|----------|-----------|-------|
| Create Apple Developer account | HIGH | 1 hour | If not already done |
| Generate distribution certificate | HIGH | 30 min | For App Store signing |
| Create App Store Connect entry | HIGH | 30 min | Set up basic app info |
| Configure TestFlight | MEDIUM | 1 hour | For beta testing before launch |
| Setup GitHub Actions CI/CD | MEDIUM | 3 hours | Automate build and test process | 