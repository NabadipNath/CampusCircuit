# NN ElectroLab Store V2 — PWA Starter Release

This package is a standalone V2 starter for the public NN ElectroLab Store repository. It retains the existing dark obsidian / PCB-grid visual language, green and amber accents, contact details, WhatsApp workflow and all four catalogue projects visible in the current repository.

## Included
- Responsive storefront and searchable category-filtered catalogue
- Four original project entries with technical specifications, BOM estimates and three package tiers
- Product detail views, local cart persistence and WhatsApp order enquiry
- Custom prototype request form routed to WhatsApp
- Installable PWA manifest, service worker and offline shell caching
- Local demo admin console with catalogue overview and JSON/CSV export
- Backend/API integration blueprint and environment example

## Run locally
A PWA service worker requires HTTPS or localhost. Do not open `index.html` directly using `file://`.

### Python
```bash
cd NN-ElectroLab-Store-V2
python3 -m http.server 8080
```
Open `http://localhost:8080`.

### Node
```bash
npx serve .
```

## Deploy free
- **GitHub Pages:** upload the package contents to the repository root (or a release branch), enable Pages for the chosen branch/folder, then visit the HTTPS Pages URL.
- **Cloudflare Pages:** connect the repository or upload this folder as a static site. No build command is required; output directory is `/`.
- **Netlify:** drag-and-drop the folder or connect the repository. No build command is required.

If deploying under a repository subpath (GitHub Pages project site), the relative URLs in this package are already used for the app shell and service worker.

## Demo admin
Click the gear icon and enter `2468`. This is a **local demonstration only**. It is not secure authentication. The PIN is visible in `app.js`, data lives in the current browser's localStorage, and it must not be used to protect real customer records or payment operations.

## Important commerce notes
- WhatsApp ordering is functional and sends an enquiry containing selected packages and estimated prices.
- The original repository's Razorpay URLs were placeholder links. This release intentionally does not pretend that payment processing is live. Configure a verified payment provider on the server before accepting payments.
- Prices are catalogue estimates and should be confirmed before customer payment.
- The local cart is per browser/device. It is not a shared multi-device cart.

## Next full-stack phase
See `docs/BACKEND-ROADMAP.md` and `backend/schema.sql`. A production release should add server-side authentication, database-backed catalogue and orders, verified payment webhooks, stock reservation, shipping status, admin audit logs, backups and rate limiting.

## Repository integration
1. Keep a backup of the current `index.html`.
2. Upload/replace the package files in the repository.
3. Test the HTTPS deployment on desktop and mobile.
4. Confirm product names, prices, contact details and fulfilment terms before publishing.
5. Do not publish the demo admin PIN as a real security measure.
