# Development Guidelines for PanicButton Flutter App

## 1. Language Rules

### Code Elements (MUST BE IN ENGLISH)
- File names (e.g., `profile_screen.dart`, `settings_screen.dart`)
- Class names (e.g., `ProfileScreen`, `SettingsController`)
- Variable names (e.g., `userProfile`, `isLoading`)
- Function names (e.g., `handleLogout`, `updateProfile`)
- Comments and documentation
- Route names (e.g., `/profile`, `/settings`)
- Database column names
- API endpoints
- Git commits and PR descriptions

### User-Facing Text (MUST BE IN SPANISH)
- Screen titles
- Button labels
- Error messages
- Success messages
- Menu items
- Descriptions
- Help text
- Tooltips
- Placeholder text
- Alert messages

## 2. File Structure
- Screens go in `lib/screens/`
- Widgets go in `lib/widgets/`
- Models go in `lib/models/`
- Services go in `lib/services/`
- Utils go in `lib/utils/`
- Constants go in `lib/constants/`

## 3. Naming Conventions
- Files: lowercase with underscores (`user_profile_screen.dart`)
- Classes: PascalCase (`UserProfileScreen`)
- Variables/Functions: camelCase (`getUserProfile`)
- Constants: SCREAMING_SNAKE_CASE (`MAX_RETRY_ATTEMPTS`)

## 4. Development Process
1. Always pull latest changes before starting work
2. Create feature branches from main/master
3. Test compilation and run app before committing
4. Follow atomic commit practices
5. Review changes against these guidelines before PR

## 5. UI/UX Guidelines
- Use consistent color scheme from theme
- Maintain proper spacing and padding
- Follow Material Design guidelines
- Ensure proper error handling and loading states
- Add proper validation for forms
- Include proper feedback for user actions

## 6. Testing Requirements
- Test on both iOS and Android
- Test on different screen sizes
- Verify all user flows
- Check error scenarios
- Validate form inputs
- Test offline behavior

## 7. Performance Guidelines
- Optimize image assets
- Minimize widget rebuilds
- Use const constructors where possible
- Implement proper pagination
- Cache network responses
- Handle memory leaks

## 8. Security Guidelines
- Never commit API keys
- Use environment variables
- Implement proper authentication
- Validate all inputs
- Secure data storage
- Handle sensitive data properly 