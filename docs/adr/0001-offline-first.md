# ADR 0001: Offline-First Architecture

## Context
TrustGuard is designed to be a personal group expense ledger. Users often need to record expenses in situations with limited connectivity (e.g., traveling abroad, inside restaurants).

## Decision
We will use an offline-first architecture. The local database will be the primary source of truth for the application.

## Alternatives Considered
- **Cloud-First**: Requires a backend, authentication, and reliable internet. Worsens user experience in low-connectivity areas.
- **Sync-First**: Complex conflict resolution and requires a backend.

## Consequences
- **Pros**:
  - Instant UI updates.
  - Works anywhere without internet.
  - High privacy (data stays on device).
- **Cons**:
  - No automatic multi-device synchronization.
  - Data loss risk if device is lost (mitigated by manual backup feature).
