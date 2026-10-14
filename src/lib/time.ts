const KARACHI = 'Asia/Karachi'

export function formatKarachiDateTime(iso: string | Date): string {
  const d = typeof iso === 'string' ? new Date(iso) : iso
  return new Intl.DateTimeFormat('en-GB', {
    timeZone: KARACHI,
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  }).format(d)
}

export function formatPkr(amount: number): string {
  return `Rs ${amount.toLocaleString('en-PK')}`
}
