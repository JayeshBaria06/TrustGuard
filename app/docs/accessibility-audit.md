# Accessibility Audit Report

**Date:** 2026-01-29
**Version:** 1.5.0-dev
**Auditor:** AI Agent (Static Analysis)

## Executive Summary

This audit assesses the current state of accessibility in the TrustGuard application. The audit was performed via static code analysis, reviewing widget composition, semantic labeling, and theme configurations against WCAG 2.1 AA standards and Flutter best practices.

**Overall Status:** Partial Compliance. Core interactive elements have basic accessibility (Semantics, Tooltips), but purely visual cues (colors, icons) often lack semantic descriptions, and some touch targets may be undersized.

## Findings by Component

### 1. EmptyState Widget (`lib/src/ui/components/empty_state.dart`)
*   **Severity:** Minor
*   **Issue:** The visual illustration (Lottie/SVG/Icon) is decorative but not explicitly excluded from semantics, or if informative, lacks a label.
*   **Recommendation:** Wrap the illustration in `Semantics(excludeSemantics: true, ...)` if decorative, or provide a `label`. The text title and message usually provide sufficient context, so exclusion is preferred to reduce noise.

### 2. BalanceProgressBar (`lib/src/ui/components/balance_progress_bar.dart`)
*   **Severity:** Major
*   **Issue:** The widget conveys "owed" vs "owed to" primarily through color (Red/Green) and alignment (Left/Right). Screen readers will read the amount (e.g., "50.00 USD") but may not communicate the direction of the debt.
*   **Recommendation:** Wrap the entire widget in `Semantics` with a dynamic `value` or `label` like "You are owed 50.00 USD" or "You owe 50.00 USD".

### 3. Transaction List Item (`TransactionListScreen`)
*   **Severity:** Moderate
*   **Issue:** The leading `CircleAvatar` uses an Icon to distinguish between "Expense" and "Transfer". While the subtitle often contains "paid by..." or "A -> B", the explicit type is not announced.
*   **Recommendation:** Ensure the `ListTile` or a parent `Semantics` node explicitly announces "Expense" or "Transfer" if not clear from the subtitle.

### 4. Amount Suggestion Chips (`lib/src/ui/components/amount_suggestion_chips.dart`)
*   **Severity:** Minor
*   **Issue:** `ActionChip` uses `VisualDensity.compact`. This likely reduces the touch target height below the recommended 48dp (approx 32dp).
*   **Recommendation:** Ensure touch targets meet 48x48dp minimum. Remove compact density or wrap in a larger hit test area. Add a semantic hint "Tap to use".

### 5. Color Contrast (`lib/src/ui/theme/app_theme.dart`)
*   **Severity:** Potential Issue
*   **Issue:** The app uses `Colors.green` and `Colors.red` directly in `BalanceProgressBar` and transaction lists.
*   **Recommendation:** Verify these standard colors against the background (surface/surfaceContainer) in both Light and Dark modes. Standard Material Red/Green sometimes fail contrast on dark backgrounds. Use `ColorScheme.error` and custom semantic colors that are contrast-checked.

## Screen-Specific Analysis

### Add Expense Screen
*   **Status:** Good
*   **Notes:** `TextFormField`s have explicit `Semantics(label: ...)` wrappers. Navigation buttons in AppBar have tooltips.
*   **Improvement:** `MemberAvatarSelector` is well implemented with `Semantics(selected: ...)` on individual items.

### Speed Dial FAB
*   **Status:** Good
*   **Notes:** Main FAB has open/close labels. Items have tooltips.
*   **Improvement:** Verify focus traversal order so that opening the dial logically moves focus to the actions.

## Automated Analysis Results

*   `flutter analyze` reported issues related to missing generated code (orphan `*.freezed.dart` references), preventing a full clean analysis. These must be resolved to run automated accessibility tests reliably.

## Next Steps

1.  **Fix Build:** Resolve missing `freezed` generated files.
2.  **Implement Semantics:** Apply `Semantics` wrappers to `EmptyState` and `BalanceProgressBar`.
3.  **Touch Targets:** Audit and increase size of Chips and IconButtons where necessary.
4.  **Contrast:** Adjust red/green shades for better contrast.
