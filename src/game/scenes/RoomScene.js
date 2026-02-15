import Phaser from 'phaser';
import {
  computeHorizontalVelocity,
  JUMP_VELOCITY,
  shouldJump,
} from '../logic/movement.js';

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

  create() {
    createSolidTexture(this, 'platform', 128, 32, 0x6f8fa5);
    createSolidTexture(this, 'player', 32, 48, 0xffdd55);

    this.physics.world.setBounds(0, 0, 800, 600);

    const platforms = this.physics.add.staticGroup();
    platforms.create(400, 584, 'platform').setScale(7, 1).refreshBody();
    platforms.create(220, 430, 'platform');
    platforms.create(560, 320, 'platform');

    this.player = this.physics.add.sprite(120, 520, 'player');
    this.player.setCollideWorldBounds(true);

    this.physics.add.collider(this.player, platforms);

    this.cursors = this.input.keyboard.createCursorKeys();

    this.add.text(16, 16, 'The Room: arrows to move, up to jump', {
      color: '#ffffff',
      fontSize: '18px',
      fontFamily: 'Trebuchet MS',
    });

    updateTestState(this, this.player);
  }

  update() {
    const left = this.cursors.left.isDown;
    const right = this.cursors.right.isDown;
    const jumpPressed = Phaser.Input.Keyboard.JustDown(this.cursors.up);
    const onGround = this.player.body.blocked.down || this.player.body.touching.down;

    this.player.setVelocityX(computeHorizontalVelocity(left, right));

    if (shouldJump(jumpPressed, onGround)) {
      this.player.setVelocityY(JUMP_VELOCITY);
    }

    updateTestState(this, this.player);
  }
}
