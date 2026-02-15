import Phaser from 'phaser';
import { RoomScene } from './scenes/RoomScene.js';

export function createGameConfig() {
  return {
    type: Phaser.AUTO,
    parent: 'game-container',
    width: 800,
    height: 600,
    pixelArt: true,
    backgroundColor: '#182535',
    physics: {
      default: 'arcade',
      arcade: {
        gravity: { y: 900 },
        debug: false,
      },
    },
    scene: [RoomScene],
  };
}
