# Thndr Notifications & holdings Tracking Design Spec

This document details the architectural layout, database entities, parsing logic, and UI design to integrate **Thndr** stock execution notifications with automatic portfolio tracking.

## Goals
- Parse Thndr buy and sell notifications dynamically.
- Update EGX holdings (quantity and average cost).
- Log cash flow transactions linked to a `Thndr` money source.
- Update the watchlist automatically for new symbols.
- Render holdings and performance details on the Stocks tab.

## Database Entities
- **`EGXHolding`**: Holds quantity, average cost, ticker, and purchase date.
- **`MoneySource`**: Tracks cash balance of the `Thndr` wallet.
- **`Transaction`**: Tracks cash flow events.
- **`EGXWatchlist`**: Ensures stock symbols are added when transacted.

## Notification Parsing Regex
- **BUY Pattern**: Matches executions where shares are bought.
  - Pattern: `r'(?:bought|buy\s+order\s+executed:?)\s+(\d+)\s*(?:shares\s+of\s+)?([A-Z0-9]+)\s+(?:at|@)\s*([\d,\.]+)\s*(?:EGP|LE)?'`
- **SELL Pattern**: Matches executions where shares are sold.
  - Pattern: `r'(?:sold|sell\s+order\s+executed:?)\s+(\d+)\s*(?:shares\s+of\s+)?([A-Z0-9]+)\s+(?:at|@)\s*([\d,\.]+)\s*(?:EGP|LE)?'`

## Data Flow Pipeline
1. `NotificationParserService` intercepts notifications from package `com.thndr` or text containing "thndr".
2. On matching **BUY**:
   - Create investment transaction: amount = `qty * price`, source = `Thndr`, type = `EXPENSE`.
   - Update/create `Thndr` `MoneySource` (subtract cost).
   - Recalculate average cost for `EGXHolding`.
   - Ensure ticker exists in `EGXWatchlist`.
3. On matching **SELL**:
   - Create investment transaction: amount = `qty * price`, source = `Thndr`, type = `INCOME`.
   - Update/create `Thndr` `MoneySource` (add revenue).
   - Decrease quantity in `EGXHolding`. Delete holding if quantity <= 0.

## UI Presentation
- **Holdings Card**: A high-level overview card at the top of the Stocks tab indicating:
  - Total portfolio value (calculated using latest scraped stock prices * holding quantities).
  - Total profit/loss percentage and absolute value.
- **Watchlist & Holdings List**: Display owned quantities directly on stock grid cards if they exist in `EGXHolding` (e.g. "10 shares @ 135.50").
