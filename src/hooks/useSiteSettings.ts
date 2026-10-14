import { useEffect, useState } from 'react'
import { supabase, isSupabaseConfigured } from '../services/supabase'
import type { Database } from '../types/database'

type PublicSettings = Database['public']['Views']['app_settings_public']['Row']

export function useSiteSettings() {
  const [settings, setSettings] = useState<PublicSettings | null>(null)
  const [loading, setLoading] = useState(isSupabaseConfigured)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!supabase) {
      setLoading(false)
      return
    }

    let cancelled = false

    void (async () => {
      const { data, error: qErr } = await supabase
        .from('app_settings_public')
        .select('*')
        .maybeSingle()

      if (cancelled) return
      if (qErr) {
        setError(qErr.message)
      } else {
        setSettings(data)
      }
      setLoading(false)
    })()

    return () => {
      cancelled = true
    }
  }, [])

  return { settings, loading, error }
}
