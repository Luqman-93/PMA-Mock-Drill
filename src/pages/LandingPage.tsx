import { CheckCircle2, Clock, Smartphone } from 'lucide-react'
import { useSiteSettings } from '../hooks/useSiteSettings'
import { formatPkr } from '../lib/time'
import { isSupabaseConfigured, supabase } from '../services/supabase'
import { useEffect, useState } from 'react'

export function LandingPage() {
  const { settings, loading, error } = useSiteSettings()
  const [categoryCount, setCategoryCount] = useState<number | null>(null)
  const [dbOk, setDbOk] = useState<boolean | null>(null)

  useEffect(() => {
    if (!supabase) return
    void (async () => {
      const { count, error: cErr } = await supabase
        .from('categories')
        .select('*', { count: 'exact', head: true })
      setCategoryCount(cErr ? null : count)
      setDbOk(!cErr)
    })()
  }, [])

  const price = settings?.price_per_test_pkr ?? 500

  return (
    <div className="space-y-10">
      {settings?.announcement_banner ? (
        <div className="rounded-xl border border-army-accent/40 bg-army-accent/10 px-4 py-3 text-sm">
          {settings.announcement_banner}
        </div>
      ) : null}

      <section className="grid gap-8 lg:grid-cols-2 lg:items-center">
        <div>
          <p className="text-sm font-semibold uppercase tracking-wide text-army-accent">
            PMA Long Course preparation
          </p>
          <h1 className="mt-2 text-3xl font-bold text-army-primary sm:text-4xl">
            Practice MCQs with timed mock tests
          </h1>
          <p className="mt-4 text-lg text-army-dark/80">
            Mobile-first portal for verbal and academic drills. Pay per test via Easypaisa,
            or use a guest access ID from your instructor.
          </p>
          <ul className="mt-6 space-y-3 text-army-dark/90">
            <li className="flex gap-2">
              <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-success" />
              Server-timed tests with autosave and resume
            </li>
            <li className="flex gap-2">
              <Clock className="mt-0.5 h-5 w-5 shrink-0 text-army-accent" />
              10-minute answer review after each attempt
            </li>
            <li className="flex gap-2">
              <Smartphone className="mt-0.5 h-5 w-5 shrink-0 text-army-primary" />
              Built for phones — large tap targets, clean palette
            </li>
          </ul>
          <p className="mt-6 text-xl font-semibold text-army-primary">
            {loading ? '…' : formatPkr(price)} <span className="text-base font-normal">per test</span>
          </p>
        </div>

        <div className="rounded-2xl border border-army-muted bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-army-primary">Phase 1 status</h2>
          <dl className="mt-4 space-y-3 text-sm">
            <div className="flex justify-between gap-4">
              <dt>Supabase env</dt>
              <dd className={isSupabaseConfigured ? 'text-success' : 'text-danger'}>
                {isSupabaseConfigured ? 'Configured' : 'Missing .env'}
              </dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt>Database connection</dt>
              <dd>
                {!isSupabaseConfigured
                  ? '—'
                  : dbOk === null
                    ? 'Checking…'
                    : dbOk
                      ? 'OK'
                      : 'Failed'}
              </dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt>Categories seeded</dt>
              <dd>{categoryCount ?? (error ? '—' : '…')}</dd>
            </div>
          </dl>
          {error ? (
            <p className="mt-4 rounded-lg bg-danger/10 px-3 py-2 text-sm text-danger">
              {error} — run migrations and seed SQL in Supabase.
            </p>
          ) : null}
          <p className="mt-4 text-xs text-army-dark/60">
            Next phases: guest login, Easypaisa payments, full test engine, admin panel.
          </p>
        </div>
      </section>
    </div>
  )
}
