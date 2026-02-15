import Phaser from 'phaser';
import { createGameConfig } from './game/config.js';
import './style.css';

if (typeof window !== 'undefined') {
  window.__chipChap = {
    ready: false,
    scene: null,
    player: { x: 0, y: 0 },
  };
}

const game = new Phaser.Game(createGameConfig());

if (typeof window !== 'undefined') {
  window.__chipChap.game = game;
}
