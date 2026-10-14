/**
 * Pure helpers mirrored by server RPC rules (Phase 3+). Used in unit tests.
 */

export function balanceAfterLedger(current: number, delta: number): number {
  const next = current + delta
  if (next < 0) throw new Error('Credits cannot go negative')
  return next
}

/** Starting a test should charge at most once per attempt id. */
export function shouldChargeCredit(
  attemptStatus: 'in_progress' | 'submitted' | 'expired',
  creditCharged: boolean,
): boolean {
  if (attemptStatus !== 'in_progress') return false
  return !creditCharged
}

/** Admin approval must not apply twice for the same payment. */
export function canApprovePayment(status: 'pending' | 'approved' | 'rejected'): boolean {
  return status === 'pending'
}
