/** Minimal typed surface for Phase 1; expand as RPCs land in later phases. */
export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export interface Database {
  public: {
    Tables: {
      app_settings_public: {
        Row: {
          site_name: string
          price_per_test_pkr: number
          easypaisa_number: string
          easypaisa_title: string
          payment_instructions: string
          support_whatsapp: string
          support_email: string
          announcement_banner: string
          guest_access_id: string
          guest_version: number
          max_bookmarks: number
        }
      }
      profiles: {
        Row: {
          id: string
          full_name: string | null
          phone: string | null
          city: string | null
          display_name: string | null
          role: 'admin' | 'student' | 'guest'
          credits: number
          status: 'active' | 'disabled'
          guest_version: number
          guest_fail_count: number
          guest_locked_until: string | null
          is_leaderboard_hidden: boolean
          created_at: string
          updated_at: string
        }
      }
      categories: {
        Row: {
          id: string
          name: string
          slug: string
          group_name: string
          sort_order: number
        }
      }
      papers: {
        Row: {
          id: string
          title: string
          slug: string
          description: string
          duration_minutes: number
          question_count: number
          negative_mark: number
          is_published: boolean
        }
      }
    }
    Views: {
      app_settings_public: {
        Row: {
          site_name: string
          price_per_test_pkr: number
          easypaisa_number: string
          easypaisa_title: string
          payment_instructions: string
          support_whatsapp: string
          support_email: string
          announcement_banner: string
          guest_access_id: string
          guest_version: number
          max_bookmarks: number
        }
      }
    }
  }
}
