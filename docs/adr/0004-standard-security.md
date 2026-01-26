# ADR 0004: Standard Security Model

## Context
The app stores sensitive financial data. We need to prevent unauthorized access to the app.

## Decision
We will implement a "Standard Security" model:
1. Optional app lock with PIN.
2. Biometric fallback (Fingerprint/FaceID).
3. Encryption of security preferences (PIN hash, salt) in secure storage.
4. **No database encryption** in v1.

## Alternatives Considered
- **Full Database Encryption (SQLCipher)**: Provides higher security but increases complexity, binary size, and can impact performance.
- **No Security**: Unacceptable for a financial app.

## Consequences
- **Pros**:
  - Quick to implement.
  - Good balance of security and convenience for most users.
  - Low performance overhead.
- **Cons**:
  - Technical users could potentially access the SQLite file if they have root access to the device (mitigated by OS-level app sandboxing).
