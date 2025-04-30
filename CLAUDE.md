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

### File Structure

```
lib/
├── screens/          # Main screen widgets
├── widgets/          # Reusable widgets
├── models/           # Data models
├── services/         # Business logic and API calls
├── utils/            # Helper functions and utilities
├── constants/        # App-wide constants
└── config/           # Configuration files
```

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
    - Containers with complex decoration (e.g., `BreathingCircle`)
    - Custom animations (e.g., `WaveAnimation`)
    - Text displays with formatting (e.g., `RemainingTimeDisplay`)
    - UI elements that show/hide based on state (e.g., `PhaseIndicator`)
    - Interactive controls (e.g., `AddTimeButton`)

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

- **Table names:** snake_case, plural (`user_profiles`)  
- **Column names:** snake_case (`first_name`)  
- **Foreign keys:** singular_table_name_id (`user_id`)  
- **Timestamps:** `created_at`, `updated_at`

---

### Route Names

- All lowercase  
- Use hyphens for readability  
- Examples: `/user-profile`, `/breathing-exercise`

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

