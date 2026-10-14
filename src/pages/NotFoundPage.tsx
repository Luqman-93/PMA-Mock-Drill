import { Link } from 'react-router-dom'

export function NotFoundPage() {
  return (
    <div className="py-16 text-center">
      <h1 className="text-2xl font-bold text-army-primary">Page not found</h1>
      <p className="mt-2 text-army-dark/70">The page you requested does not exist.</p>
      <Link
        to="/"
        className="mt-6 inline-flex min-h-11 items-center rounded-xl bg-army-primary px-5 text-white hover:bg-army-dark"
      >
        Back to home
      </Link>
    </div>
  )
}
