# Contributing to TrustGuard

First off, thank you for considering contributing to TrustGuard! It's people like you that make TrustGuard such a great tool.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Code Style](#code-style)
- [Pull Request Process](#pull-request-process)
- [Adding Translations](#adding-translations)

## Code of Conduct

This project and everyone participating in it is governed by the [TrustGuard Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/your-username/TrustGuard.git
   cd TrustGuard
   ```
3. **Install Flutter** following the [official guide](https://docs.flutter.dev/get-started/install)
4. **Install dependencies**:
   ```bash
   cd app
   flutter pub get
   ```

## Development Setup

### Prerequisites

- Flutter SDK (Stable channel, 3.9+)
- Dart SDK 3.9+
- Android Studio or VS Code with Flutter extensions
- Android SDK (for Android development)
- Xcode (for iOS development, macOS only)

### Code Generation

We use `build_runner` for code generation. After modifying models or database tables, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Running the App

```bash
flutter run
```

### Running Tests

```bash
flutter test
```

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** (code snippets, screenshots)
- **Describe the behavior you observed and expected**
- **Include your environment details** (Flutter version, device, OS)

### Suggesting Features

Feature suggestions are welcome! Please provide:

- **A clear and descriptive title**
- **A detailed description** of the proposed feature
- **Explain why this feature would be useful**
- **Any mockups or examples** if applicable

### Pull Requests

1. Create a new branch for your feature or bug fix:
   ```bash
   git checkout -b feature/amazing-feature
   ```
2. Make your changes
3. Write or update tests as needed
4. Ensure all tests pass
5. Submit a pull request

## Code Style

### Dart/Flutter Guidelines

- Follow the [official Dart style guide](https://dart.dev/guides/language/analysis-options)
- Use `const` constructors wherever possible
- Prefer named parameters for better readability
- Keep functions focused and under 50 lines when possible

### Before Committing

```bash
# Format code
dart format .

# Run analyzer
flutter analyze

# Run tests
flutter test
```

### Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Examples:
- `feat(expenses): add percentage-based split mode`
- `fix(balance): resolve calculation error with transfers`
- `docs(readme): update installation instructions`

## Pull Request Process

### Definition of Done

- [ ] Code is formatted and passes linting (`flutter analyze`)
- [ ] Unit and widget tests are added/updated and passing
- [ ] Accessibility standards maintained (Semantics, contrast, touch targets)
- [ ] Documentation updated if necessary
- [ ] No breaking changes (or clearly documented if unavoidable)

### Review Process

1. At least one maintainer review is required
2. All CI checks must pass
3. Changes will be squash-merged into main

## Adding Translations

TrustGuard uses Flutter's standard localization (l10n) system with ARB files.

### Adding a New Language

1. Navigate to `app/l10n/`
2. Create a new ARB file: `app_{locale}.arb` (e.g., `app_es.arb` for Spanish)
3. Copy contents from `app_en.arb` and translate the values
4. Run code generation:
   ```bash
   flutter gen-l10n
   ```
5. Test by changing your device language

### Translation Guidelines

- Preserve parameters like `{count}`, `{payer}`, `{amount}` in translations
- Use ICU format for plurals
- Keep translations concise but clear
- Test on actual devices to check text overflow

---

## Questions?

Feel free to open an issue for any questions or discussions. We're happy to help!

Thank you for contributing!
