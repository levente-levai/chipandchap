import Phaser from 'phaser';
import chipFramesUrl from '../../../assets/processed/chip/chip.frames.png';
import chipFramesMeta from '../../../assets/processed/chip/chip.frames.json';
import {
  computeHorizontalVelocity,
  JUMP_VELOCITY,
  shouldJump,
} from '../logic/movement.js';

const CHIP_SCALE = 0.35;

function createSolidTexture(scene, key, width, height, color) {
  const graphics = scene.add.graphics();
  graphics.fillStyle(color, 1);
  graphics.fillRect(0, 0, width, height);
  graphics.generateTexture(key, width, height);
  graphics.destroy();
}

function updateTestState(scene, player) {
  if (typeof window === 'undefined' || !window.__chipChap) {
    return;
  }

  window.__chipChap.ready = true;
  window.__chipChap.scene = scene.scene.key;
  window.__chipChap.player.x = player.x;
  window.__chipChap.player.y = player.y;
}

export class RoomScene extends Phaser.Scene {
  constructor() {
    super('TheRoom');
  }

  preload() {
    this.load.spritesheet('chip', chipFramesUrl, {
      frameWidth: chipFramesMeta.frameWidth,
      frameHeight: chipFramesMeta.frameHeight,
    });
  }

  create() {
    createSolidTexture(this, 'platform', 128, 32, 0x6f8fa5);

    this.physics.world.setBounds(0, 0, 800, 600);

    const platforms = this.physics.add.staticGroup();
    platforms.create(400, 584, 'platform').setScale(7, 1).refreshBody();
    platforms.create(220, 430, 'platform');
    platforms.create(560, 320, 'platform');

    this.createChipAnimations();
    this.player = this.physics.add.sprite(120, 520, 'chip', chipFramesMeta.animations.idle[0]);
    this.player.setScale(CHIP_SCALE);
    this.player.setCollideWorldBounds(true);

    this.physics.add.collider(this.player, platforms);

    this.cursors = this.input.keyboard.createCursorKeys();

    this.add.text(16, 16, 'The Room: arrows to move, up to jump', {
      color: '#ffffff',
      fontSize: '18px',
      fontFamily: 'Trebuchet MS',
    });

    this.player.play('chip-idle');
    updateTestState(this, this.player);
  }

  createChipAnimations() {
    const toFrames = (indices) => indices.map((frame) => ({ key: 'chip', frame }));

    if (!this.anims.exists('chip-idle')) {
      this.anims.create({
        key: 'chip-idle',
        frames: toFrames(chipFramesMeta.animations.idle),
        frameRate: 3,
        repeat: -1,
      });
    }

    if (!this.anims.exists('chip-run')) {
      this.anims.create({
        key: 'chip-run',
        frames: toFrames(chipFramesMeta.animations.run),
        frameRate: 10,
        repeat: -1,
      });
    }
  }

  selectJumpFrame() {
    const jumpFrames = chipFramesMeta.animations.jump;
    const velocityY = this.player.body.velocity.y;

    if (velocityY < -220) {
      return jumpFrames[0];
    }
    if (velocityY < -20) {
      return jumpFrames[1] ?? jumpFrames[0];
    }
    if (velocityY < 190) {
      return jumpFrames[2] ?? jumpFrames[jumpFrames.length - 1];
    }
    return jumpFrames[3] ?? jumpFrames[jumpFrames.length - 1];
  }

  update() {
    const left = this.cursors.left.isDown;
    const right = this.cursors.right.isDown;
    const jumpPressed = Phaser.Input.Keyboard.JustDown(this.cursors.up);
    const onGround = this.player.body.blocked.down || this.player.body.touching.down;

    this.player.setVelocityX(computeHorizontalVelocity(left, right));

    if (left) {
      this.player.setFlipX(true);
    } else if (right) {
      this.player.setFlipX(false);
    }

    if (shouldJump(jumpPressed, onGround)) {
      this.player.setVelocityY(JUMP_VELOCITY);
    }

    if (!onGround) {
      this.player.anims.stop();
      this.player.setFrame(this.selectJumpFrame());
    } else if (left || right) {
      if (this.player.anims.currentAnim?.key !== 'chip-run') {
        this.player.play('chip-run');
      }
    } else if (this.player.anims.currentAnim?.key !== 'chip-idle') {
      this.player.play('chip-idle');
    }

    updateTestState(this, this.player);
  }
}
