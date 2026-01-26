# Product Specification: TrustGuard

TrustGuard is an offline-first group expense and settlement ledger Flutter app.

## Target Audience

- Travel groups sharing expenses.
- Roommates splitting household bills.
- Friends managing shared event costs.
- Users who value financial privacy and want to keep data offline.

## Core Features (v1)

### 1. Group Management
- Create, edit, and archive groups.
- Set group currency (defaults to USD).
- Member management within groups (add, remove with soft-delete).

### 2. Transaction Tracking
- **Expenses**: Record amount, payer, note, date, and participants.
- **Transfers**: Record money movement between two members (settlements).
- **Split Types**:
  - Equal split (default).
  - Custom split (manual amounts per participant).
- **Tagging**: Categorize transactions with multiple tags.

### 3. Balances & Settlements
- Real-time balance calculation for each group member.
- Identification of debtors and creditors.
- **Settlement Suggestions**: A deterministic greedy algorithm that minimizes the number of transfers needed to settle all debts.

### 4. Search & Filter
- Search transactions by note text.
- Filter by tags, members, and date range.

### 5. Security
- PIN-based app lock.
- Biometric unlock support (Fingerprint/FaceID).
- Export protection (require unlock before sharing data).

### 6. Data Portability
- CSV export for transactions and balances.
- Text summary sharing (optimized for messaging apps).
- Full JSON backup and restore with conflict resolution.

### 7. Reminders
- Schedule periodic notifications (daily, weekly, monthly) for groups with outstanding balances.

## Non-Goals (v1)

- Cloud sync or multi-device coordination.
- Real-time collaborative editing.
- Integration with payment gateways (Venmo, PayPal, etc.).
- Image/receipt attachments (scaffolded but not implemented).
- Multi-currency support within a single group.

## Definition of Done

- 100% functional requirements met.
- Clean code passing all lint rules.
- Robust unit and widget test coverage.
- Accessible UI (screen reader support, high contrast).
- Comprehensive documentation.
