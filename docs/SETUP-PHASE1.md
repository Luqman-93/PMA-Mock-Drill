# Phase 1 setup guide (100% free tiers)

This guide gets **PMA Mock Test Drill** running locally and prepares Supabase + Cloudflare Pages. No credit card required for these steps.

## What Phase 1 includes

- Vite + React + TypeScript + Tailwind + React Router scaffold
- Full Postgres schema, RLS, storage policies, pg_cron cleanup stub
- Seed: app settings, 7 categories, **30 sample MCQs**, 2 sample mock papers
- GitHub Actions keep-alive workflow (optional but recommended)
- Landing page with DB connectivity check

**Not yet in Phase 1:** login, guest door, payments, tests, admin UI (Phases 2–7).

---

## 1. Local frontend

```powershell
cd D:\PMA\pma-mock-test-drill
copy .env.example .env
npm install
npm run dev
```

Open `http://localhost:5173`. Without Supabase env vars, the status card shows **Missing .env**.

Run tests:

```powershell
npm test -- --run
```

Production build (for Cloudflare later):

```powershell
npm run build
```

---

## 2. Create a Supabase project (free)

1. Go to [https://supabase.com](https://supabase.com) → **Start your project** (free tier).
2. **New project** → pick a name, strong DB password, region closest to Pakistan (e.g. Singapore or Mumbai if available).
3. Wait for the project to finish provisioning.

**Cost:** $0 on free tier. Limits include ~500 MB database, 1 GB file storage, paused projects after inactivity (we ping with GitHub Actions).

---

## 3. API keys and `.env`

1. Supabase → **Project Settings** → **API**.
2. Copy **Project URL** → `VITE_SUPABASE_URL`
3. Copy **anon public** key → `VITE_SUPABASE_ANON_KEY`
4. Paste into `pma-mock-test-drill/.env` (never commit this file).

**Never** put the `service_role` key in the frontend or Cloudflare Pages build env for the site.

---

## 4. Run SQL migrations

Supabase → **SQL Editor** → New query.

Run in order (copy entire file contents each time):

1. `supabase/migrations/20251015000001_initial_schema.sql`
2. `supabase/migrations/20251015000002_storage_policies.sql` (after creating bucket — see step 6)
3. `supabase/seed/seed.sql`

For step 2, if the bucket insert fails, create the bucket in the UI first (step 6), then run only the `CREATE POLICY` lines from file 2.

---

## 5. Auth settings (for Phase 2, set up now)

Supabase → **Authentication** → **Providers**:

- **Email**: enable email + password.
- **Confirm email**: **OFF** (works on free tier without SMTP).
- **Anonymous sign-ins**: **ON** (required for guest door in Phase 2).

Optional later (free SMTP for password reset): use [Resend](https://resend.com) free tier or [Brevo](https://www.brevo.com) and configure Supabase → Authentication → SMTP.

---

## 6. Storage bucket (payments — Phase 3)

1. **Storage** → **New bucket**
   - Name: `payment-screenshots`
   - **Private**
   - File size limit: 5 MB
   - Allowed MIME: JPEG, PNG, WEBP
2. Run `20251015000002_storage_policies.sql` if not already applied.

---

## 7. pg_cron (10-minute review cleanup — Phase 4)

1. **Database** → **Extensions** → enable **pg_cron**.
2. Run `supabase/migrations/20251015000003_cron_cleanup.sql`.

---

## 8. Make yourself admin (after you register in Phase 2)

For now, if you create a user manually in Auth, or after your first signup:

```sql
-- Replace with your auth user uuid from Authentication → Users
UPDATE public.profiles
SET role = 'admin'
WHERE id = 'YOUR-USER-UUID-HERE';
```

Your admin login email is stored only in `app_settings.admin_notification_email` (`umerluqman93@gmail.com`) — not shown on public pages.

---

## 9. Cloudflare Pages (commercial-friendly hosting)

1. Push this repo to **GitHub** (free).
2. [Cloudflare Dashboard](https://dash.cloudflare.com) → **Workers & Pages** → **Create** → **Pages** → Connect Git.
3. Select the repo, project name e.g. `pma-mock-test-drill`.
4. Build settings:
   - **Framework preset:** Vite
   - **Build command:** `npm run build`
   - **Build output directory:** `dist`
5. **Environment variables** (Production):
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
   - (Phase 2+) `VITE_TURNSTILE_SITE_KEY`
6. Deploy. Custom domain can be added on free plan.

**Do not use Vercel Hobby** for a paid student product (non-commercial restriction). Cloudflare Pages free tier allows commercial use.

---

## 10. GitHub keep-alive (optional)

Repo → **Settings** → **Secrets and variables** → **Actions**:

- `SUPABASE_URL` = same as VITE_SUPABASE_URL
- `SUPABASE_ANON_KEY` = anon key

Workflow file: `.github/workflows/supabase-keepalive.yml` (runs every 3 days).

---

## 11. Monitor free-tier usage

| Resource | Where to check |
|----------|----------------|
| Database size | Supabase → **Database** → **Reports** / Settings |
| Storage | Supabase → **Storage** → usage |
| Auth MAUs | Supabase → **Authentication** → usage |
| Bandwidth | Supabase project home usage meters |

Keep screenshots compressed (~400 KB client-side in Phase 3) and paginate admin lists at 50 rows.

---

## 12. Easypaisa account title

Seed leaves `easypaisa_title` empty until you provide the account title (Phase 3 payment page). You can also run:

```sql
UPDATE public.app_settings SET easypaisa_title = 'Your Account Title Here' WHERE id = 1;
```

---

## Phase 1 verification checklist

- [ ] `npm run dev` loads landing page with army-green theme
- [ ] `.env` set → status card shows **Database connection: OK**
- [ ] **Categories seeded: 7**
- [ ] SQL Editor: `SELECT count(*) FROM questions WHERE is_sample = true;` → **30**
- [ ] Two papers: `SELECT title FROM papers;`
- [ ] `npm test -- --run` passes
- [ ] Footer shows unofficial disclaimer

When this checklist passes, reply **approve Phase 1** to continue to **Phase 2 (auth + guest door)**.
