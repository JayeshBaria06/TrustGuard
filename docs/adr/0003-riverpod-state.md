# ADR 0003: Riverpod for State Management

## Context
We need a scalable and testable way to manage application state and dependency injection.

## Decision
We will use `Riverpod` (v2+) for state management.

## Alternatives Considered
- **Provider**: Good, but has limitations with compile-time safety and accessing providers outside the widget tree.
- **Bloc**: Very robust but often leads to excessive boilerplate for simple reactive data fetching.
- **GetX**: Lacks the architectural discipline and testability of Riverpod.

## Consequences
- **Pros**:
  - Compile-time safety.
  - No dependency on `BuildContext` for logic.
  - Easy to mock dependencies for testing.
  - Excellent integration with asynchronous data (AsyncValue).
- **Cons**:
  - Learning curve for developers new to functional reactive programming.
