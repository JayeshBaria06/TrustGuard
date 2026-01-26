# ADR 0002: Drift for Local Persistence

## Context
We need a robust, type-safe way to store structured data (groups, members, transactions) on the device.

## Decision
We will use `Drift` (formerly Moor) as our database library. Drift is a reactive persistence library for Flutter and Dart, built on top of SQLite.

## Alternatives Considered
- **Sqflite**: Low-level, requires manual SQL and mapping. Error-prone.
- **Hive**: NoSQL, fast, but lacks strong relational constraints and complex query support needed for financial ledgers.
- **Isar**: Fast NoSQL, but Drift's relational model fits our domain better.

## Consequences
- **Pros**:
  - Type-safe queries (compile-time checks).
  - Reactive streams (`watch()`) for automatic UI updates.
  - Excellent migration support.
- **Cons**:
  - Requires code generation (`build_runner`).
