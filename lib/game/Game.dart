import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class FightingGame extends FlameGame with TapDetector {
  late PlayerComponent player;
  late MobComponent mob;
  late TextComponent playerHPText;
  late TextComponent mobHPText;
  late TextComponent messageText;
  double lastMobAttackTime = 0;
  double lastPlayerHitTime = 0;
  bool canAct = true;

  @override
  Future<void> onLoad() async {
    // Load sprite sheets
    final playerSpriteSheet = await images.load('sprites/idle.png');
    final mobSpriteSheet = await images.load('sprites/dog.png');

    // Player
    player = PlayerComponent()
      ..position = Vector2(50, size.y / 2 - 50)
      ..animation = SpriteAnimation.fromFrameData(
        playerSpriteSheet,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.2,
          textureSize: Vector2(80, 80),
        ),
      );
    add(player);

    // Mob
    mob = MobComponent()
      ..position = Vector2(size.x - 100, size.y / 2 - 50)
      ..animation = SpriteAnimation.fromFrameData(
        mobSpriteSheet,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.2,
          textureSize: Vector2(80, 80),
        ),
      );
    add(mob);

    // HP Text
    playerHPText = TextComponent(
      text: 'HP: ${player.hp}',
      position: Vector2(50, size.y / 2 - 70),
    );
    mobHPText = TextComponent(
      text: 'HP: ${mob.hp}',
      position: Vector2(size.x - 100, size.y / 2 - 70),
    );
    messageText = TextComponent(
      text: 'Fight!',
      position: Vector2(size.x / 2 - 50, size.y - 100),
      anchor: Anchor.center,
    );
    add(playerHPText);
    add(mobHPText);
    add(messageText);

    // Buttons (Flutter overlay)
    overlays.add('buttons');
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Mob attacks every 1 second
    lastMobAttackTime += dt;
    if (lastMobAttackTime >= 1.0 && mob.hp > 0 && player.hp > 0) {
      _mobAttack();
      lastMobAttackTime = 0;
    }

    // Re-enable player actions after 0.5 seconds
    if (!canAct) {
      lastPlayerHitTime += dt;
      if (lastPlayerHitTime >= 0.5) {
        canAct = true;
        lastPlayerHitTime = 0;
      }
    }

    // Update HP text
    playerHPText.text = 'HP: ${player.hp}';
    mobHPText.text = 'HP: ${mob.hp}';
  }

  void _mobAttack() {
    int damage = Random().nextInt(15) + 5;
    int effectiveDamage = (damage - player.defense).clamp(0, damage);
    player.hp -= effectiveDamage;
    player.setAnimationState('hit');
    FlameAudio.play('hit.mp3');
    messageText.text = "Mob dealt $effectiveDamage damage!";
    canAct = false;
    if (player.hp <= 0) _endGame("Mob wins!");
  }

  void _endGame(String result) {
    pauseEngine();
    overlays.add('gameOver');
  }
}

class PlayerComponent extends SpriteAnimationComponent {
  int hp = 100;
  int defense = 0;

  PlayerComponent() : super(size: Vector2(50, 50));

  void setAnimationState(String state) {
    int currentIndex = 0;
    switch (state) {
      case 'attack':
        animation?.frames[1];
        Future.delayed(
            const Duration(milliseconds: 200), () => animation?.frames[0]);
        break;
      case 'hit':
        animation?.frames[2];
        Future.delayed(
            const Duration(milliseconds: 200), () => animation?.frames[0]);
        break;
      case 'defend':
        animation?.frames[3];
        Future.delayed(
            const Duration(milliseconds: 200), () => animation?.frames[0]);
        break;
    }
  }
}

class MobComponent extends SpriteAnimationComponent {
  int hp = 100;

  MobComponent() : super(size: Vector2(50, 50));
}

class FightingGameScreen extends StatelessWidget {
  const FightingGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = FightingGame();
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(
            game: game,
            overlayBuilderMap: {
              'buttons': (context, FightingGame game) => Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSquareButton('Attack', () {
                          if (!game.canAct ||
                              game.player.hp <= 0 ||
                              game.mob.hp <= 0) return;
                          int damage = Random().nextInt(20) + 10;
                          game.mob.hp -= damage;
                          game.player.setAnimationState('attack');
                          FlameAudio.play('attack.mp3');
                          game.messageText.text = "You dealt $damage damage!";
                          if (game.mob.hp <= 0) game._endGame("You win!");
                        }, !game.canAct),
                        _buildSquareButton('Defend', () {
                          if (!game.canAct ||
                              game.player.hp <= 0 ||
                              game.mob.hp <= 0) return;
                          game.player.defense = 15;
                          game.player.setAnimationState('defend');
                          game.messageText.text = "You brace for attack!";
                        }, !game.canAct),
                        _buildSquareButton('Ability', () {
                          if (!game.canAct ||
                              game.player.hp <= 0 ||
                              game.mob.hp <= 0) return;
                          int damage = Random().nextInt(30) + 20;
                          game.mob.hp -= damage;
                          game.player.setAnimationState('attack');
                          FlameAudio.play('attack.mp3');
                          game.messageText.text =
                              "Ability dealt $damage damage!";
                          if (game.mob.hp <= 0) game._endGame("You win!");
                        }, !game.canAct),
                      ],
                    ),
                  ),
              'gameOver': (context, FightingGame game) => Center(
                    child: AlertDialog(
                      title: const Text('Game Over'),
                      content: Text(game.player.hp <= 0
                          ? 'Mob wins!'
                          : 'You win!\nYour HP: ${game.player.hp}\nMob HP: ${game.mob.hp}'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSquareButton(
      String text, VoidCallback onPressed, bool disabled) {
    return SizedBox(
      width: 80,
      height: 80,
      child: TextButton(
        onPressed: disabled ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: disabled ? Colors.grey : Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          padding: EdgeInsets.zero,
          minimumSize: const Size(80, 80),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
      ),
    );
  }
}
