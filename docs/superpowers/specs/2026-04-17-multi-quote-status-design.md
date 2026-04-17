# Multi-Quote Status Design

Date: 2026-04-17
Project: BTC Menu macOS

## Goal

Expand status bar app so user can independently choose whether to show:

- BTC price in USD
- BTC price in BRL
- USD exchange rate in BRL

When more than one option is enabled, status bar title must show all enabled values at same time in a fixed order using visual separators, for example:

`↑ ₿ $77.788 | → ₿ R$430.000 | ↓ $ R$5,20`

Each displayed item must show its own movement arrow based on comparison with last successful refresh of that same item.

## Current State

Today app supports only one BTC display currency at a time through a `Moeda` submenu (`USD` or `BRL`). Fetch layer requests a single BTC quote in one currency, and status title renders a single value. Main detail rows in menu also assume one active BTC quote.

## Proposed UX

### Status bar

- Replace single-price status text with a composed string built from zero to three independently enabled quote segments.
- Fixed segment order:
  1. BTC/USD
  2. BTC/BRL
  3. USD/BRL
- Segment formats:
  - BTC/USD: `<arrow> ₿ $<compact price>`
  - BTC/BRL: `<arrow> ₿ R$<compact price>`
  - USD/BRL: `<arrow> $ R$<price with 2 decimals>`
- If all toggles are disabled, status title falls back to placeholder such as `--`.
- Tooltip should still expose same composed value shown in status bar.

### Menu

- Remove current `Moeda` submenu because quote selection is no longer mutually exclusive.
- Add new section or submenu named `Exibir` with three checkbox items:
  - `Cotação do dólar`
  - `Bitcoin em dólar`
  - `Bitcoin em real`
- Existing rows for last update, 24h variation, volume, source, error, alert, API key, launch at login, and quit remain.

### Detail rows

- Main detail rows continue to show one BTC-centered summary:
  - last update
  - 24h variation
  - volume
  - source
- Preferred source for detail rows:
  1. BTC/BRL if available in current snapshot
  2. BTC/USD otherwise
- Rationale: menu details today are BTC-specific and should remain stable without adding more clutter.

## Data Model

Introduce richer quote snapshot instead of single BTC quote:

- `btcUSD`
- `btcBRL`
- `usdBRL`
- `btcUSDVolume24h`
- `btcBRLVolume24h`
- `btcUSDPercentChange24h`
- `btcBRLPercentChange24h`
- optional shorter-window BTC changes if already supported by source

The view model will store last successful values separately for:

- previous BTC/USD
- previous BTC/BRL
- previous USD/BRL

This allows independent movement arrows per segment.

## Fetch Strategy

### CoinGecko path

Single request can already return `usd` and `brl` values from `market_data.current_price`. Design should read both in one fetch, then derive:

- `btcUSD` directly from `usd`
- `btcBRL` directly from `brl`
- `usdBRL = btcBRL / btcUSD`

The same pattern applies to volume and 24h change dictionaries.

### CoinMarketCap path

Request should ask `convert=USD,BRL` if API supports comma-separated conversions. If returned, use both directly and derive `usdBRL = btcBRL / btcUSD`.

If CMC path rate-limits or fails in existing fallback cases, app should continue current behavior of falling back to CoinGecko.

## Preferences

Replace old single-currency preference with three persistent booleans:

- `showDollarRate`
- `showBitcoinUSD`
- `showBitcoinBRL`

Default values:

- `showBitcoinUSD = true`
- `showBitcoinBRL = false`
- `showDollarRate = false`

These defaults preserve current user expectation of seeing BTC in USD on first launch while unlocking new displays.

Legacy `currency` preference should no longer drive UI. Implementation may ignore it or migrate from it:

- if legacy currency is `brl`, initialize `showBitcoinBRL = true` and `showBitcoinUSD = false` only when new keys are absent
- otherwise keep default `showBitcoinUSD = true`

## View Model Changes

View model responsibilities will change from “single active currency” to “quote snapshot + visibility settings”:

- load visibility preferences on startup
- fetch full multi-quote snapshot
- build status title from enabled segments
- compute independent movement arrows
- expose menu checkbox states
- choose primary BTC detail quote for menu rows

Alert logic remains BTC-based. It should evaluate against primary BTC detail quote so existing alert semantics stay deterministic.

## Error Handling

- Fetch failure still sets error state and preserves last error details.
- If refresh fails after previous successful snapshot, status bar should continue showing last known composed values rather than collapsing to unreadable partial state.
- If a required value for one segment is missing but other values exist, omit only broken segment from composed title and keep others.

## Testing

Add tests around:

- preference migration and defaults
- composed status title for 0, 1, 2, and 3 enabled segments
- independent movement arrows for each segment
- snapshot derivation of USD/BRL from BTC quotes
- menu state checkbox rendering
- fallback selection of primary BTC detail quote

## Implementation Notes

- Keep order and wording consistent in UI strings.
- Reuse existing formatting helpers where possible, but add dedicated formatter for exchange rate with 2 decimals.
- Avoid adding parallel network requests when one multi-currency request can satisfy all data.

## Out of Scope

- Separate detail rows for dollar-specific variation/volume
- Separate alert types for USD/BRL
- Custom ordering of visible segments
- User-configurable separators or symbols
