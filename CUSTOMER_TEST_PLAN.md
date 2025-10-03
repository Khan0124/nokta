# Customer App Test Scenarios

## Scope
End-to-end validation for the localized Nokta customer application covering guest discovery, checkout, loyalty insights, and realtime order tracking flows across Arabic and English locales.

## Environments
- **Mobile Flutter build** (debug or release) using the bundled customer experience service for demo data.
- **Network conditions**: online and simulated offline (Airplane mode) to verify graceful messaging.

## Personas
- **Guest user** (no login) browsing and placing a delivery order.
- **Returning customer** with loyalty history reviewing profile insights and tracking an active order.

## Test Matrix

| Area | Scenario | Steps | Expected |
| --- | --- | --- | --- |
| Localization | Toggle language | From home header switch between Arabic/English | UI flips direction, copy updates without restart |
| Discovery | Featured carousel | Scroll featured rail and open a restaurant | Restaurant detail renders with menu sections and info panel |
| Cart | Add from modal | Tap product > increase quantity > add | Snack bar confirmation, cart badge increments |
| Checkout | Delivery flow | Choose delivery, select address, pick schedule, pick cash, add note, place order | Success toast, navigation to tracking view |
| Checkout | Address validation | Attempt delivery checkout without selecting address | CTA disabled, helper text informs user |
| Suggestions | Quick add | Tap suggestion chip in checkout | Item appears in cart summary |
| Tracking | Timeline updates | Observe timeline for seeded order 1001 | Stages highlight sequentially, map placeholder renders coordinates |
| Tracking | Driver info | Confirm driver card actions visible | Call/chat buttons enabled |
| Profile | Loyalty snapshot | Open profile | Points and tier data visible |
| Search | Query dishes | Enter "wrap" | Matching products listed with add-to-cart action |
| Offline messaging | Disable connectivity | Toggle Airplane mode from OS | Async sections show loading then retry copy |

## Regression Checklist
- Home navigation bar updates selection state accurately.
- Bottom floating checkout button respects RTL alignment.
- AppLocalizations returns correct currency format for SAR in both locales.
- Cart clears after successful checkout.
- Stream providers dispose without leaks when leaving tracking screen.

## QA Notes
- Demo services seed order `1001` for tracking; use it for validation.
- Profile screen currently surfaces stubs for address/payment management—mark as informational only.
