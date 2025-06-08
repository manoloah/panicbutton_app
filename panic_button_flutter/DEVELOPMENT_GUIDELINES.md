## PanicButton Flutter Development Guidelines

All development of the app be done inside: panicbutton_app/panic_button_flutter, other folders are just for support. And a previous MVP was created at: panicbutton_app/calm-button-breathe-easy. 

You can find supporting Development docs at: panic_button_flutter/development_guidelines_extradocs

### Language Rules

**Code Elements (MUST BE IN ENGLISH)**  
- File names: `settings_screen.dart`, `profile_screen.dart`  
- Class names: `SettingsScreen`, `UserProfile`  
- Variable names: `isLoading`, `userName`  
- Function names: `handleLogin()`, `updateProfile()`  
- Route names: `/settings`, `/profile`  
- Database columns: `user_id`, `created_at`  
- Comments and documentation  
- Git commits  
- Configuration keys

**User-Facing Text (MUST BE IN SPANISH)**  
- Screen titles: "Configuración", "Mi Perfil"  
- Button labels: "Guardar Cambios", "Cerrar Sesión"  
- Error messages: "Error al cargar el perfil"  
- Success messages: "Cambios guardados exitosamente"  
- Form labels: "Nombre", "Correo electrónico"  
- Menu items: "Tu camino", "Mídete"  
- Tooltips and help text  
- Placeholder text  
- Alert messages

**User-Facing Hierarchy**
- DisplayLarge → top‑level hero
- HeadlineLarge → screen titles
- HeadlineMedium/Small → sub‑section or card titles
- Title… → smaller widget‑level labels
- Body… / Label… → paragraph text and buttons

---

### 8-Point Grid System

The 8-point grid system is a design guideline that establishes consistent spacing, sizing, and alignment throughout the app. All measurements should be multiples of 8 (or 4 in certain cases) to create visual harmony.

See sources: 
- https://medium.com/design-bootcamp/8-pixel-revolution-transforming-your-design-workflow-with-figma-66053a6ad404
- https://medium.com/design-bootcamp/designing-in-the-8pt-grid-system-f3c1183ea6e8

**Why We Use the 8-Point Grid System:**
- Creates consistent visual rhythm and spacing
- Makes scaling for different devices easier and more predictable
- Improves communication between designers and developers
- Most screen sizes are divisible by 8, making layouts more predictable
- Reduces decision fatigue during design and implementation

**Core Principles:** 
- Use multiples of 8 for spacing, padding, margins, and component dimensions
- For smaller elements or fine-tuning, use multiples of 4 when necessary
- Always align to the grid - avoid arbitrary values like 13px or 27px

**Practical Guidelines:**

1. **Spacing**:
   - Use the following values for padding and margins:
     - 8px, 16px, 24px, 32px, 40px, 48px, 56px, etc.
   - For tighter spacing, use multiples of 4:
     - 4px, 8px, 12px, 16px, 20px, etc.
   - Between major sections: 24px or 32px
   - Between related elements: 8px or 16px
   - Inside containers (padding): 16px or 24px

2. **Component Sizing**:
   - Button heights: 32px, 40px, 48px, 56px
   - Icon sizes: 16px, 24px, 32px, 40px
   - Input field heights: 40px, 48px
   - Cards and containers: widths and heights in multiples of 8px
   - Touch targets: minimum 48px x 48px

3. **Typography**:
   - Line heights should be multiples of 8 (or 4 for tighter control)
   - Text blocks should have vertical margins in multiples of 8
   - Text field padding should be in multiples of 8

4. **Implementation Tips**:
   - Define spacing constants to reuse throughout the app:
     ```dart
     class Spacing {
       static const double xs = 4;    // Extra small
       static const double s = 8;     // Small
       static const double m = 16;    // Medium
       static const double l = 24;    // Large
       static const double xl = 32;   // Extra large
       static const double xxl = 40;  // 2X large
       static const double xxxl = 48; // 3X large
     }
     ```
   - Use these constants for all padding and margin values
   - For vertical layouts, align content to an 8px baseline grid

5. **Component-Specific Guidelines**:
   - **Buttons**: 
     - Height: 40px or 48px
     - Horizontal padding: 16px or 24px
     - Corner radius: 8px, 16px, or 24px
   - **Cards**:
     - Padding: 16px or 24px
     - Margin between cards: 16px
     - Border radius: 8px or 16px
   - **Lists**:
     - Item height: multiples of 8px (usually 48px, 56px, or 64px)
     - Padding between items: 8px or 16px
   - **Forms**:
     - Field spacing: 16px or 24px
     - Field padding: 16px

**Layout Structure:**
- Use a 12-column grid for horizontal layouts
- Column gutters should be 16px or 24px (multiples of 8)
- Maintain 16px or 24px margins on the left and right edges

**Breaking the Rules:**
- While consistency is important, there are cases where breaking the grid makes sense
- Visual design may sometimes require values that aren't multiples of 8
- These exceptions should be deliberate and justified by better UX
- Document any intentional exceptions

By following the 8-point grid system, we ensure a consistent visual experience across the app while making development and collaboration more efficient.

---

### UI Improvements and Functionality Preservation

When making UI improvements or implementing design changes, it's essential to maintain the app's functionality. Follow these guidelines:

**Core Principles:**
- **Preserve all existing functionality** when updating the UI
- **Test thoroughly** after visual changes to ensure no features are broken
- **Maintain user workflows** even if the visual presentation changes
- **Document any intentional changes** to user interactions

**Best Practices:**
1. **Understand Before Modifying:**
   - Analyze how the existing UI components work before changing them
   - Identify event handlers, callbacks, and state management
   - Map out the user flow and interaction patterns

2. **Component Refactoring:**
   - When replacing a component, ensure all original behavior is transferred
   - Preserve all event handlers and callbacks
   - Maintain the same state management approach
   - Test all edge cases and interactions

3. **Visual vs. Functional Changes:**
   - Separate visual changes (styling, layout) from functional changes
   - Make visual changes in small, testable increments
   - Avoid changing both appearance and behavior in the same update

4. **Handling Dependencies:**
   - Check for dependencies on the component you're modifying
   - Ensure external components aren't relying on implementation details
   - Test related features after making changes

5. **Testing After UI Changes:**
   - Verify all interactive elements still work as expected
   - Test with different input methods (touch, keyboard)
   - Confirm that accessibility features are preserved
   - Validate across different screen sizes

6. **Documentation:**
   - Document UI changes that affect user interaction in panic_button_flutter/README.md and panic_button_flutter/DEVELOPMENT_GUIDELINES.md
   - Note any adjustments to component APIs 

**Visual Hierarchy Principles:**
- Maintain clear visual hierarchy for primary, secondary, and tertiary actions
- Follow consistent button styling based on action importance:
  - Primary actions: Most prominent, use primary color
  - Secondary actions: Less prominent, use secondary styling
  - Tertiary actions: Least prominent, use minimal styling
- Apply consistent interaction patterns across similar components

By following these guidelines, we ensure that UI improvements enhance the user experience without disrupting functionality or creating confusion.

---

### App Identity Management

- **Centralized Configuration Approach**
  - All app identity information is centralized in `lib/config/app_config.dart`
  - This class contains constants for:
    ```dart
    class AppConfig {
      static const String appDisplayName = "Calme";  // App name shown on device
      static const String appName = "Calme";         // Short name for general use
      static const String appDescription = "...";    // Description for app stores
      static const String bundleId = "com.breathmanu.calme";  // Bundle/application ID
      static const String companyName = "breathmanu.com";     // Company name
      // ... other app identity values
    }
    ```
  - Always reference these constants in code, never hardcode app name or identity values

- **App Identity Change Process**
  1. Update values in `lib/config/app_config.dart` first
  2. Run the update script to propagate changes:
     ```bash
     ./scripts/update_app_name.sh "NewAppName" "com.company.newappid"
     ```
  3. Verify changes were applied correctly to:
     - iOS Info.plist (`CFBundleDisplayName`, `CFBundleName`)
     - Android Manifest (`android:label`)
     - Android build.gradle (`applicationId`, `namespace`)
  4. Update any usage descriptions containing the app name
  5. Run a build and visually verify the changes

- **Manual Updates (when necessary)**
  - iOS Info.plist modifications:
    ```bash
    plutil -replace CFBundleDisplayName -string "NewName" ios/Runner/Info.plist
    plutil -replace CFBundleName -string "newname" ios/Runner/Info.plist
    ```
  - Android manifest modifications:
    ```bash
    sed -i '' "s/android:label=\".*\"/android:label=\"NewName\"/" android/app/src/main/AndroidManifest.xml
    ```
  - Build.gradle modifications:
    ```bash
    sed -i '' "s/applicationId = \".*\"/applicationId = \"com.company.newapp\"/" android/app/build.gradle.kts
    ```

- **App Identity Documentation**
  - All locations containing app identity info are documented in `APP_IDENTITY_LOCATIONS.md`
  - Refer to this document when implementing new features that display the app name
  - When adding new locations that use app identity, update this document

- **Future Improvements**
  - Next phase: Implement Flutter flavor system for environment-based configuration
  - Use xcconfig files for iOS to simplify variable substitution
  - Set up product flavors in Android build.gradle
  - Implement CI/CD automation for app identity management

### Responsive UI Guidelines

- **Device Size Detection**
  - Always use `MediaQuery` to adapt UI to screen dimensions:
    ```dart
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    ```
  - Account for system UI elements:
    ```dart
    final viewPadding = MediaQuery.of(context).viewPadding;
    final availableHeight = screenHeight - viewPadding.top - viewPadding.bottom;
    ```

- **Circular Widgets**
  - For buttons and visual elements, scale proportionally to screen width:
    ```dart
    // Example from PanicButton
    final buttonSize = screenSize.width < 360 ? 160.0 : 
                       screenSize.width < 400 ? 180.0 : 200.0;
    ```
  - Limit animation scaling to prevent overflow:
    ```dart
    // Example from BreathCircle
    final maxScaleFactor = screenSize.width < 360 ? 1.2 : 1.25;
    ```

- **Text Scaling**
  - Decrease font size on smaller screens for better fitting:
    ```dart
    // Example for responsive text
    final fontSize = screenSize.width < 360 ? 24 : 28;
    ```
  - Use MediaQuery's textScaleFactor for better accessibility support:
    ```dart
    final scaledFontSize = 16 * MediaQuery.of(context).textScaleFactor;
    ```

- **Layout Organization**
  - Use `Expanded` widgets and flex factors to distribute space proportionally
  - Add padding at the bottom of scrollable content to prevent navbar overlap:
    ```dart
    // Prevent content from being hidden behind navbar
    Padding(
      padding: const EdgeInsets.only(bottom: 70),
      child: /* content */
    )
    ```
  - For grids and collections, use `Wrap` for automatic flow:
    ```dart
    // Example from goal chips
    Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: /* items */
    )
    ```

- **Bottom Sheets and Modals**
  - Use explicit height calculations rather than percentages:
    ```dart
    constraints: BoxConstraints(
      maxHeight: availableHeight * 0.65, // Explicit max height
    ),
    ```
  - Include proper padding for the home indicator and notches:
    ```dart
    isScrollControlled: true,
    useSafeArea: true,
    ```

---

### Security Best Practices

- **Environment Variables**
  - **NEVER hardcode credentials** in the codebase
  - Use `String.fromEnvironment()` with build-time injection via `--dart-define` flags
  - Maintain a local `.env` file for development (add to `.gitignore`)
  - Use the `build_ios.sh` script which securely passes credentials at build time
  - The app uses a centralized environment configuration system:
    ```dart
    // Environment configuration in lib/config/env_config.dart
    class EnvConfig {
      // Private constructor to prevent instantiation
      EnvConfig._();
      
      // Retrieve values from Dart-define with empty defaults - must be const
      static const String _supabaseUrl = String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: '',
      );
      
      static const String _supabaseAnonKey = String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: '',
      );
      
      // Load .env file in debug mode
      static Future<void> load() async {
        if (kDebugMode) {
          try {
            await dotenv.load(fileName: '.env');
            debugPrint('🔑 Environment loaded from .env file');
          } catch (e) {
            debugPrint('⚠️ No .env file found or error loading it: $e');
          }
        }
      }
      
      // Getter methods with fallback logic (dart-define → .env → empty)
      static String get supabaseUrl {
        // Implementation with fallback logic...
      }
    }
    ```
  - **Development approaches:**
    ```bash
    # For VS Code development with .env:
    # Use the "Flutter (default)" launch configuration

    # For Chrome development:
    ./scripts/dev_run.sh -d chrome

    # For iOS simulator:
    ./scripts/dev_run.sh -d "iPhone"
    ```
  - **Production builds:**
    ```bash
    # For TestFlight:
    ./scripts/build_ios.sh --distribution=testflight
    
    # For App Store:
    ./scripts/build_ios.sh --distribution=appstore
    ```

- **Secure Logging**
  - **NEVER log sensitive information** such as:
    - API keys, tokens, or credentials
    - User IDs (full UUIDs)
    - User email addresses or personal information
  - Use conditional logging with `kDebugMode`:
    ```dart
    if (kDebugMode) {
      // Debug-only logs
      debugPrint('Uploading avatar (user ID: ${user.id.substring(0, 8)}...)');
    }
    ```
  - Truncate sensitive IDs in logs:
    ```dart
    // Bad:
    debugPrint('User ID: $userId');
    
    // Good:
    debugPrint('User ID: ${userId.substring(0, 8)}...');
    ```
  - When displaying credentials in logs, mask them properly:
    ```dart
    // Bad:
    debugPrint('Using key: $apiKey');
    
    // Good:
    final maskedKey = apiKey.length > 8 
      ? "${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}" 
      : "***";
    debugPrint('Using key: $maskedKey');
    ```

- **Secure Storage**
  - Use `flutter_secure_storage` for sensitive data like:
    - Authentication tokens
    - Refresh tokens
    - User credentials
  - **NEVER** store sensitive data in `SharedPreferences` or regular storage
  - iOS-specific security options:
    ```dart
    static const _options = IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    );
    ```

- **Database Access Security**
  - Always validate user input before using in queries
  - Use Supabase's method chaining for queries (safe from SQL injection)
  - Avoid string interpolation in database queries:
    ```dart
    // Bad:
    client.rpc('some_function', params: {'query': "name='$userInput'"});
    
    // Good:
    client.from('table').select().eq('name', userInput);
    ```
  - Always include user IDs in queries to leverage Row-Level Security

---

### iOS App Store Compliance

- **Privacy Declarations**
  - Add required usage descriptions to `Info.plist`:
    - `NSPhotoLibraryUsageDescription` - For profile photos
    - `NSCameraUsageDescription` - For taking profile photos
    - `NSHealthShareUsageDescription` - For health data integration
    - `NSHealthUpdateUsageDescription` - For health data updates
  - Add proper App Transport Security settings:
    ```xml
    <key>NSAppTransportSecurity</key>
    <dict>
      <key>NSAllowsArbitraryLoads</key>
      <false/>
    </dict>
    ```
  - Add non-exempt encryption declaration:
    ```xml
    <key>ITSAppUsesNonExemptEncryption</key>
    <false/>
    ```

- **Keychain Access**
  - Create `Runner.entitlements` file with proper app group identifiers:
    ```xml
    <key>keychain-access-groups</key>
    <array>
      <string>$(AppIdentifierPrefix)com.panicbutton.panicButtonFlutter</string>
    </array>
    ```

- **Build Configuration**
  - Minimum iOS version should be 14.0 or higher
  - Disable Bitcode (Apple removed support)
  - Use code obfuscation for production builds:
    ```bash
    flutter build ios --release --obfuscate --split-debug-info=build/ios/obfuscation
    ```

- **Medical App Requirements**
  - Include medical disclaimers in app description and within the app
  - Clarify that the app is not a diagnostic tool
  - Provide accurate descriptions of health-related features

---

### File Structure

```
lib/
├── screens/          # Main screen widgets
├── widgets/          # Reusable widgets
├── models/           # Data models
├── services/         # Business logic and API calls
│   └── secure_storage_service.dart  # Secure storage implementation
├── utils/            # Helper functions and utilities
├── constants/        # App-wide constants
├── providers/        # State management providers
├── data/             # Data repositories
└── config/           # Configuration files
    └── supabase_config.dart  # Environment-based configuration
```

---

### Breathing Feature Structure

The breathing feature follows a modular architecture with the following components:

```
lib/
├── screens/
│   └── breath_screen.dart           # Main breathing exercise screen
├── widgets/
│   ├── breath_circle.dart           # Animated breathing circle
│   ├── wave_animation.dart          # Wave animation inside circle
│   ├── duration_selector_button.dart # Duration selection widget
│   └── goal_pattern_sheet.dart      # Pattern selection sheet
├── models/
│   └── breath_models.dart           # Models for patterns, steps, etc.
├── providers/
│   ├── breathing_providers.dart     # State management for breathing
│   └── breathing_playback_controller.dart # Animation controller
└── data/
    └── breath_repository.dart       # Data access for breathing patterns
```

**Component Responsibilities:**

1. **Models**: Define data structures for breathing patterns
   - `PatternModel`: Core pattern data with name, goal, etc.
   - `StepModel`: Individual breathing step configuration
   - `ExpandedStep`: Runtime step model with all breathing parameters

2. **Repository**: Handle data access to Supabase
   - Get patterns by goal
   - Expand patterns into concrete steps
   - Log pattern usage

3. **Providers**: Manage application state
   - Selected pattern and duration
   - Expanded steps for the current pattern
   - Default pattern loading

4. **Playback Controller**: Control breathing animations
   - Track current phase (inhale, hold, exhale, relax)
   - Manage timers and phase transitions
   - Handle play/pause/reset

5. **UI Components**: Present interactive interface
   - Animated breathing circle with wave animation
   - Pattern and duration selection
   - Phase indicators with countdown

---

### Image Asset Management

- **Organization**
  - Store all images in `assets/images/` directory
  - Use snake_case for image filenames (e.g., `breathing_icon.png`)
  - Group related images with common prefixes (e.g., `breathwork_inhale.png`, `breathwork_exhale.png`)
  - Maintain separate directories for animations (`assets/animations/`) and icons (`assets/icons/`) when appropriate

- **Reference System**
  - Create a dedicated `constants/images.dart` file with an `Images` class
  - Use a private constructor (`Images._();`) to prevent instantiation
  - Define static constants for all image paths:
    ```dart
    class Images {
      Images._();  // Private constructor to prevent instantiation
      
      // BOLT Screen Images
      static const String pinchNose = 'assets/images/pinch_nose.png';
      static const String breathCalm = 'assets/images/breath_calm.png';
    }
    ```
  - Always access images through these constants, not string literals
  - Group related images with comments

- **Usage Best Practices**
  - Specify image dimensions explicitly when possible
  - Use standard sizes across the app for consistency
  - Consider conditional coloring based on theme:
    ```dart
    Image.asset(
      Images.someIcon,
      width: 24,
      height: 24,
      color: isActive ? cs.primary : cs.onSurface.withOpacity(0.6),
    )
    ```
  - Only include images that are actually being used
  - Document image asset requirements in PR descriptions

- **Asset Declaration**
  - Register all image directories in `pubspec.yaml` under the `assets` section
  - Use directory references for bulk imports:
    ```yaml
    assets:
      - assets/images/
      - assets/animations/
    ```

---

### Screen Transitions & Animations

- **Page Transitions**
  - Use the `animations` package for standard transitions between screens and components
  - Prefer `PageTransitionSwitcher` with `FadeThroughTransition` for multi-step UI flows:
    ```dart
    PageTransitionSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
        return FadeThroughTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      child: KeyedWidget(/* ... */),
    )
    ```
  - Use a `ValueKey` based on step number or other unique identifier:
    ```dart
    key: ValueKey<int>(_currentStep)
    ```
  - Set appropriate durations (recommended: 300-600ms)

- **Container Sizing for Smooth Transitions**
  - Use fixed or constrained sizes for containers that will change content:
    ```dart
    ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 300),
      child: Column(/* ... */),
    )
    ```
  - When fixed height is needed, use relative sizing:
    ```dart
    SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: /* ... */
    )
    ```
  - Use Card widgets with consistent padding for content that changes size

- **Component-Specific Animations**
  - Use AnimationControllers in StatefulWidget classes
  - Initialize controllers in initState and dispose them properly
  - Use .forward(), .reverse(), .reset() methods to control animations
  - Prefer explicit control over animation progress when synchronizing multiple animations

---

### Breathing Animation Guidelines

- **Circle Animation**
  - Use `AnimatedScale` for smooth size transitions during breathing phases
  - Apply easing curves for natural movement: `Curves.easeInOutCubic`
  - Scale values: 1.0 (base) to 1.3 (fully inhaled)
  - Add subtle oscillation during hold phases for organic feeling

- **Wave Animation**
  - Use `CustomPainter` with wave equations for fluid motion
  - Control fill level based on breathing phase (0.0 to 1.0)
  - Use slow animation controller (10-12 seconds per cycle)
  - Set wave parameters for natural movement:
    ```dart
    // Wave configuration example
    final amplitude = size.width * 0.05;
    final frequency = 0.5;
    final horizontalShift = animation.value * 2 * math.pi;
    ```

- **Phase Transitions**
  - Make phase text changes with fade transitions
  - Use countdown timer with whole number display
  - Ensure transitions between phases feel smooth and natural
  - Don't rush transitions; allow slight overlap (100-200ms)

---

### Naming Conventions

- **Files:** snake_case (`user_profile_screen.dart`)  
- **Classes:** PascalCase (`UserProfileScreen`)  
- **Variables:** camelCase (`userName`)  
- **Constants:** SCREAMING_SNAKE_CASE (`MAX_RETRY_ATTEMPTS`)  
- **Private members:** `_prefixUnderscore` (`_handleSubmit`)

---

### Component Architecture

- **Component Extraction Guidelines**
  - Extract a widget when it:
    - Exceeds 50-75 lines of code in a build method
    - Has a distinct visual and/or logical purpose
    - Is reused across multiple places
    - Manages its own animations or state
    - Would benefit from isolated testing
  
  - Widget categories to consider extracting:
    - Containers with complex decoration (e.g., `BreathCircle`)
    - Custom animations (e.g., `WaveAnimation`)
    - Text displays with formatting (e.g., `RemainingTimeDisplay`)
    - UI elements that show/hide based on state (e.g., `PhaseIndicator`)
    - Interactive controls (e.g., `DurationSelectorButton`)

  - Naming conventions:
    - Widget should describe its visual or functional role
    - Name should not include parent screen (prefer `ProfileCard` over `ProfileScreenCard`)
    - Keep related widgets in the same file if under ~200 total lines
    - For larger related widgets, create a subdirectory in `/widgets`

  - APIs and parameters:
    - Only pass what the widget needs to function
    - Use callbacks for actions (e.g., `onTap`, `onPressed`)
    - Keep constructor parameters simple and focused
    - Document non-obvious parameters with comments

---

### Multi-Step UI Flows

- **Define Clear Steps**
  - Create an enum or integer constants for step states
  - Store current step in state variable
  - Use switch statements or if/else blocks to determine UI display

- **Progress Control**
  - Implement both automatic and manual progression options
  - For timed progressions, show clear countdowns:
    ```dart
    Text(
      displayCountdown.toString(),
      style: tt.displayLarge,
    )
    ```
  - For manual progression, use prominent buttons:
    ```dart
    ElevatedButton(
      onPressed: _advanceToNextStep,
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primary,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
      child: const Text('SIGUIENTE'),
    )
    ```

- **Step-Specific Behaviors**
  - Manage state transitions in dedicated methods:
    ```dart
    void _advanceToNextStep() {
      setState(() {
        _currentStep++;
        // Initialize phase-specific variables
      });
      
      // Start timers or animations if needed
      if (_currentStep == 1) {
        _startSomeTimer();
      }
    }
    ```
  - Encapsulate step-specific logic in separate methods
  - Use callbacks for completion notification

---

### Animation Best Practices

- **Separate Animation Logic from UI**
  - Place animation controllers and logic in the parent widget
  - Pass animation values or animation objects to child components
  - Use callbacks to synchronize animation phases

- **Animation Safety**
  - Always check `mounted` before calling `setState()` in animation callbacks
  - Clean up animation controllers in `dispose()` method
  - Use `Future.delayed` with mount checks for any delayed state updates:
    ```dart
    Future.delayed(duration, () {
      if (!mounted) return;
      setState(() { /* update state */ });
    });
    ```

- **Custom Painting**
  - Use `CustomPainter` for complex animations like fluid effects
  - Break down complex paint operations into smaller methods
  - Optimize `shouldRepaint()` to return true only when relevant properties change
  - Consider using shaders for gradients and effects

- **Performance**
  - Prefer `AnimatedBuilder` with isolated rebuild scopes
  - For repeated animations, use longer durations (3-5s) with repeat
  - Use `Curves` (e.g., `Curves.easeInOut`) for natural motion
  - Avoid animating in the build method directly

---

### Database Schema

Database structure for breathing exercise can be found at: [DatabaseLogic.md](./DatabaseLogic.md)

The breathing feature uses the following database structure:

```sql
-- Breathing patterns database schema
CREATE TABLE breathing_goals (
  id UUID PRIMARY KEY,
  slug TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  description TEXT
);

CREATE TABLE breathing_patterns (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  goal_id UUID REFERENCES breathing_goals(id),
  recommended_minutes INT DEFAULT 3,
  cycle_secs INT,
  slug TEXT UNIQUE  -- Added for journey integration
);

CREATE TABLE breathing_steps (
  id UUID PRIMARY KEY,
  cue_text TEXT,
  inhale_secs INT NOT NULL,
  hold_in_secs INT DEFAULT 0,
  exhale_secs INT NOT NULL,
  hold_out_secs INT DEFAULT 0,
  inhale_method TEXT DEFAULT 'nose',
  exhale_method TEXT DEFAULT 'mouth'
);

CREATE TABLE breathing_pattern_steps (
  pattern_id UUID REFERENCES breathing_patterns(id),
  step_id UUID REFERENCES breathing_steps(id),
  sort_order INT NOT NULL,
  repetitions INT DEFAULT 1,
  PRIMARY KEY (pattern_id, step_id)
);

CREATE TABLE breathing_pattern_status (
  user_id UUID REFERENCES auth.users(id),
  pattern_id UUID REFERENCES breathing_patterns(id),
  last_run TIMESTAMPTZ,
  total_runs INT DEFAULT 0,
  total_seconds INT DEFAULT 0,  -- Tracks cumulative breathing time
  PRIMARY KEY (user_id, pattern_id)
);

CREATE TABLE breathing_activity (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  pattern_id UUID REFERENCES breathing_patterns(id) NOT NULL,
  started_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  duration_seconds INTEGER NOT NULL,
  completed BOOLEAN DEFAULT false,
  expected_duration_seconds INTEGER,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
```

Notes:
- The schema directly links patterns to steps, without the routine layer
- Patterns include metadata like recommended_minutes, cycle_secs, and slug
- Pattern usage is tracked in breathing_pattern_status
- Detailed activity tracking in breathing_activity

### Breathing Activity Tracking Guidelines

1. **When to Create Activity Records**
   - Create a new activity record when a user starts a breathing session
   - Initial record should have duration_seconds=0 and completed=false
   - Update the record when the session ends or is abandoned

2. **Session Duration Requirements**
   - Only count sessions longer than 10 seconds toward user statistics
   - For very short sessions, don't update the breathing_pattern_status table
   - Enforce minimum duration via triggers and application logic

3. **Pause/Resume Handling**
   - When a user pauses, keep the same activity record
   - Track accumulated time even across multiple pauses
   - Don't reinitialize the controller when resuming
   - Ensure that the play/pause button doesn't create new records

4. **Database Updates**
   - Update breathing_pattern_status automatically via triggers
   - Use total_seconds for cumulative statistics
   - Store expected_duration_seconds to track intended vs. actual practice time
   - Always include user_id for row-level security

5. **Journey Integration**
   - Use pattern slugs to connect breathing patterns to journey levels
   - Allow direct navigation from journey to specific patterns via slugs
   - Ensure slugs are unique and follow consistent naming (snake_case)

### Metric Measurement Architecture

The app provides a reusable architecture for implementing different types of breathing metric measurements (like BOLT, CO2 tolerance, etc.). This modular design allows for creating consistent UI experiences while configuring different measurement metrics.

#### Core Components

1. **MetricConfig Model**
   - Defines a measurement metric with configurable properties
   - Contains name, description, instructions, zones (for score interpretation)
   - Provides methods for assessing score values and zone determination
   - Example implementation:
     ```dart
     MetricConfig boltConfig = MetricConfig(
       name: 'BOLT',
       description: 'Body Oxygen Level Test',
       instructions: [
         // Step-by-step instructions
       ],
       zones: [
         MetricZone(min: 0, max: 20, label: 'Bajo', color: Colors.red),
         MetricZone(min: 20, max: 30, label: 'Medio', color: Colors.amber),
         MetricZone(min: 30, max: double.infinity, label: 'Alto', color: Colors.green),
       ],
       unitLabel: 'segundos',
     );
     ```

2. **MetricScore Models**
   - Handles storing and processing metric scores
   - Provides different aggregation options (day, week, month)
   - Includes historical analysis calculations
   - Supports both numeric and subjective measurements

3. **Reusable UI Components**
   - **MetricScreen**: Base screen that adapts to any metric configuration
   - **MetricInstructionsCard**: Shows 3-step instructions with "COMENZAR" button
   - **MetricMeasurementUI**: Handles timer and results display
   - **MetricInstructionOverlay**: Step-by-step guided instructions
   - **MetricScoreInfoDialog**: Explains score meanings and zones
   - **ScoreChart**: Visualizes historical scores with configurable time periods

#### Implementation Flow

1. **Create Metric Configuration**
   - Define a new `MetricConfig` with appropriate parameters
   - Specify zones, instructions, and scoring methodology
   - Add any metric-specific parameters

2. **Register Metric Provider**
   - Create a provider that exposes the metric configuration
   - Implement data loading/saving logic
   - Define metric-specific calculations if needed

3. **Create Screen Instance**
   - Use the `MetricScreen` widget with your configuration
   - Customize content if needed
   - Add navigation to your new metric screen

4. **Database Integration**
   - Create appropriate tables for storing metric scores
   - Implement repository logic for data access
   - Use consistent naming conventions


#### Example: MBT Implementation

The MBT (Maximum Breathlessness Test) implementation demonstrates the framework's flexibility for different measurement types:

```dart
// MBT Metric Configuration
final mbtMetricConfig = MetricConfig(
  id: 'mbt',
  displayName: 'MBT',
  tableName: 'mbt_scores',
  description: 'La prueba MBT mide tu tolerancia al esfuerzo respiratorio. Camina contando pasos mientras retienes la respiración.',
  scoreFieldName: 'steps',
  
  // Score zones based on step count (0-200 range)
  scoreZones: [
    MetricScoreZone(lowerBound: 0, upperBound: 20, label: '<20 - Pánico Constante', color: Colors.redAccent),
    MetricScoreZone(lowerBound: 20, upperBound: 40, label: '20-40 - Inquieto/Irregular', color: Colors.amber),
    MetricScoreZone(lowerBound: 40, upperBound: 60, label: '40-60 - Calma Parcial', color: Colors.lightGreen),
    MetricScoreZone(lowerBound: 60, upperBound: 90, label: '60-90 - Tranquilo/Estable', color: Colors.teal),
    MetricScoreZone(lowerBound: 90, upperBound: 130, label: '90-130 - Zen/Inmune', color: Colors.blue),
    MetricScoreZone(lowerBound: 130, upperBound: 200, label: '130+ - Beyond Zen', color: Colors.indigo),
  ],
  
  // Detailed instruction steps with timed breathing phases
  detailedInstructions: [
    MetricInstructionStep(stepNumber: 1, description: 'Inhala normal', isTimedStep: true, durationSeconds: 5),
    MetricInstructionStep(stepNumber: 2, description: 'Exhala normal', isTimedStep: true, durationSeconds: 5),
    MetricInstructionStep(stepNumber: 3, description: 'Pincha tu nariz (retén el aire)', imagePath: Images.pinchNose),
    MetricInstructionStep(stepNumber: 4, description: 'Camina contando tus pasos hasta llegar al máximo', icon: Icons.directions_walk),
    MetricInstructionStep(stepNumber: 5, description: 'Detente cuando sientas un deseo intenso de respirar', icon: Icons.stop_circle),
  ],
  
  // Compact steps for summary view
  compactSteps: [
    MetricInstructionStep(stepNumber: 1, description: 'Retén\nrespiración', imagePath: Images.pinchNose),
    MetricInstructionStep(stepNumber: 2, description: 'Camina\ncontando', icon: Icons.directions_walk),
    MetricInstructionStep(stepNumber: 3, description: 'Selecciona\npasos', icon: Icons.edit),
  ],
);

// Usage in navigation
GoRoute(
  path: '/mbt',
  builder: (context, state) => MbtScreen(), // Custom screen for step selection UI
)
```


#### Guidelines for Adding New Metrics

1. **Start from Reference Implementation**
   - Use the BOLT (panic_button_flutter/lib/screens/bolt_screen.dart) implementation as a starting point
   - Copy and adapt the metric configuration
   - Reuse UI components for consistency

2. **Maintain Consistent UX**
   - Keep the same 3-step instruction pattern
   - Maintain a similar scoring approach (unless metric requires otherwise)
   - Use consistent zone coloring for comparable metrics

3. **Testing New Metrics**
   - Test all instruction phases
   - Verify score recording and visualization
   - Check responsiveness on different screen sizes

4. **Documentation**
   - Add metric-specific documentation
   - Document any unique scoring properties
   - Update navigation documentation if needed

---
### Route Names

- All lowercase  
- Use hyphens for readability  
- Examples: `/user-profile`, `/breathing-exercise`

### Route Parameters and Navigation Context

- Use route parameters for specific screens (e.g., `/breath/:patternSlug`)
- Pass contextual information via the `extra` parameter in Go Router:
  ```dart
  context.go('/breath/coherent_4_6', extra: {'fromHome': true});
  ```
- Document route parameters and expected `extra` values in comments
- Use consistent parameter names across the codebase

### Breathing Exercise Auto-Start Behavior

- **Auto-Start Rules**:
  - The breathing exercise should ONLY auto-start when navigating from the home screen
  - All other navigation paths should require manual start by the user
  - The `fromHome` flag in the route's `extra` parameter controls this behavior:
    ```dart
    // In PanicButton widget
    context.go('/breath/coherent_4_6', extra: {'fromHome': true});
    
    // In router configuration
    GoRoute(
      path: '/breath/:patternSlug',
      builder: (context, state) {
        final patternSlug = state.pathParameters['patternSlug'];
        final fromHomePage = state.extra is Map && 
            (state.extra as Map)['fromHome'] == true;
        return BreathScreen(patternSlug: patternSlug, autoStart: fromHomePage);
      },
    ),
    ```
  - Verify this behavior when modifying navigation code

---

### Error Handling

- **User-facing errors in Spanish**  
- **Log technical errors in English**  
- Include error codes for debugging  
- Provide helpful recovery actions

---

### State Management

- Use providers for app-wide state  
- Local state with `setState()` when appropriate  
- Document state dependencies  
- Handle loading and error states

---

### Code Style

- Use consistent indentation (2 spaces)  
- Group related properties together  
- Order: constructors, lifecycle methods, public methods, private methods  
- Add comments for complex logic  
- Use meaningful variable names

---

### Code Modernization & Best Practices

- **Color Opacity Handling**
  - ❌ Avoid using deprecated `.withOpacity(x)` method:
    ```dart
    // Deprecated approach
    color.withOpacity(0.5)
    ```
  
  - ✅ Use `.withAlpha((x * 255).toInt())` instead:
    ```dart
    // Modern approach
    color.withAlpha((0.5 * 255).toInt())  // 128 alpha value
    ```
  
  - Common alpha value conversions:
    | Opacity | Alpha Value (int) |
    |---------|------------------|
    | 0.1     | 25               |
    | 0.2     | 51               |
    | 0.4     | 102              |
    | 0.5     | 128              |
    | 0.6     | 153              |
    | 0.8     | 204              |
    | 1.0     | 255              |

- **Theme Color Scheme Updates**
  - ❌ Avoid using deprecated `onBackground` in color schemes:
    ```dart
    // Deprecated approach
    Theme.of(context).colorScheme.onBackground
    ```
  
  - ✅ Use `onSurface` instead:
    ```dart
    // Modern approach
    Theme.of(context).colorScheme.onSurface
    ```

- **Type Casting Best Practices**
  - ❌ Avoid unnecessary type casting when type is already inferred:
    ```dart
    // Unnecessary cast
    final data = await client.from('table').select().single() as Map<String, dynamic>;
    ```
  
  - ✅ Let Dart inference handle simple cases:
    ```dart
    // Better approach
    final data = await client.from('table').select().single();
    ```
  
  - ✅ When conversion is needed, use safer methods:
    ```dart
    // Safe conversion
    final stepsData = Map<String, dynamic>.from(stepData['breathing_steps']);
    ```

- **Logging Best Practices**
  - ❌ Avoid using `print()` statements:
    ```dart
    // Not recommended
    print("User logged in: $userId");
    ```
  
  - ✅ Use `debugPrint()` for improved handling:
    ```dart
    // Better approach
    debugPrint("User logged in: ${userId.substring(0, 8)}...");
    ```
  
  - ✅ Conditional logging in production:
    ```dart
    // Best practice
    if (kDebugMode) {
      debugPrint("Session details: $sessionData");
    }
    ```

- **Layout Structure for Responsive UI**
  - ❌ Avoid fixed positioning with `Stack` and `Positioned` for basic layouts:
    ```dart
    // Less flexible approach
    Stack(
      children: [
        // Main content
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: CustomNavBar(),
        ),
      ],
    )
    ```
  
  - ✅ Use standard Scaffold properties for common UI elements:
    ```dart
    // Better approach
    Scaffold(
      body: /* main content */,
      bottomNavigationBar: const CustomNavBar(currentIndex: 1),
    )
    ```
  
  - ✅ Center content for better responsiveness:
    ```dart
    // Responsive layout
    Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: /* content */,
          ),
        ),
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 0),
    )
    ```

Following these practices ensures our app remains compatible with the latest Flutter versions, performs better, and maintains a clean and maintainable codebase.

---

## Additional Guidelines for Performance & Quality

### Widget & Build Optimization

- **Use `const` constructors wherever possible** to reduce widget rebuilds.  
- **Prefer `const` values** for static styling (e.g. `const EdgeInsets.symmetric(...)`).  
- **Avoid deeply nested widget trees**; break complex layouts into small, reusable widgets.  
- **Minimize work in `build()`**; move heavy computations or I/O into `initState`, providers, or services.

---

### Performance Best Practices

- **Profile in release mode** using DevTools' performance tab before each release.  
- **Debounce rapid state changes** (e.g. typing, sliders) to avoid jank.  
- **Cache images** with `CachedNetworkImage` or via Supabase's CDN headers.  
- **Use `RepaintBoundary`** around heavy animations or custom-paint widgets to isolate repaints.

---

### Testing & Quality Assurance

- **Widget tests** for each screen: verify presence of key widgets and callbacks.  
- **Unit tests** for providers/services logic (e.g. `SupabaseService.uploadAvatar`).  
- **Golden tests** for critical UI flows (e.g. dark vs. light mode).  
- **CI integration:** run `flutter test --coverage` on every PR and block merges on regressions.

---

### Accessibility & Internationalization

- **Add semantic labels** (`Semantics(label: 'Cambiar avatar')`) to interactive widgets.  
- **Ensure minimum tap target of 48×48 dp** for all buttons and icons.  
- **Use `flutter_localizations`** for date, number, and plural handling if expanding beyond Spanish.

---

### Dependency & Version Management

- **Lock package versions** in `pubspec.yaml` and commit `pubspec.lock`.  
- **Audit transitive dependencies** regularly for security or performance issues.  
- **Prefer first‑party Flutter/Dart packages** over unmaintained forks.

---

### Error Reporting & Logging

- **Report runtime exceptions** with Sentry or a crash service (technical logs in English).  
- **Use structured logs** (e.g. `logger.i('Avatar upload succeeded', {'userId': user.id});`).  
- **Differentiate dev vs. prod logging** (e.g. suppress verbose logs in `kReleaseMode`).

---

### Continuous Integration & Delivery

- **Automate formatting:** add a `pre-commit` hook for `flutter format` and `flutter analyze`.  
- **Run `flutter analyze --fatal-infos`** in CI to catch lints early.  
- **Automate releases** with Fastlane or GitHub Actions, tagging each build.

---

*These guidelines ensure that our PanicButton app remains performant, accessible, and easy to maintain as it grows.*

### App Icon Management

- **Icon Creation & Format**
  - Create square icons with 1024x1024px resolution minimum
  - Use PNG format with clear background (transparency will be handled by the generator)
  - Place icons in the `assets/icons/` directory
  - Follow the PanicButton design system for colors and styling
  - Avoid text in app icons as they'll be too small to read

- **Configuration**
  - Use `flutter_launcher_icons` package for icon generation:
    ```yaml
    flutter_icons:
      android: "launcher_icon"    # Name for Android icon
      ios: true                   # Generate iOS icons
      remove_alpha_ios: true      # Remove transparency for iOS
      image_path: "assets/icons/app_icon_3d.png"  # Path to your icon
      min_sdk_android: 21         # Android min SDK version
      adaptive_icon_background: "#FFFFFF"  # Background color for adaptive icons
      
      # Web icons configuration
      web:
        generate: true
        image_path: "assets/icons/app_icon_3d.png"
        background_color: "#FFFFFF"
        theme_color: "#FFFFFF"
        
      # Windows configuration (requires Windows setup)
      windows:
        generate: true
        image_path: "assets/icons/app_icon_3d.png"
        icon_size: 48  # Size in pixels (min 48, max 256)
    ```

- **Generation Process**
  - Generate icons with command:
    ```bash
    flutter pub run flutter_launcher_icons
    ```
  - Verify outputs in platform-specific directories:
    - Android: `android/app/src/main/res/mipmap-*/`
    - iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
    - Web: `web/icons/` and `web/favicon.png`
  - Commit generated files to git

- **Guidelines for Icon Design**
  - Use a simple, recognizable shape that works at small sizes
  - Ensure good contrast for visibility on different backgrounds
  - Test on both light and dark device themes
  - Follow platform-specific guidelines (especially for adaptive icons on Android)

---

### TestFlight & App Store Deployment

Script has been created to do this almost automatically find it at: panic_button_flutter/scripts/build_ios.sh

- **Pre-deployment Checklist**
  - Version number updated in `pubspec.yaml`
  - Screenshots captured for all required device sizes
  - App icons generated and verified
  - Required usage descriptions added to Info.plist
  - Build version incremented for each submission

- **Code Signing Setup**
  1. Open Xcode → Preferences → Accounts → Add Apple ID
  2. Select Runner project → Runner target → Signing & Capabilities
  3. Enable "Automatically manage signing"
  4. Select your Development Team 
  5. Ensure Bundle Identifier is unique (e.g., `com.panicbutton.app`)

- **Build Process**
  1. Create a release build:
     ```bash
     flutter build ios --release
     ```
  2. Open Xcode and select a physical device (or "Any iOS Device")
  3. Go to Product → Archive
  4. When Archive completes, click "Distribute App"
  5. Select "App Store Connect" → "Upload" → follow prompts

- **TestFlight Configuration**
  1. Log into [App Store Connect](https://appstoreconnect.apple.com)
  2. Go to "My Apps" → select your app → TestFlight tab
  3. Wait for build processing (typically 15-30 minutes)
  4. Complete required compliance information
  5. Add test information (what to test, instructions)
  6. Configure testers:
     - Internal testers (limited to your development team)
     - External testers (require email invitation and Beta App Review)

- **Beta App Review Guidelines**
  - Allow 1-2 days for Beta App Review process
  - Provide clear testing instructions
  - If using External TestFlight, ensure your app follows App Store Guidelines
  - If rejected, fix issues and upload a new build with incremented build number

- **Common TestFlight Issues**
  - Privacy declarations missing in Info.plist
  - App crashes on launch (test thoroughly before submission)
  - Missing export compliance information
  - Sensitive API usage without justification
  - Unable to test core functionality

- **Troubleshooting**
  - If upload fails, check Apple Developer account status and certificates
  - For processing issues, verify app size and try an .ipa export (Product → Archive → "Export" → "Export as .ipa")
  - For binary validation errors, check build logs for details
  - For TestFlight rejections, carefully read the resolution steps in the review notes

---

### Audio Integration Best Practices

The app includes a comprehensive audio system for breathing exercises with advanced session management and automatic pausing capabilities. The system underwent major architectural improvements to provide persistent sessions and robust error handling. Follow these guidelines:

1. **Session Management & Lifecycle Architecture**
   - **Session State Machine**: Comprehensive state tracking with 4 distinct states:
     - `notStarted`: Initial state, shows pattern/duration selectors
     - `playing`: Active breathing session with audio/visual guidance
     - `paused`: Session suspended, preserving progress and allowing resume
     - `finished`: Session completed or stopped, ready for new session
   
   - **Persistent Sessions**: Sessions survive navigation and app backgrounding:
     - User can navigate away and return to find session in paused state
     - Session progress (accumulated time) is preserved
     - Audio state (background music selection) is restored on resume
   
   - **RouteObserver Integration**: Automatic session management:
     - Sessions automatically pause when user navigates to other screens
     - Audio is stopped to prevent background playback during navigation
     - No manual intervention required from user to maintain session state
   
   - **Enhanced Lifecycle Management**:
     - Proper widget disposal prevents memory leaks and crashes
     - Safe provider access with disposal checks throughout async operations
     - Graceful handling of widget state changes during navigation

2. **Audio Layer Architecture**
   - The audio system uses a three-layer approach:
     - **Background Music**: Ambient sounds for relaxation (river, rain, forest)
     - **Instrument Cues**: Audio cues that play at the start of inhale and exhale phases (replacing the old tones system)
     - **Voice Guidance**: Verbal instructions synchronized with breathing

3. **Instrument Cues System (New Implementation)**
   - **Purpose**: Provides precise audio cues at the beginning of inhale and exhale phases during breathing exercises
   - **Key Features**:
     - Phase-specific playback (inhale and exhale only, no hold phases)
     - Precise timing control with automatic stop at phase transitions
     - Multiple instrument options: gong, synth, violin, human, and off
     - Persistent user preferences across sessions
     - Cross-platform compatibility (Android, iOS, Web)
   
   - **Technical Implementation**:
     ```dart
     // New enums for instrument cues
     enum Instrument { gong, synth, violin, human, off }
     enum BreathInstrumentPhase { inhale, exhale }
     
     // Key method for playing instrument cues
     Future<void> playInstrumentCue(
       Instrument instrument,
       BreathInstrumentPhase phase,
       int phaseDurationSeconds,
     )
     ```
   
   - **Asset Structure**:
     ```
     assets/sounds/instrument_cues/
     ├── gong/
     │   ├── inhale_gong.mp3
     │   └── exhale_gong.mp3
     ├── synth/
     │   ├── inhale_synth.mp3
     │   └── exhale_synth.mp3
     └── [other instruments...]
     ```
   
   - **Integration with Breathing Controller**:
     - Triggered in `_moveToNextPhase()` method of `BreathingPlaybackController`
     - Only plays for inhale and exhale phases (skips hold phases)
     - Uses timer-based precision to stop audio exactly at phase transitions
     - Handles cases where audio file duration exceeds phase duration

4. **File Format & Organization**
   - **File Format**: Use MP3 over WAV for several advantages:
     - Significantly smaller file size (often 10x smaller)
     - Excellent quality-to-size ratio for voice and ambient sounds
     - Universal platform compatibility
     - Lower memory and CPU usage during playback
   - **Directory Structure**:
     ```
     assets/
     └── sounds/
         ├── music/      # Background ambient sounds
         ├── instrument_cues/  # NEW: Breathing phase indicator sounds (replaces tones/)
         │   ├── gong/
         │   ├── synth/
         │   ├── violin/
         │   └── human/
         └── guiding_voices/  # Voice guidance recordings with multiple characters
             ├── manu/
             │   ├── inhale/
             │   ├── pause_after_inhale/
             │   ├── exhale/
             │   └── pause_after_exhale/
             └── andrea/
                 ├── inhale/
                 ├── pause_after_inhale/
                 ├── exhale/
                 └── pause_after_exhale/
     ```
   - Register sound directories in `pubspec.yaml`:
     ```yaml
     assets:
       - assets/sounds/music/
       - assets/sounds/instrument_cues/
       - assets/sounds/instrument_cues/gong/
       - assets/sounds/instrument_cues/synth/
       - assets/sounds/instrument_cues/violin/
       - assets/sounds/instrument_cues/human/
       - assets/sounds/guiding_voices/
       # ... other voice directories
     ```

5. **Safe Audio Management**
   - **Memory Leak Prevention**:
     - Store audio service references early in widget lifecycle:
       ```dart
       // In initState
       _audioService = ref.read(audioServiceProvider);
       ```
     - Add disposal flag to prevent accessing disposed widgets:
       ```dart
       bool _isDisposed = false;
       
       @override
       void dispose() {
         _isDisposed = true;
         super.dispose();
         // Use stored references instead of accessing providers
         if (_audioService != null) {
           _audioService!.stopAllAudio();
         }
       }
       ```
     - Always check disposal state before operations:
       ```dart
       if (_isDisposed) return;
       ```

   - **Provider Access Safety**:
     - Get all provider references upfront before async operations
     - Store references locally instead of accessing providers after async gaps
     - Add disposal checks after every await

6. **UI Integration**
   - Provide clear audio controls with proper labeling
   - Use bottom sheets for audio selection interfaces
   - Include visual feedback when audio tracks are playing
   - Initialize default tracks when none are selected
   - **Instrument Selection**: New "Instrumentos" section in AudioSelectionSheet with circular buttons and visual feedback

7. **Default Audio Selection Logic**
   ```dart
   void _setDefaultAudioIfNeeded() {
     if (_isDisposed) return;
     
     // Set default instrument if none is selected (gong is default)
     final currentInstrument = ref.read(selectedInstrumentProvider);
     if (currentInstrument == Instrument.off) {
       ref.read(selectedInstrumentProvider.notifier)
          .selectInstrument(Instrument.gong);
     }
     
     // ... other default audio settings
   }
   ```

8. **Audio Performance & Mobile Compatibility**
   - Preload audio files for key interactions
   - Handle audio focus changes (e.g., phone calls interrupting)
   - Add progressive volume transitions for smoother experience
   - **Enhanced Retry Logic**: Implement robust retry mechanism for iOS "Operation Stopped" errors:
     - Use 3 retry attempts (increased from 2)
     - Progressive delays of 200ms between retries (increased from 100ms)
     - Proper error logging for debugging
   - **Asset Path Resolution**: Automatic directory structure mapping for voice prompts:
     - Convert camelCase enum values to snake_case directory names
     - Handle `pauseAfterInhale` → `pause_after_inhale` conversion
     - Ensure proper `assets/` prefix for Flutter asset loading
   - **Resource Management**: Clean audio player state between operations:
     - Stop existing audio before starting new playback
     - Add 50ms delays for iOS audio system stability
     - Proper timer cleanup and cancellation
   - Reduce excessive logging in production builds
   - **Precise Timing Control**: Use Timer-based stopping for instrument cues to ensure they don't overlap phases

9. **Testing Audio Integration**
   - Test navigation between screens multiple times to verify no leaks
   - Test device sleep/wake behavior with active audio
   - Test with different audio output devices (speaker, headphones)
   - **Test Instrument Cues**: Verify cues play only at phase starts and stop precisely at transitions
   - **Mobile-Specific Testing**:
     - Test on both iOS and Android devices for platform-specific issues
     - Verify asset loading across different file structures
     - Monitor console logs for "Operation Stopped" or asset loading errors
     - Test breathing patterns with all voice characters (Manu, Andrea)
     - Validate instrument cues work with all types (gong, synth, violin, human)
     - Test audio restoration after app backgrounding/foregrounding

10. **Troubleshooting Audio Issues**
   - **Asset Loading Failures**:
     - Check file paths match actual directory structure exactly
     - Verify `pubspec.yaml` includes all required asset directories
     - Ensure file names follow snake_case convention for voice directories
   - **"Operation Stopped" Errors on iOS**:
     - Verify retry logic is properly implemented with sufficient delays
     - Check for multiple simultaneous audio operations
     - Ensure proper audio player cleanup between operations
   - **Directory Structure Issues**:
     - Voice files must use snake_case: `pause_after_inhale`, not `pauseAfterInhale`
     - Instrument files follow pattern: `{phase}_{instrument}.mp3`
     - All paths need proper `assets/` prefix for Flutter asset loading
   - **Performance Issues**:
     - Monitor memory usage during extended breathing sessions
     - Check for audio player resource leaks
     - Verify timers are properly cancelled when switching phases

10. **Migration from Tones to Instrument Cues**
   - **Removed**: `AudioType.breathGuide`, `_breathGuidePlayer`, tones asset directory
   - **Added**: `AudioType.instrumentCue`, `_instrumentPlayer`, instrument cues asset structure
   - **Updated**: Audio selection UI, default settings, state management providers
   - **Maintained**: All existing functionality while improving precision and user experience

Following these guidelines ensures audio integration that enhances the user experience while maintaining app stability and performance.

**For detailed technical information about recent audio system improvements, see**: `development_guidelines_extradocs/improved_breathing_screen_playback_logic.md`

---

### Adding or Updating Sound Assets - Step by Step Guide

This guide explains the complete process for adding new sound files or replacing existing ones in the app.

#### 1. Prepare Your Sound Files

- **Format Requirements**:
  - Use MP3 format (preferred over WAV for size and performance)
  - Recommended bitrate: 192kbps for music, 128kbps for voice and tones
  - Maximum file size: Keep background music under 2MB, tones/voice under 500KB
  - Recommended duration:
    - Background music: 1-3 minutes (will loop automatically)
    - Tones: 1-3 seconds
    - Voice: Short phrases (2-5 seconds)
  
- **Audio Processing Tips**:
  - Normalize audio to -3dB peak level
  - Apply gentle compression (2:1 ratio) for voice recordings
  - Remove background noise and hiss
  - Add a short fade-in/fade-out (50-100ms) to prevent clicks
  - For looping music, ensure seamless loop points

#### 2. Add Sound Files to the Project

- **File Placement**:
  Place your prepared audio files in the appropriate directory based on type:
  
  ```
  panic_button_flutter/
  └── assets/
      └── sounds/
          ├── music/      # Place background music files here
          ├── instrument_cues/  # Place breath guide tone files here
          └── guiding_voices/  # Place voice guidance files here
  ```

- **File Naming Conventions**:
  - Use lowercase letters and underscores only
  - Use simple, descriptive names (e.g., `gentle_river.mp3`, `deep_tone.mp3`)
  - Avoid spaces, special characters, or version numbers in filenames
  
- **Example**:
  ```bash
  # Example command to copy a new music file to the correct location
  cp ~/Downloads/gentle_forest.mp3 panic_button_flutter/assets/sounds/music/
  ```

#### 3. Register New Files in the Audio Service

- **Update Track Lists**:
  Open `lib/services/audio_service.dart` and locate the appropriate track list constants:
  
  ```dart
  // For background music
  static const List<AudioTrackInfo> _backgroundMusicTracks = [
    AudioTrackInfo(id: 'river', name: 'Río', fileName: 'river.mp3'),
    AudioTrackInfo(id: 'forest', name: 'Bosque', fileName: 'forest_ambience.mp3'),
    // Add your new track here:
    AudioTrackInfo(id: 'gentle_forest', name: 'Bosque Suave', fileName: 'gentle_forest.mp3'),
  ];
  
  // For breath guide tones
  static const List<AudioTrackInfo> _breathGuideTracks = [
    AudioTrackInfo(id: 'sine', name: 'Suave', fileName: 'sine.mp3'),
    AudioTrackInfo(id: 'bowl', name: 'Cuenco', fileName: 'bowl.mp3'),
    // Add your new track here
  ];
  
  // For voice guidance
  static const List<AudioTrackInfo> _voiceGuidanceTracks = [
    AudioTrackInfo(id: 'davi', name: 'Davi', fileName: 'davi.mp3'),
    AudioTrackInfo(id: 'bryan', name: 'Bryan', fileName: 'bryan.mp3'),
    // Add your new track here
  ];
  ```

- **Important Properties**:
  - `id`: Unique identifier used in code (lowercase, no spaces)
  - `name`: Display name shown to users (use Spanish for user-facing text)
  - `fileName`: Exact filename including extension, must match file in assets folder

#### 4. Update Default Sound Selection (Optional)

If you want to change the default sounds that play when the breathing exercise starts:

- Open `lib/screens/breath_screen.dart`
- Locate the `_initializeAudio()` method
- Update the default track IDs:

```dart
void _initializeAudio() {
  if (_isDisposed) return;
  if (!_isAudioInitialized) {
    // Check if music is already playing
    final currentMusic = _audioService?.getCurrentTrack(AudioType.backgroundMusic);
    if (currentMusic == null) {
      // Change 'river' to your new default music ID
      ref.read(selectedAudioProvider(AudioType.backgroundMusic).notifier)
          .selectTrack('gentle_forest');
    }
    
    // Similar changes for tones and voice if needed
    final currentTone = _audioService?.getCurrentTrack(AudioType.breathGuide);
    if (currentTone == null) {
      ref.read(selectedAudioProvider(AudioType.breathGuide).notifier)
          .selectTrack('sine');
    }
    
    final currentVoice = _audioService?.getCurrentTrack(AudioType.ambientSound);
    if (currentVoice == null) {
      ref.read(selectedAudioProvider(AudioType.ambientSound).notifier)
          .selectTrack('davi');
    }
    
    _isAudioInitialized = true;
  }
}
```

#### 5. Verify Asset Registration in pubspec.yaml

Ensure the sound directories are properly registered in your `pubspec.yaml` file:

```yaml
flutter:
  assets:
    - assets/sounds/music/
    - assets/sounds/instrument_cues/
    - assets/sounds/instrument_cues/gong/
    - assets/sounds/instrument_cues/synth/
    - assets/sounds/instrument_cues/violin/
    - assets/sounds/instrument_cues/human/
    - assets/sounds/guiding_voices/
```