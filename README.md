# PMA Mock Test Drill

Unofficial PMA Long Course mock-test portal (React + Supabase + Cloudflare Pages). Built in phases.

| Phase | Scope | Status |
|-------|--------|--------|
| **1** | Scaffold, SQL, RLS, seed | ✅ Ready for review |
| 2 | Auth + guest access | Pending |
| 3 | Easypaisa payments + admin approval | Pending |
| 4 | Test engine + review window | Pending |
| 5 | History, bookmarks, weak topics, leaderboard | Pending |
| 6 | Admin questions, papers, reports | Pending |
| 7 | Polish + deployment hardening | Pending |

## Quick start

See **[docs/SETUP-PHASE1.md](./docs/SETUP-PHASE1.md)** for step-by-step free setup.

```powershell
cd pma-mock-test-drill
npm install
copy .env.example .env
npm run dev
```

## Project layout

```text
src/components/     Shared UI
src/pages/          Route pages (student + admin later)
src/hooks/          Data hooks
src/services/       Supabase client
src/lib/            Helpers + tests
supabase/migrations SQL schema & policies
supabase/seed/      Seed data
public/templates/   CSV import template (admin Phase 6)
.github/workflows/  Supabase keep-alive ping
```

**Disclaimer:** Not affiliated with Pakistan Army or PMA.
