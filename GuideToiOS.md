# Complete Guide to Publish PanicButton to iOS TestFlight

This guide will walk you through the complete process of preparing and publishing your Flutter app to TestFlight for iOS testing.

## 1. Xcode Setup and Configuration

### Sign in with your Apple ID

1. Open Xcode
2. Go to **Xcode → Preferences → Accounts**
3. Click the **+** button in the bottom-left corner
4. Add your Apple Developer account credentials

### Set up Code Signing

1. Select the **Runner** project in the left navigator
2. Select the **Runner** target
3. Go to the **Signing & Capabilities** tab
4. Check ✅ **Automatically manage signing**
5. Select your **Development Team** from the dropdown
6. Make sure the **Bundle Identifier** is unique (e.g., `com.panicbutton.app`)

### Update App Version

1. Still in the Runner target settings, go to the **General** tab
2. Verify your app version (e.g., `1.0.0`) and build number (e.g., `1`)
   
   > **Note:** Each time you upload a new build, you must increment the build number

## 2. Archive and Upload Process

### Create an Archive

1. Connect a physical iOS device or select **Any iOS Device** from the device dropdown in Xcode
2. Go to **Product → Archive**
3. Wait for the archiving process to complete (this may take several minutes)

### Upload to App Store Connect

1. When Archive completes, the **Archive Organizer** window will appear automatically
2. Select your archive and click **Distribute App**
3. Select **App Store Connect** and click **Next**
4. Choose **Upload** and follow the prompts
5. Select appropriate options:
   - **Include bitcode for iOS content**: No (Apple deprecated bitcode)
   - **Strip Swift symbols**: Yes (reduces app size)
   - **Upload your app's symbols**: Yes (helps with crash reporting)
6. Click **Next**, then **Upload**
7. Wait for the upload to complete (may take 5-15 minutes depending on app size and internet speed)

## 3. App Store Connect Configuration

### Prepare TestFlight

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select **Apps** and find your app (or create it if it doesn't exist)
3. Go to the **TestFlight** tab
4. Wait for your build to finish processing (can take 30+ minutes)
   
   > **Note:** You'll see a status indicator next to your build as it processes

### Setup Test Information

1. Click on your build once it's processed
2. Add test information:
   - **What to Test**: Brief description of what testers should try
   - **Test Notes**: Detailed instructions or known issues
3. If prompted, complete the **App Information** section:
   - **Privacy Policy URL**: Required for all apps
   - **Contact Email**: For tester feedback
4. If you're using any sensitive APIs (Health, Location, etc.), you'll need to complete an additional questionnaire

### Add Testers

#### Internal Testers (up to 25 people in your development team)

1. Go to the **Testers and Groups** section
2. Select **Internal Testing**
3. Click **+** to add internal testers by email
   
   > Internal testers must be assigned to your app with a role in App Store Connect

#### External Testers (up to 10,000 people)

1. Go to the **Testers and Groups** section
2. Select **External Testing**
3. Click **Create Group** to organize testers (optional)
4. Add emails of your external testers
5. Submit for **Beta App Review** (required for external testing)

### TestFlight Beta Review

1. For external testers, your app will undergo a Beta App Review
2. This is lighter than the full App Store review
3. Fix any issues and resubmit if needed
4. Reviews typically take 1-2 business days

### Invite Testers

1. Once approved, you can send invites to your testers
2. They'll receive an email with instructions to download TestFlight and install your app
3. You can manage the invitations and see which testers have installed the app

## 4. Prerequisites for App Store Connect

### Create an App Record (if you haven't already)

1. Go to **My Apps → + → New App**
2. Enter required information:
   - **App Name**: PanicButton
   - **Platform**: iOS
   - **Bundle ID**: Must match your Xcode bundle ID
   - **SKU**: Unique identifier for your app (e.g., panicbutton2023)
   - **Primary Language**: Spanish

### Prepare App Store Information

Even for TestFlight, you'll need to provide some basic information:

1. **App Information**:
   - App description
   - Keywords
   - Support URL
   - Marketing URL (optional)
   - Privacy Policy URL (required)
2. **App Screenshots** (if submitting for external testing)
3. **App Icon** (already configured with flutter_launcher_icons)

### Complete Export Compliance

When uploading, you'll be asked about export compliance and encryption:

- **Does your app use encryption?** If you're using standard HTTPS, the answer is typically "Yes, but my app qualifies for exemption"
- **Does your app use third-party encryption?** Typically "No" for most Flutter apps

## 5. Tips for a Successful TestFlight Launch

- **Version Bump**: Each time you upload a new build, increment the build number in your pubspec.yaml and run `flutter build ios`
- **Check for Issues**: Resolve any build warnings or errors before archiving
- **Be Patient**: Processing in App Store Connect can take time, especially for the first build
- **Start with Internal Testing**: Get feedback from internal testers before expanding to external testers
- **Update Privacy Labels**: Make sure your app's privacy labels are correctly set in App Store Connect
- **Test on Multiple Devices**: If possible, test on different iOS devices and versions

## 6. Common Issues and Solutions

### "Missing Compliance" Error

- Make sure you've completed the Export Compliance information during the upload process

### "Invalid Bundle" Error

- Verify your bundle ID matches between Xcode and App Store Connect
- Check that your app version and build numbers are valid

### Processing Failed

- Check that your app icon meets Apple's requirements
- Ensure all required app information is completed
- Verify your app binary is valid

### Rejected During Beta Review

- Read rejection reasons carefully
- Fix the issues mentioned in the rejection notice
- Increment build number and resubmit