# Deployment Checklist for iOS App Store

## 1. Pre-Build Security Audit

- [x] Remove hardcoded Supabase credentials from configuration files
- [x] Configure Supabase config to use build-time environment variables
- [x] Remove `.env` file from assets in pubspec.yaml
- [x] Check for any debug prints or logs exposing sensitive information
- [x] Verify iOS app transport security settings in Info.plist

## 2. Environment and Version Setup

- [ ] Increment version using `./scripts/bump_version.sh` (patch/minor/major)
- [ ] Verify `.env` file exists for local build with correct credentials
- [ ] Ensure Info.plist has all required usage descriptions:
  - [x] NSPhotoLibraryUsageDescription - For profile photos
  - [x] NSCameraUsageDescription - For taking profile photos
  - [x] NSHealthShareUsageDescription - For health data integration
  - [x] NSHealthUpdateUsageDescription - For health data updates
  - [x] NSAppTransportSecurity - Set to disallow arbitrary loads

## 3. Code Quality and Dependencies

- [x] Run `flutter pub outdated` to check for any pending updates
- [x] Ensure correct Flutter SDK version in pubspec.yaml
- [x] Verify that all packages in pubspec.yaml are up-to-date
- [x] Review and fix any linter warnings or errors

## 4. Build Process

- [ ] Clean build environment with `flutter clean`
- [ ] Run `./scripts/build_ios.sh` to build with encrypted credentials
- [ ] Verify minimum iOS version set to 14.0 in AppFrameworkInfo.plist
- [ ] Ensure code signing identity is properly set in Xcode
- [ ] Disable Bitcode (should be NO as Apple removed support)
- [ ] Enable code obfuscation in release builds

## 5. Testing

- [ ] Test app on iPhone simulator with different screen sizes
- [ ] Verify all screens display correctly on notched devices
- [ ] Test app with different iOS versions (14.0+)
- [ ] Verify SafeArea is properly implemented across all screens
- [ ] Test the app without internet connection
- [ ] Ensure splash screen works as expected
- [ ] Test all core features end-to-end

## 6. App Store Submission

- [ ] Prepare screenshots for all required device sizes
- [ ] Create App Store listing with:
  - [ ] Description with medical disclaimer
  - [ ] Keywords
  - [ ] Support URL
  - [ ] Marketing URL
  - [ ] Privacy Policy URL
- [ ] Set appropriate age rating (4+)
- [ ] Provide required app review information for Apple Review team
- [ ] Submit for TestFlight testing before App Store submission
- [ ] Address any TestFlight rejection issues

## 7. Post-Submission

- [ ] Invite internal team to test on TestFlight
- [ ] Monitor crash reports from TestFlight
- [ ] Prepare for App Store Review questions or rejections
- [ ] Monitor App Store Connect for app status

## Common Issues and Solutions

1. **White Screen on Launch in TestFlight**
   - Solution: Ensure all environment variables are properly injected at build time
   - Run build script with `--dart-define` flags for Supabase credentials

2. **App Store Review Rejections**
   - Metadata Rejections: Verify all usage descriptions match app functionality
   - Privacy Policy: Ensure your privacy policy covers all data usage
   - Performance: Test cold start time and app responsiveness

3. **Missing Assets**
   - Verify all assets in pubspec.yaml actually exist in the project
   - Run `flutter build ios` locally before archiving to catch any errors

## Final Build Command

```bash
./scripts/build_ios_production.sh
```

Then in Xcode:
1. Open the generated project: `open ios/Runner.xcworkspace`
2. Select Product > Archive
3. In the Archives organizer, click "Distribute App"
4. Choose "App Store Connect" and follow the prompts 