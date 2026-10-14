import { lazy, Suspense } from 'react'
import { BrowserRouter, Route, Routes } from 'react-router-dom'
import { Layout } from './components/Layout'

const LandingPage = lazy(() =>
  import('./pages/LandingPage').then((m) => ({ default: m.LandingPage })),
)
const NotFoundPage = lazy(() =>
  import('./pages/NotFoundPage').then((m) => ({ default: m.NotFoundPage })),
)

function PageFallback() {
  return (
    <div className="animate-pulse space-y-4 py-8">
      <div className="h-8 w-2/3 rounded bg-army-muted" />
      <div className="h-4 w-full rounded bg-army-muted/70" />
      <div className="h-4 w-5/6 rounded bg-army-muted/70" />
    </div>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route
            index
            element={
              <Suspense fallback={<PageFallback />}>
                <LandingPage />
              </Suspense>
            }
          />
          <Route
            path="*"
            element={
              <Suspense fallback={<PageFallback />}>
                <NotFoundPage />
              </Suspense>
            }
          />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}
