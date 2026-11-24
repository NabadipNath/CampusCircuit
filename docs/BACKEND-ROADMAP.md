# NN ElectroLab Store — Full-stack roadmap

## Release 1 (this package): PWA storefront
Static-first application, install prompt, offline shell, catalogue, local cart, WhatsApp enquiry and demo admin view.

## Release 2: API + database
Suggested free/open-source-friendly stack:
- API: Node.js + Express or Fastify
- Database: PostgreSQL (Supabase free tier or self-hosted PostgreSQL)
- ORM/migrations: Prisma or Drizzle
- Authentication: server-side sessions with secure, HttpOnly cookies; role-based access control
- File storage: Supabase Storage or an S3-compatible service
- Hosting: Cloudflare Pages for frontend; Render/Fly.io or Supabase for API/database, subject to current free-tier limits

### Suggested REST endpoints
| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/api/health` | Service health |
| GET | `/api/products` | Public catalogue |
| GET | `/api/products/:slug` | Product detail |
| POST | `/api/orders` | Create pending order |
| GET | `/api/orders/:id` | Customer order status (protected token) |
| POST | `/api/payments/create` | Create provider checkout session |
| POST | `/api/payments/webhook` | Verify payment provider signature |
| POST | `/api/admin/session` | Admin login |
| GET/POST/PATCH/DELETE | `/api/admin/products` | Product CRUD |
| GET/PATCH | `/api/admin/orders` | Order operations |
| GET/POST/PATCH | `/api/admin/inventory` | Stock management |

## Security requirements before production
- Never store admin passwords, payment secrets or API keys in frontend JavaScript.
- Hash passwords with Argon2id or bcrypt; enforce MFA for owner/admin accounts.
- Use secure, HttpOnly, SameSite cookies and CSRF protection.
- Verify payment webhooks server-side; never trust a browser redirect as proof of payment.
- Validate all input server-side; add rate limiting and structured audit logs.
- Use least-privilege database credentials and automated backups.
- Add privacy policy, terms, refund/shipping policy and customer consent as applicable.

## Multi-device behaviour
The frontend in this release stores the cart locally. A database-backed API is required for shared owner/cashier/admin views, inventory synchronisation and cross-device order tracking.
