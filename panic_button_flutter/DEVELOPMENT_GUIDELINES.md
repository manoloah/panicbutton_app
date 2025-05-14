## PanicButton Flutter Development Guidelines

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
  - Example implementation:
    ```dart
    // Secure configuration using build-time injection
    static const String _envSupabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    );
    
    static String get supabaseUrl {
      // First check build-time environment variables (production approach)
      if (_envSupabaseUrl.isNotEmpty) {
        return _envSupabaseUrl;
      }
      
      // Then try to get from .env file (development approach)
      final envValue = dotenv.env['SUPABASE_URL'];
      if (envValue != null && envValue.isNotEmpty) {
        return envValue;
      }
      
      return '';
    }
    ```
  - For production builds, always use:
    ```bash
    ./scripts/build_ios.sh --distribution=testflight
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

