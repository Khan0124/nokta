# Nokta POS – Internationalization & Localization Guide

## 1. Scope & Principles
- **Supported locales**: Arabic (`ar`) with RTL layout, English (`en`) with LTR layout.
- **Primary targets**: POS and kitchen display (completed), remaining Flutter clients (driver, customer, admin) scheduled next.
- **Goals**: Centralize copy in translation files, guarantee locale-safe formatting, and provide runtime switching per user/tenant.
- **Standards**: Follow CLDR formatting rules via Flutter `intl` package. Every UI string must originate from `AppLocalizations`.

## 2. Repository Layout
| Artifact | Purpose |
| --- | --- |
| `packages/core/assets/i18n/en.json`, `packages/core/assets/i18n/ar.json` | Source of truth for human-readable strings (namespaced by module). |
| `packages/core/lib/l10n/app_localizations.dart` | Generated-style helper that loads JSON, offers typed getters, and handles fallbacks. |
| `packages/core/lib/providers/locale_provider.dart` | Riverpod provider exposing current locale and updater APIs. |
| `packages/core/lib/services/locale_service.dart` | Persists locale preference (shared prefs) and enforces RTL/LTR switching. |
| `apps/*/lib/main.dart` | Each Flutter app wires localization delegates and supported locales. |

## 3. Adding or Updating Strings
1. **Decide namespace** using dot notation (`pos.checkout.confirm`); reuse existing namespaces when extending screens.
2. **Update both JSON files** (English + Arabic). Keep keys alphabetized inside each namespace for diff clarity.
3. **Regenerate strongly typed accessors** by re-running the app (no manual code-gen required; loader reads JSON at runtime).
4. **Reference strings** via `context.l10n.posCheckoutConfirm` (extension defined in `app_localizations.dart`). Never hardcode text.
5. **Fallback behavior**: Missing keys log a warning and return the key itself. Treat any such warning as a regression.

## 4. Date, Time, Currency, and Numbers
- Use `l10n.formatCurrency(amount, currencyCode)` and `l10n.formatDateTime(dateTime)` helpers (extend in `app_localizations.dart` if a formatter is missing).
- Avoid manual string interpolation for prices/dates; prefer the helper functions so locale-specific separators render correctly.
- For pluralization, add structured entries (`{"orders": {"one": "Order", "other": "Orders"}}`) and call `l10n.plural("orders", count)`.

## 5. Locale Switching Workflow
1. `LocaleProvider` exposes `currentLocale` and `setLocale(Locale locale)`.
2. POS app exposes a language switcher from the app bar menu; additional clients react to global changes (Riverpod listener).
3. Store preference in `LocaleService` (SharedPreferences) so relaunch preserves user selection per device.
4. Multi-tenant deployments may override defaults through remote config (planned). Until then, configure branch default in app settings.

## 6. Translation QA Plan
- **String coverage**: Run `dart run tools/check_missing_translations.dart` (TODO script) or manual diff to ensure parity between `en`/`ar`.
- **Visual verification**: Capture screenshots in both locales for each major flow (POS checkout, kitchen ticket detail) and validate text expansion.
- **RTL review**: Confirm alignment and mirroring on POS screens when switching to Arabic (especially dialogs, drawer icons, barcode overlay).
- **Fallback scan**: Enable debug flag `l10n.debugShowMissingTranslations = true` (planned) to highlight unresolved keys.
- **Glossary reference**: Maintain shared glossary (`docs/glossary.csv`, TODO) for consistent translations across services.

## 7. Next Steps
- Extend localization wiring to driver, customer, and admin apps using the same provider/service stack.
- Add automated widget tests that snapshot both locales for critical screens.
- Integrate translation management platform (e.g., Lokalise) once glossary is finalized for multi-team collaboration.
