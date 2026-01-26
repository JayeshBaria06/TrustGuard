# Contributing to TrustGuard

Thank you for your interest in contributing to TrustGuard! We welcome contributions from the community.

## Getting Started

1. Fork the repository.
2. Clone your fork: `git clone https://github.com/your-username/TrustGuard.git`
3. Install Flutter: [Flutter Installation Guide](https://docs.flutter.dev/get-started/install)
4. Run `flutter pub get` in the `app/` directory.

## Development Setup

- Use the Stable channel of Flutter.
- We use `build_runner` for code generation. Run `dart run build_runner build --delete-conflicting-outputs` after modifying models or database tables.
- We use `Riverpod` for state management and `Drift` for the database.

## Code Style

- Follow the [official Dart style guide](https://dart.dev/guides/language/analysis-options).
- Use `const` constructors wherever possible.
- Run `dart format .` before committing.
- Run `flutter analyze` and ensure there are no issues.

## Pull Request Process

1. Create a new branch for your feature or bug fix.
2. Write tests for your changes.
3. Ensure all tests pass: `flutter test`.
4. Submit a pull request with a clear description of your changes.

## Definition of Done

- Code is formatted and passes linting.
- Unit and widget tests are added/updated and passing.
- Accessibility standards (Semantics, contrast) are maintained.
- Documentation is updated if necessary.

## Security

Please report security vulnerabilities following the instructions in `SECURITY.md`.
