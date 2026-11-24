# NN ElectroLab Store — Release 2 Foundation

This package is designed for the existing static PWA in `NabadipNath/CampusCircuit`.
It does not replace `index.html`, `styles.css`, `app.js`, `manifest.webmanifest`, or `sw.js`.

## Included files

- `supabase-config.js` — public project URL and publishable key.
- `backend/01-schema.sql` — Supabase Auth-linked schema, role model, RLS policies, indexes and product image bucket.
- `backend/02-seed-catalogue.sql` — inserts the four existing projects and twelve package variants.
- `backend/SETUP.md` — step-by-step deployment instructions.

## Step 1 — Upload the files

Copy these files into the root/backend folders of the existing GitHub repository:
- `supabase-config.js` to repository root
- the three SQL/setup files into `backend/`

Do not delete or replace your current PWA files.

## Step 2 — Run the database migration

1. Open the Supabase project.
2. Open **SQL Editor**.
3. Create a new query, paste all of `backend/01-schema.sql`, and run it.
4. Check the results for errors.
5. Create another query, paste `backend/02-seed-catalogue.sql`, and run it.
6. In **Table Editor**, verify `products` contains four rows and `product_variants` contains twelve rows.

IMPORTANT: Do not run the old `backend/schema.sql` from the starter release. It creates a custom `users` table with `password_hash`; this Release 2 schema uses Supabase Auth instead.

## Step 3 — Create your owner login

1. In Supabase, open **Authentication → Users**.
2. Add a user with your own email and a strong password.
3. Confirm the account is created.
4. In SQL Editor, run the owner promotion statement below after replacing the email:

```sql
update public.profiles
set role = 'owner', is_active = true
where id = (
  select id from auth.users
  where email = 'YOUR_LOGIN_EMAIL'
);
```

Do not promote ordinary customer accounts. Do not expose the owner password in source code.

## Step 4 — Add the Supabase SDK to the PWA

In `index.html`, add these script tags immediately before the existing `app.js` script:

```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script src="supabase-config.js"></script>
```

Then add `supabase-config.js` to the `CORE` list in `sw.js` so the public config is available with the offline app shell. The Supabase cloud itself still requires internet access.

## Security design

- The publishable key is intentionally public; it is not an admin credential.
- RLS is enabled for all application tables.
- Public visitors can read only published products and active variants.
- Staff/admin/owner roles can manage catalogue and operational records according to policies.
- Customer accounts can read only their own orders.
- Anonymous order creation is not enabled. The next checkout milestone should use a Supabase Edge Function to validate prices, reserve stock, create orders and later verify payment webhooks.
- Product images are public-read; uploads/updates/deletes require a staff/admin/owner role.
- Supabase Auth owns passwords. There is no application `password_hash` column.

## Important before production

This is the database foundation, not yet the complete Release 2 application. The current `app.js` still uses its local demo admin PIN and localStorage catalogue/cart. Do not treat the demo admin as secure. The next frontend milestone is to initialize the Supabase client, replace demo admin login with Supabase Auth, fetch the catalogue from Supabase, and build protected product management.

Never put a Supabase `secret` or `service_role` key, database password, payment secret, or webhook secret in GitHub Pages JavaScript.
