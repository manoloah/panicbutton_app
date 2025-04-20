# PanicButton Flutter Development Guidelines

## Language Rules

### Code Elements (MUST BE IN ENGLISH)
- File names: `settings_screen.dart`, `profile_screen.dart`
- Class names: `SettingsScreen`, `UserProfile`
- Variable names: `isLoading`, `userName`
- Function names: `handleLogin()`, `updateProfile()`
- Route names: `/settings`, `/profile`
- Database columns: `user_id`, `created_at`
- Comments and documentation
- Git commits
- Configuration keys

### User-Facing Text (MUST BE IN SPANISH)
- Screen titles: "Configuración", "Mi Perfil"
- Button labels: "Guardar Cambios", "Cerrar Sesión"
- Error messages: "Error al cargar el perfil"
- Success messages: "Cambios guardados exitosamente"
- Form labels: "Nombre", "Correo electrónico"
- Menu items: "Tu camino", "Mídete"
- Tooltips and help text
- Placeholder text
- Alert messages

## File Structure
```
lib/
├── screens/          # Main screen widgets
├── widgets/          # Reusable widgets
├── models/           # Data models
├── services/         # Business logic and API calls
├── utils/           # Helper functions and utilities
├── constants/       # App-wide constants
└── config/          # Configuration files
```

## Naming Conventions
- Files: snake_case (`user_profile_screen.dart`)
- Classes: PascalCase (`UserProfileScreen`)
- Variables: camelCase (`userName`)
- Constants: SCREAMING_SNAKE_CASE (`MAX_RETRY_ATTEMPTS`)
- Private members: _prefixUnderscore (`_handleSubmit`)

## Database Schema
- Table names: snake_case, plural (`user_profiles`)
- Column names: snake_case (`first_name`)
- Foreign keys: singular_table_name_id (`user_id`)
- Timestamps: `created_at`, `updated_at`

## Route Names
- All lowercase
- Use hyphens for readability
- Examples: `/user-profile`, `/breathing-exercise`

## Error Handling
- User-facing errors in Spanish
- Log technical errors in English
- Include error codes for debugging
- Provide helpful recovery actions

## State Management
- Use providers for app-wide state
- Local state with setState() when appropriate
- Document state dependencies
- Handle loading and error states

## Code Style
- Use consistent indentation (2 spaces)
- Group related properties together
- Order: constructors, lifecycle methods, public methods, private methods
- Add comments for complex logic
- Use meaningful variable names 