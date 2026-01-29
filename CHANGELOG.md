# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.5.0] - 2026-01-30

### Added

- **Accessibility Compliance**:
  - Comprehensive **Semantics** labels and hints for all core components.
  - Standardized all interactive elements to **48dp minimum touch targets**.
  - Optimized color contrast ratios for WCAG AA compliance.
  - New **High-Contrast Theme** toggle for severe visual impairments.
- **QR Code Sharing**:
  - Offline device-to-device expense sharing via compressed QR codes (Gzip+Base64).
  - Secure 'TG:' prefix for app identification and versioning.
  - Intelligent member mapping and **duplicate detection** on import.
- **Expense Templates**:
  - Save common expense configurations as reusable templates.
  - **Quick Entry** from Speed Dial with automatic form pre-filling.
  - Support for fixed or variable amounts and persistent template ordering.
- **Budget Tracking**:
  - Periodic budgets (Weekly, Monthly, Yearly) with custom start dates.
  - **Category-specific budgets** using tag filters.
  - Automated **Spending Alerts** (80% and 100% thresholds) via local notifications.
  - Color-coded progress cards in Group Overview.
- **Member Avatars**:
  - Visual identification with custom images, camera capture, or preset colors.
  - On-device image processing (256x256, JPEG 80%) to maintain app size.
  - Integrated avatars in list views, selectors, and detail screens.
- **Home Screen Widgets**:
  - **Balance Overview** widget for Android and iOS.
  - Supports multiple sizes (Small, Medium, Large) with **Top Groups** list.
  - Theme-aware design and direct deep linking into the app.
- **Robustness**:
  - Incremented database schema to version 9.
  - Added 40+ new tests covering QR sharing, templates, budgets, and avatars.
  - New modular integration test suite for v1.5 features.

### Changed

- Updated `DashboardService` to support cross-group balance aggregation for widgets.
- Enhanced `NotificationService` with immediate notification support for alerts.
- Refactored `MemberAvatarSelector` for better visual feedback.

### Fixed

- Fixed Riverpod circular dependency in `transactionRepositoryProvider`.
- Resolved layout issues in `SaveAsTemplateSheet` on small devices.
- Improved database migration logic to handle sequential version upgrades more reliably.

## [1.4.0] - 2026-01-30

### Added

- **Speed Dial FAB**: New expandable Floating Action Button on the transaction list.
  - **Quick Add**: Compact bottom sheet for rapid equal-split expense entry.
  - Immediate access to New Expense and New Transfer.
- **Visual Polish & Animations**:
  - **Staggered List Animations**: Beautiful entrance animations for group and transaction lists.
  - **Lottie Onboarding**: Animated illustrations for the first-launch experience.
  - **Animated Icons**: Morphing archive/unarchive icons and bouncing filter badges.
  - **Animated Empty States**: Engaging Lottie animations when lists are empty.
  - **Smooth Transitions**: Refined page transitions (Fade Through and Shared Axis).
- **Power User Features**:
  - **Keyboard Shortcuts**: Comprehensive shortcuts for desktop (Ctrl/Cmd + N, T, F, S, Esc).
  - **Drag-to-Reorder**: Persistent custom ordering for members and tags.
  - **Haptic Sliders**: Tactile percentage-based custom split adjustments.
- **Intelligent Guidance**:
  - **Smart Amount Suggestions**: Usage-based suggestions in expense and transfer forms.
  - **Feature Coachmarks**: Guided tooltips to help discover new features like swipe-to-edit.
  - **Undo Safety**: 5-second undo window for transaction deletions with SnackBars.
- **Data Visualization**:
  - **Balance Progress Bars**: Bidirectional, color-coded bars for intuitive debt/credit tracking.
  - Integrated bars into Dashboard and Balances screen for consistent scaling.
- **Robustness**:
  - Incremented database schema to version 5 with persistent ordering support.
  - Added 40+ new tests for animations, reordering, shortcuts, and suggestions.
  - Added full v1.4 feature integration test suite.

### Changed

- Improved `EmptyState` component with Lottie support and better accessibility.
- Enhanced `AddExpenseScreen` with percentage-based split mode.
- Optimized app startup sequence for background recurring transaction processing.

### Fixed

- Fixed a bug where staggered animations would not play on initial load in some screens.
- Improved focus management when using keyboard shortcuts on list screens.

## [1.3.0] - 2026-01-28

### Added

- **Spending Analytics**: Integrated `fl_chart` for visual spending insights.
  - Interactive Pie Charts for category and member breakdowns.
  - Monthly Trend Charts with period filtering and gradient fills.
- **Receipt OCR**: Automated expense entry using `google_mlkit_text_recognition`.
  - On-device extraction of amount, date, and merchant.
  - Confidence scoring and manual verification flow.
- **Recurring Transactions**: Support for automated periodic expenses and transfers.
  - Flexible frequencies: Daily, Weekly, Bi-weekly, Monthly, Yearly.
  - Background processing on app startup.
- **Data Import**: Intelligent CSV import for Splitwise and Tricount exports.
  - Automatic format detection and row preview.
  - Interactive member mapping and automated member creation.
- **Enhanced Motion Design**:
  - **Container Transforms**: Smooth shared-element transitions for navigation.
  - **Rolling Numbers**: Animated counters for financial values on the dashboard.
  - **Shake Feedback**: Visual "shake" effect for validation errors and incorrect PIN entry.
  - **Confetti Celebrations**: Festive effects when a group is fully settled.
- **Improved Input Experience**:
  - **Custom Numeric Keypad**: Specialized calculator-style input for faster amount entry.
  - **Glassmorphism**: Modern frosted-glass effect for sticky date headers.
- **Robustness & Testing**:
  - Incremented database schema to version 4 with non-destructive migrations.
  - Added 110+ new tests covering all v1.3 features.
  - New E2E integration test covering the complete v1.3 feature set.

### Changed

- Refactored `TransactionListScreen` to use `CustomScrollView` for better performance and sticky headers.
- Updated `DashboardCard` to use `RollingNumberText` for all financial summaries.
- Integrated `ShakeWidget` into all primary form validation flows.

### Fixed

- Improved CSV parsing robustness across different operating systems (EOL handling).
- Resolved overlapping text issues in `MemberAvatarSelector` on small devices.

## [1.2.0] - 2026-01-27

### Added

- **Global Dashboard**: New home screen overview showing total debt/credit across all active groups and recent activity.
- **Theme Customization**: Support for Light, Dark, and System theme modes with persistence.
- **Modern Member Selection**: Replaced legacy dropdowns and checkboxes with horizontal avatar selectors for better UX.
- **Visual Split Preview**: Real-time proportional bar chart for expense splits, providing immediate feedback on distribution.
- **Sticky Date Headers**: Transaction list now groups items by date with modern headers.
- **Swipe Actions**: Quick swipe-to-edit and swipe-to-delete gestures for transactions.
- **Contextual Settlements**: Reorganized settlements screen to prioritize actions you need to take.
- **Skeleton Loading**: Improved perceived performance with shimmer-based loading placeholders.
- **SVG Illustrations**: Custom vector illustrations for empty states.
- **Haptic Feedback**: Tactile feedback for key interactions like button presses and selection changes.
- **Hero Animations**: Smooth visual transitions between lists and detail screens.
- **Integration Testing**: Comprehensive end-to-end user flow tests.

### Changed

- Improved `EmptyState` component to support both icons and SVG paths.
- Optimized balance aggregation logic for cross-group summaries.
- Updated user guide with new UI/UX features.

### Fixed

- Resolved minor layout shifts during data loading.
- Fixed inconsistent tag display in filtered lists.

## [1.1.0] - 2026-01-15

### Added

- Initial stable release with core features.
- Offline storage using SQLite (Drift).
- Group management with members.
- Basic expenses and transfers.
- Search and filters.
- PIN lock security.
- CSV export.

---

[Unreleased]: https://github.com/MasuRii/TrustGuard/compare/v1.5.0...HEAD
[1.5.0]: https://github.com/MasuRii/TrustGuard/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/MasuRii/TrustGuard/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/MasuRii/TrustGuard/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/MasuRii/TrustGuard/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/MasuRii/TrustGuard/releases/tag/v1.1.0
