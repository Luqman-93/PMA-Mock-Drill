import { describe, expect, it } from 'vitest'
import {
  balanceAfterLedger,
  canApprovePayment,
  shouldChargeCredit,
} from './credits'

describe('credit helpers', () => {
  it('rejects negative balance', () => {
    expect(() => balanceAfterLedger(0, -1)).toThrow()
  })

  it('does not double-charge on resume', () => {
    expect(shouldChargeCredit('in_progress', true)).toBe(false)
    expect(shouldChargeCredit('in_progress', false)).toBe(true)
  })

  it('does not charge after submit', () => {
    expect(shouldChargeCredit('submitted', false)).toBe(false)
  })

  it('blocks double approval', () => {
    expect(canApprovePayment('pending')).toBe(true)
    expect(canApprovePayment('approved')).toBe(false)
    expect(canApprovePayment('rejected')).toBe(false)
  })
})
