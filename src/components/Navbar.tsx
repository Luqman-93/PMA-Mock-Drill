import { Link } from 'react-router-dom'
import { Shield } from 'lucide-react'
import { useSiteSettings } from '../hooks/useSiteSettings'

export function Navbar() {
  const { settings } = useSiteSettings()
  const siteName = settings?.site_name ?? 'PMA Mock Test Drill'

  return (
    <header className="sticky top-0 z-40 border-b border-army-muted/60 bg-army-primary text-white shadow-sm">
      <div className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-3">
        <Link to="/" className="flex min-h-11 items-center gap-2 font-semibold tracking-tight">
          <Shield className="h-6 w-6 text-army-accent" aria-hidden />
          <span>{siteName}</span>
        </Link>
        <nav className="flex items-center gap-2 text-sm">
          <Link
            to="/"
            className="min-h-11 min-w-11 inline-flex items-center justify-center rounded-lg px-3 hover:bg-white/10"
          >
            Home
          </Link>
        </nav>
      </div>
    </header>
  )
}
