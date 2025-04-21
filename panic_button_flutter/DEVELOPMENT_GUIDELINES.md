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

### Naming Conventions

- **Files:** snake_case (`user_profile_screen.dart`)  
- **Classes:** PascalCase (`UserProfileScreen`)  
- **Variables:** camelCase (`userName`)  
- **Constants:** SCREAMING_SNAKE_CASE (`MAX_RETRY_ATTEMPTS`)  
- **Private members:** `_prefixUnderscore` (`_handleSubmit`)

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

- **Profile in release mode** using DevTools’ performance tab before each release.  
- **Debounce rapid state changes** (e.g. typing, sliders) to avoid jank.  
- **Cache images** with `CachedNetworkImage` or via Supabase’s CDN headers.  
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
- **Ensure minimum tap target of 48×48 dp** for all buttons and icons.  
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

