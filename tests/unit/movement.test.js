import { describe, expect, it } from 'vitest';
import {
  computeHorizontalVelocity,
  MOVE_SPEED,
  shouldJump,
} from '../../src/game/logic/movement.js';

describe('computeHorizontalVelocity', () => {
  it('returns negative speed when left is pressed', () => {
    expect(computeHorizontalVelocity(true, false)).toBe(-MOVE_SPEED);
  });

  it('returns positive speed when right is pressed', () => {
    expect(computeHorizontalVelocity(false, true)).toBe(MOVE_SPEED);
  });

  it('returns zero when both directions are pressed', () => {
    expect(computeHorizontalVelocity(true, true)).toBe(0);
  });

  it('returns zero when no direction is pressed', () => {
    expect(computeHorizontalVelocity(false, false)).toBe(0);
  });
});

describe('shouldJump', () => {
  it('returns true when jump is newly pressed and player is grounded', () => {
    expect(shouldJump(true, true)).toBe(true);
  });

  it('returns false when jump is not newly pressed', () => {
    expect(shouldJump(false, true)).toBe(false);
  });

  it('returns false when player is in the air', () => {
    expect(shouldJump(true, false)).toBe(false);
  });
});
