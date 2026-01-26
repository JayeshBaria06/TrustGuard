# System Architecture: TrustGuard

TrustGuard is built with a modern, reactive, and offline-first architecture using Flutter.

## Core Technologies

- **Language**: Dart
- **Framework**: Flutter
- **State Management**: Riverpod (Reactive providers)
- **Local Database**: Drift (SQLite with type-safe queries)
- **Domain Models**: Freezed (Immutable classes with JSON serialization)
- **Navigation**: go_router (Declarative routing)
- **Local Notifications**: flutter_local_notifications (Timezone-aware scheduling)
- **Security**: flutter_secure_storage (Encrypted preferences), crypto (Hashing/Salting)

## Project Structure

The project follows a feature-first organization:

```text
app/lib/src/
├── app/               # App-wide config (router, providers, bootstrap)
├── core/              # Shared infrastructure
│   ├── database/      # Drift setup, tables, mappers, repositories
│   ├── models/        # Shared domain models
│   ├── platform/      # Platform-specific services (notifications, auth)
│   └── utils/         # Helper functions (money, validators)
├── features/          # Functional features
│   ├── balances/      # Balance computation and settlement logic
│   ├── export_backup/ # CSV/JSON export and restore logic
│   ├── groups/        # Group and member management UI
│   ├── reminders/     # Notification settings and scheduling
│   ├── settings/      # App-wide preferences and security UI
│   └── transactions/  # Transaction CRUD and filtering UI
└── ui/                # Shared UI components and theme
```

## Data Flow

1. **Persistence**: `Drift` manages the SQLite database. Tables are defined in `core/database/tables/`.
2. **Mapping**: `Mappers` convert Drift-generated data classes to and from clean domain models (`core/models/`).
3. **Repository Pattern**: Repositories provide a clean API for data access, abstracting the database implementation.
4. **Reactive State**: `Riverpod` providers watch repository streams and expose data to the UI.
5. **Logic**: Services (e.g., `BalanceService`, `SettlementService`) perform complex computations on domain models.

## Offline-First Design

TrustGuard works entirely without an internet connection.
- SQLite is the source of truth.
- State is derived from database streams using `watch()`.
- Backup/Restore provides manual data synchronization/portability.

## Security Architecture

- **App Lock**: Managed by `AppLockService`. The PIN is never stored in plain text.
- **Hashing**: PINs are salted with a random UUID and hashed using SHA-256.
- **Secure Storage**: Hashed PINs and security preferences are stored in `flutter_secure_storage`.
- **Identity Verification**: Sensitive operations (e.g., export) can be gated by a PIN verification dialog.
