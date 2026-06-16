# EGX Watchlist Improvements Design Specification

## Goal Description
Enhance the EGX stocks watchlist in `kero_space` by adding bullish/bearish indicators, color-coded price changes, sparklines, monthly trends, and daily performance notification recaps.

## Proposed Changes

### 1. Data Models (`lib/features/finance/data/models/finance_collections.dart`)
- **`EGXPriceSnapshot` [MODIFY]**:
  - Add `double changeAmount` to track daily price change values.

### 2. Services & Repositories

#### `EGXScraperService` (`lib/features/finance/data/repositories/egx_scraper_service.dart`)
- Define class `EGXScrapeResult` with fields: `price`, `changeAmount`, and `changePercentage`.
- Update `fetchPrice(ticker)` to return `EGXScrapeResult?` instead of `double?`.
- Scrape elements:
  - Price: `.market-summary__last-price`
  - Change Amount: `.market-summary__change`
  - Change Percentage: `.market-summary__change-percentage`

#### `FinanceRepository` (`lib/features/finance/data/repositories/finance_repository.dart`)
- Add method to save a snapshot: `savePriceSnapshot(EGXPriceSnapshot snapshot)`.
- Add method to query snapshots: `getSnapshotsForTicker(String ticker, {int limit})`.

### 3. Business Logic (`lib/features/finance/presentation/bloc/finance_bloc.dart`)
- Update `LoadFinanceData` and `RefreshStockPrices` to:
  - Fetch `EGXScrapeResult`.
  - Save new snapshots to Isar DB.
  - Calculate 7-day Simple Moving Average (SMA).
  - Calculate 30-day percentage trend change.
  - Classify stock sentiment (Strong/Weak Bullish, Strong/Weak Bearish, Neutral).
- Save sentiment data and price histories in `FinanceLoaded` state.

#### `FinanceWorker` (`lib/features/finance/data/services/finance_worker.dart`)
- Perform scrapes at 2:30 PM Cairo Time (Sunday to Thursday).
- Save results to Isar.
- Trigger local push notification with watchlist summary (e.g. `COMI is up +2.1% (Strong Bullish)`).

### 4. UI presentation (`lib/features/finance/presentation/widgets/portfolio_tab.dart`)
- Replace the vertical watchlist list with a responsive `GridView`.
- Each stock card displays:
  - Ticker name and company name.
  - Color-coded current price (Green = Up, Red = Down).
  - Daily change chip `+1.20 EGP (+0.9%)`.
  - Sentiment badge (colored capsule pill).
  - Sparkline line graph of last 7 price points.

## Verification Plan

### Automated Tests
- Test cases for QNB/NBE/Bybit parser outputs.
- Test cases for SMA calculation logic and bullish/bearish classification.

### Manual Verification
- Add a ticker like COMI, trigger pull-to-refresh, verify grid card layout and sparkline render correctly.
