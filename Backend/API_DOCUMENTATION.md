# sharePlate API reference

This reference covers the Django REST API implemented in the `Backend` directory.

## Base URL and authentication

- Local server: `http://127.0.0.1:8000`
- Android emulator: `http://10.0.2.2:8000`
- Protected routes require `Authorization: Bearer <access-token>`.
- JSON is accepted by default; use `multipart/form-data` for registration documents and donation images.
- Access tokens last 30 days and refresh tokens last 90 days.

Roles are `CUSTOMER`, `BUSINESS`, and `NGO`. Unless noted, all non-auth routes require a JWT.

## Authentication

### `POST /api/auth/register/customer/`

Public. Required: `phone_num`, `email`, `password`. Optional: `full_name`, `address`.

```json
{
  "phone_num": "9841234567",
  "email": "customer@example.com",
  "password": "StrongPassword123",
  "full_name": "Rojina Shrestha",
  "address": "Lazimpat, Kathmandu"
}
```

Returns `201` with `message`, `user`, `profile`, `access`, and `refresh`.

### `POST /api/auth/register/business/`

Public. Required: `phone_num`, `email`, `password`. Optional: `business_name`, `contact_name`, `business_type`, `registration_number`, `registration_document`, `address`, `latitude`, `longitude`. Supports multipart form data and returns the same token envelope as customer registration.

### `POST /api/auth/register/ngo/`

Public. Required: `phone_num`, `email`, `password`. Optional: `organization_name`, `organization_type`, `contact_name`, `registration_number`, `registration_document`, `address`, `latitude`, `longitude`. Supports multipart form data and returns the same token envelope.

### `POST /api/auth/register/user/`

Public generic user creation endpoint. Fields follow the user serializer; later operations on this route are admin-only.

### `POST /api/auth/login/`

Public. Supply `password` and one identifier: `phone_num`, `email`, or `username`.

```json
{ "email": "customer@example.com", "password": "StrongPassword123" }
```

Returns `200` with `user`, role-specific `profile`, `access`, and `refresh`.

### `POST /api/auth/logout/`

```json
{ "refresh": "<refresh-token>" }
```

Blacklists the refresh token and returns `200`.

## Profiles

### `GET /api/profiles/me/`

Returns the caller’s role-specific profile plus `email`, `phone_num`, and `role`.

### `PATCH|PUT /api/profiles/me/`

Updates the current profile. `phone_num` and `email` update the user; remaining fields update the profile. Use multipart data to upload `registration_document`.

- Customer: `full_name`, `address`
- Business: `business_name`, `contact_name`, `business_type`, `registration_number`, `registration_document`, `address`, `latitude`, `longitude`, `verification_status`
- NGO: `organization_name`, `organization_type`, `registration_number`, `contact_name`, `registration_document`, `address`, `latitude`, `longitude`, `verification_status`, `total_meals_received`, `people_supported`, `description`, `current_needs`, `urgency_level`

### `GET|POST /api/profiles/documents/`

Lists the caller’s verification documents or creates one. For upload, use multipart form data with document fields such as `title`, `document_file`, `file_name`, `document_type`, `issued_id_number`, and `issuer_authority`.

### `GET /api/profiles/nearby-ngos/`

Public. Lists NGO profiles. Optional query parameters: `latitude`, `longitude`, `radius_km`. When coordinates are supplied, the response includes calculated `distance_km` and applies the radius filter.

## Donations

### `GET /api/donations/`

Lists role-appropriate listings:

- Business: its own listings
- NGO: available donations in the NGO-priority window
- Customer: available flash sales
- Staff: all listings

Optional filters: `food_type`, `listing_type`, `status`, `latitude`, `longitude`, `radius_km`.

### `POST /api/donations/`

Business or staff only. Required: `title`, `description`, `food_type`, `quantity`, `people_served`.

```json
{
  "title": "Surplus rice with curry",
  "description": "Freshly cooked meal",
  "food_type": "VEG",
  "quantity": 10,
  "people_served": 15,
  "listing_type": "DONATION",
  "quantity_unit": "Plates",
  "best_before": "2026-08-15T22:00:00Z",
  "ngo_priority_duration_minutes": 45,
  "pickup_address": "Lazimpat, Kathmandu",
  "latitude": "27.7172",
  "longitude": "85.3240"
}
```

Optional fields include `best_before_hours`, `price`, `flash_sale_price`, `food_photo` (or `photo`), `fresh_at`, `pickup_window_start`, `pickup_window_end`, `pickup_instructions`, `contact_name`, `contact_phone`, `visibility_radius_km`, `pack_size`, and `auto_discount_percent`. `flash_sale_price` is required for `FLASH_SALE` listings. Valid food types are `VEG`, `NONVEG`, `MIXED`.

### `GET|PATCH|PUT|DELETE /api/donations/{id}/`

Retrieves, updates, or deletes a listing. Only the donor or staff may change a listing.

### `GET /api/donations/ngo_priority/`

NGO or staff only. Lists active donation listings in the NGO priority window.

### `GET /api/donations/flash_sales/`

Lists available flash-sale listings.

### `POST /api/donations/{id}/claim/`

NGO or staff only. Claims an available donation during its priority window.

```json
{
  "pickup_method": "SELF",
  "scheduled_pickup_start": "2026-08-15T18:00:00Z",
  "scheduled_pickup_end": "2026-08-15T19:00:00Z",
  "volunteer_name": "Bikash Adhikari",
  "volunteer_phone": "9845012345",
  "donor_note": "Collecting with our van",
  "people_served_confirmed": 12
}
```

Returns `201` with the claim and a pickup-ticket QR code.

### `POST /api/donations/{id}/reserve/`

Customer or staff only. Reserves an available flash sale and creates an order and pickup ticket. Returns `201` with `reservation` and `order_code`.

### `POST /api/donations/{id}/convert_to_flash_sale/`

Donor or staff only. Converts a listing. Optional body: `{ "flash_sale_price": "120.00" }`.

### `POST /api/donations/{id}/cancel/`

Donor or staff only. Cancels the listing and its related claim, reservation, or order.

### `POST /api/donations/verify_pickup/`

Business or staff only. Verify a collection with either `{ "qr_code": "..." }` or `{ "manual_code": "..." }`. Successful verification marks the listing as picked up.

## Claims, reservations, orders, and contributions

| Resource | Routes | Access / behaviour |
| --- | --- | --- |
| Claims | `GET, POST /api/claims/`; `GET, PATCH, PUT, DELETE /api/claims/{id}/` | NGOs create claims and see their own; businesses see claims for their listings; staff see all. |
| Reservations | `GET, POST /api/reservations/`; `GET, PATCH, PUT, DELETE /api/reservations/{id}/` | Customers create reservations and see their own; businesses see reservations for their listings; staff see all. |
| Orders | `GET /api/orders/`; `GET /api/orders/{id}/` | Customers see their orders; businesses see orders for their listings; staff see all. |
| Sponsorship items | `GET /api/sponsorship-items/`; `GET /api/sponsorship-items/{id}/` | Active meal-sponsorship items. |
| Sponsorships | `GET, POST /api/sponsorships/`; `GET /api/sponsorships/{id}/` | Customers create/view their sponsorships; staff see all. |
| Contributions | `GET /api/contributions/`; `GET /api/contributions/{id}/` | Businesses see their contributions; NGOs see contributions for them; staff see all. |

Direct claim creation uses `donation_id` plus the claim fields shown above. Direct reservation creation uses `donation_id` and optional `quantity`.

Create a charity sponsorship with:

```json
{
  "surplus_item_id": 1,
  "meals_count": 10,
  "dedication": "In celebration of our team"
}
```

## Notifications

- `GET /api/notifications/` — list the caller’s notifications.
- `GET|PATCH|PUT|DELETE /api/notifications/{id}/` — access one notification.
- `PATCH /api/notifications/{id}/read/` — mark one notification as read.
- `POST /api/notifications/read-all/` — mark every unread notification as read.
- `GET /api/notification-settings/` — get (or create) the caller’s preferences.
- `POST /api/notification-settings/` — partially update preferences, for example:

```json
{
  "email_notifications": true,
  "push_notifications": true,
  "sms_alerts": false,
  "expiry_reminders": true,
  "claim_alerts": true
}
```

## Listing flow and QR pickup

- `GET /api/listing-flow/{id}/detail/` — full listing-flow detail.
- `GET|PUT|PATCH /api/listing-flow/{id}/listing-detail/` — business donor only; reads/updates `fresh_at`, pickup-window, instructions, contact, visibility, pack size, and automatic discount fields.
- `GET /api/listing-flow/{id}/listing-update/` — priority countdown/status, listing detail, conversion, and donor action flags.
- `POST /api/listing-flow/{id}/adjust-price/` — donor only; body: `{ "flash_sale_price": "120.00" }`.
- `POST /api/listing-flow/{id}/keep-donation-only/` — donor only; closes the listing without converting it to a sale.
- `POST /api/listing-flow/{id}/process-priority-expiry/` — processes priority expiry and returns the resulting status/type.

### Claim holds

- `GET /api/claim-holds/` — NGO only; lists active holds.
- `POST /api/claim-holds/` — NGO only; body: `{ "donation_id": 10 }`.
- `POST /api/claim-holds/{id}/confirm/` — NGO only. Required: `pickup_method`, `scheduled_pickup_start`, `scheduled_pickup_end`, `people_served_confirmed`. `volunteer_id` is required for `pickup_method: "VOLUNTEER"`; `donor_note` is optional.
- `POST /api/claim-holds/{id}/cancel/` — cancels the caller’s own hold.

### QR and verification

- `GET /api/pickup-qr/by-claim/{claim_id}/` — QR/manual-code payload for the claiming NGO or associated donor.
- `GET /api/pickup-qr/by-ticket/{ticket_id}/` — QR/manual-code payload for a pickup ticket.
- `POST /api/verify-pickup/` — business only; verifies `qr_code` or `manual_code`.
- `GET /api/verify-pickup/expected/{code}/` — business only; previews the pickup tied to a QR or manual code for its own listing.

## Status codes and errors

- `200 OK`: successful read or update
- `201 Created`: successful creation
- `204 No Content`: successful deletion
- `400 Bad Request`: validation or business-rule error
- `401 Unauthorized`: missing/invalid JWT
- `403 Forbidden`: insufficient role or ownership
- `404 Not Found`: no matching resource

Validation responses use DRF field errors. Business-rule errors generally use `{ "error": "..." }`. Timestamps are ISO 8601; in development uploaded media is available beneath `/media/`.
