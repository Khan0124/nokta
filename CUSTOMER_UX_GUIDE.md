# Customer App Experience Guide

## Overview
The Nokta customer experience enables diners to discover restaurants, place multilingual delivery or pickup orders, and track fulfilment in real time. The mobile-friendly Flutter app now shares the same localization, loyalty, and offline-ready foundations as the POS and driver surfaces.

## Key Flows

### 1. Browsing & Discovery
- **Localized home hub** greets the guest, surfaces featured restaurants, nearby options, and a recommendation rail powered by curated highlights.
- **Search omnibox** is available from the hero header or the navigation bar and queries dishes and restaurants instantly.
- **Categories & promotions** leverage loyalty context to spotlight timely offers.

### 2. Restaurant Exploration
- **Rich hero header** summarises cuisine, delivery SLA, and badges (favourites, free delivery, loyalty perks).
- **Structured info panels** detail address, hours, contact, and accepted payment methods.
- **Menu sections** stay pinned via a sliver tab bar; product cards support quick-add while a modal sheet lets customers set quantities and review descriptions.

### 3. Cart & Checkout
- **Global cart indicator** floats above bottom navigation and converts into a contextual checkout CTA with localized currency formatting.
- **Checkout wizard** walks through fulfilment mode, delivery address selection, scheduling, payment choice, and free-form notes.
- **Contextual suggestions** surface complementary dishes via the shared customer experience service.

### 4. Order Tracking
- **Live timeline** reflects real-time stage updates (placed → confirmed → preparing → driver assigned → on the way → delivered).
- **Driver snapshot** presents call/chat actions, vehicle metadata, and the most recent GPS breadcrumb.
- **Support affordance** is available from the app bar to trigger customer care playbooks.

### 5. Account & Loyalty
- **Profile hub** summarises loyalty points, tier progress, saved addresses, payment methods, and preference entry points.
- **Locale toggle** is accessible from the home header to switch between Arabic and English instantly while preserving RTL/LTR layouts.

## Accessibility & Localization
- All copy is sourced from `packages/core/assets/i18n/{en,ar}.json` and rendered via `context.l10n` to ensure consistent translation handling.
- Layouts respect text direction automatically and use semantic widgets (NavigationBar, ChoiceChip, FilledButton) for screen readers.

## Integration Touchpoints
- Shares `customer_experience_service.dart` with Riverpod providers for menus, loyalty, and tracking.
- Reuses core widgets (order tracking, checkout controls) and exposes additional customer-specific building blocks.

## Future Enhancements
- Payment tokenisation and wallet integrations.
- Deeper loyalty redemption (apply rewards directly in checkout).
- Push notifications for key timeline events.
