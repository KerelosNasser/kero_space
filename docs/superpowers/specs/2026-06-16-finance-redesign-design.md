# Finance Module Redesign Specification

## Goal Description
Redesign the existing finance module in `kero_space` to provide a clear, automated, and easy-to-use money hub. Replace the confusing health-wealth correlation and career preparation boards with a clean net worth tracker, money sources manager, subscription tracking with auto-logging, a scheduled EGX stock watchlist, notification listener integration for specific Egyptian banks/wallets and Bybit, and AI-powered quick-logging and advice.

## Proposed Changes

### 1. Data Models (`lib/features/finance/data/models/finance_collections.dart`)
- **`MoneySource` [NEW]**: Represents an income source or account.
  - `Id id = Isar.autoIncrement`
  - `String name` (e.g., 'EGX', 'Freelance', 'Basic Job', 'QNB', 'NBE', 'Bybit')
  - `double balance` (Running balance)
- **`Subscription` [NEW]**: Represents a recurring payment.
  - `Id id = Isar.autoIncrement`
  - `String name` (e.g., 'Netflix')
  - `double amount`
  - `String billingCycle` ('MONTHLY', 'YEARLY')
  - `DateTime nextRenewalDate`
  - `bool isAutoRenew` (If true, logs an expense transaction when the renewal date is reached)
- **`Transaction` [MODIFY]**: Link transactions to a specific money source.
  - Add `String? sourceName`
- **`EGXWatchlist` [KEEP]**: Stock tickers to watch.
- **`EGXPriceSnapshot` [KEEP]**: Ticker prices over time.

### 2. Services & Repositories

#### `FinanceRepository` (`lib/features/finance/data/repositories/finance_repository.dart`)
- Add CRUD support for `MoneySource` and `Subscription`.
- Add method to log a subscription renewal transaction.
- Add helper to adjust `MoneySource` balances automatically when transactions are recorded.

#### `NotificationParserService` (`lib/features/finance/data/repositories/notification_parser_service.dart`)
- Update parsing regexes to support:
  - **QNB**: Transaction push alerts or SMS (e.g. `purchase transaction done on card... amount EGP \d+ at \w+`).
  - **NBE**: Bank notifications (e.g. `purchase of EGP \d+ from \w+`).
  - **Bybit Card**: Crypto/debit card notification formats (e.g. `transaction of \d+ USD/EUR successful at \w+`).
  - **Instapay / Vodafone Cash**: Keep existing rules.
- Set parsed transaction source matching the bank name.

#### `EGXScraperService` & Scheduled Refresh (`lib/features/finance/data/repositories/egx_scraper_service.dart`)
- Implement `WorkManager` task running daily.
- If the current local day is Friday or Saturday, skip execution.
- Trigger price scraping at Cairo Local Time 2:30 PM, storing the results in `EGXPriceSnapshot`.

### 3. Business Logic (`lib/features/finance/presentation/bloc/finance_bloc.dart`)
- **`LoadFinanceData`**:
  - Load all transactions, budgets, watchlist, sources, and subscriptions.
  - Calculate total net worth (sum of money source balances + stock values).
  - Check past-due subscriptions, auto-generate expense transactions, update renewal dates, and dispatch local notifications.
  - Auto-generate monthly salary transaction on specified date if not yet logged.
- **`AIQuickLogEvent`**: Send text description to `AIService` (OpenRouter API), extract parameters, and register transaction.
- **`GetAIAdvisoryEvent`**: Analyze current financial summary using `AIService` and load advice.

### 4. Presentation & UI (`lib/features/finance/presentation`)
- **`FinanceHomeScreen`**: Modify tab navigation to use a 4-tab system:
  1. **Overview Tab**:
     - Net Worth Card (Glassmorphic, color gradient, showing total cash + stock valuation, and monthly net gain/loss).
     - AI Quick-Log bar: Simple text field for lazy typing.
     - Money Sources Grid: GridView layout of sources and their current balances.
     - Top Stocks Grid: GridView displaying watchlist tickers with current scraped price and percentage change.
     - AI Advisor Card: Dynamic text card with finance insights.
  2. **Transactions Tab**: History feed + category budget progress bars. Shows badge for auto-logged transactions.
  3. **Subscriptions Tab**: Burn rate card + list of subscriptions and days remaining.
  4. **Stocks Tab**: Complete EGX watchlist screen with pull-to-refresh.

## Verification Plan

### Automated Tests
- Test cases for subscription auto-renewal generation.
- Test cases for salary auto-generation.
- Unit tests for the custom regex notification parser (Instapay, Vodafone Cash, QNB, NBE, Bybit).

### Manual Verification
- Test AI Quick-Log by typing experimental sentences (e.g., "spent 50 EGP on transport").
- Test stock scraping by adding a known EGX symbol and triggering a pull-to-refresh.
- Simulate background notifications parsing.
