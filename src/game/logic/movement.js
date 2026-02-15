export const MOVE_SPEED = 220;
export const JUMP_VELOCITY = -560;

export function computeHorizontalVelocity(isLeftPressed, isRightPressed, speed = MOVE_SPEED) {
  if (isLeftPressed === isRightPressed) {
    return 0;
  }

  return isLeftPressed ? -speed : speed;
}

export function shouldJump(jumpJustPressed, isOnGround) {
  return Boolean(jumpJustPressed && isOnGround);
}
