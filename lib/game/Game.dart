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
  int currentAttackIndex =
      0; // Track which attack in the cycle (0: Attack1, 1: Attack2, 2: Attack3)

  @override
  Future<void> onLoad() async {
    final playerIdleSheet = await images.load('sprites/idle.png');
    final attack1Sheet = await images.load('sprites/attack1.png');
    final attack2Sheet = await images.load('sprites/attack2.png');
    final attack3Sheet = await images.load('sprites/attack3.png');
    final mobSpriteSheet = await images.load('sprites/dog.png');

    player = PlayerComponent(
      idleAnimation: SpriteAnimation.fromFrameData(
        playerIdleSheet,
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: 0.2,
          textureSize: Vector2(64, 64),
        ),
      ),
      attack1Animation: SpriteAnimation.fromFrameData(
        attack1Sheet,
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: 0.1,
          textureSize: Vector2(64, 64),
        ),
      ),
      attack2Animation: SpriteAnimation.fromFrameData(
        attack2Sheet,
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: 0.1,
          textureSize: Vector2(64, 64),
        ),
      ),
      attack3Animation: SpriteAnimation.fromFrameData(
        attack3Sheet,
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: 0.1,
          textureSize: Vector2(64, 64),
        ),
      ),
    )
      ..position = Vector2(50, size.y / 2 - 50)
      ..scale = Vector2(2.0, 2.0);
    add(player);

    mob = MobComponent()
      ..position = Vector2(size.x - 100, size.y / 2 - 50)
      ..animation = SpriteAnimation.fromFrameData(
        mobSpriteSheet,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.2,
          textureSize: Vector2(80, 80),
        ),
      )
      ..scale = Vector2(2.0, 2.0);
    add(mob);

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

    overlays.add('buttons');
  }

  @override
  void update(double dt) {
    super.update(dt);

    lastMobAttackTime += dt;
    if (lastMobAttackTime >= 1.0 && mob.hp > 0 && player.hp > 0) {
      _mobAttack();
      lastMobAttackTime = 0;
    }

    if (!canAct) {
      lastPlayerHitTime += dt;
      if (lastPlayerHitTime >= 0.5) {
        canAct = true;
        lastPlayerHitTime = 0;
      }
    }

    playerHPText.text = 'HP: ${player.hp}';
    mobHPText.text = 'HP: ${mob.hp}';
  }

  void _mobAttack() {
    int damage = Random().nextInt(15) + 5;
    int effectiveDamage = (damage - player.defense).clamp(0, damage);
    player.hp -= effectiveDamage;
    FlameAudio.play('hit.mp3');
    messageText.text = "Mob dealt $effectiveDamage damage!";
    canAct = false;
    if (player.hp <= 0) _endGame("Mob wins!");
  }

  void _endGame(String result) {
    pauseEngine();
    overlays.add('gameOver');
  }

  Future<void> performAttack() async {
    if (!canAct || player.hp <= 0 || mob.hp <= 0) return;
    canAct = false;

    int damage;
    String attackName;
    switch (currentAttackIndex) {
      case 0:
        damage = Random().nextInt(20) + 10;
        attackName = "Attack1";
        await player.playAttack1(damage, (dmg) {
          mob.hp -= dmg;
          FlameAudio.play('attack.mp3');
          messageText.text = "$attackName dealt $dmg damage!";
          if (mob.hp <= 0) _endGame("You win!");
        });
        currentAttackIndex = 1;
        break;
      case 1:
        damage = Random().nextInt(25) + 15;
        attackName = "Attack2";
        await player.playAttack2(damage, (dmg) {
          mob.hp -= dmg;
          FlameAudio.play('attack.mp3');
          messageText.text = "$attackName dealt $dmg damage!";
          if (mob.hp <= 0) _endGame("You win!");
        });
        currentAttackIndex = 2;
        break;
      case 2:
        damage = Random().nextInt(30) + 20;
        attackName = "Attack3";
        await player.playAttack3(damage, (dmg) {
          mob.hp -= dmg;
          FlameAudio.play('attack.mp3');
          messageText.text = "$attackName dealt $dmg damage!";
          if (mob.hp <= 0) _endGame("You win!");
        });
        currentAttackIndex = 0; // Reset to Attack1 after Attack3 completes
        break;
    }
  }
}

class PlayerComponent extends SpriteAnimationComponent {
  int hp = 100;
  int defense = 0;

  final SpriteAnimation idleAnimation;
  final SpriteAnimation attack1Animation;
  final SpriteAnimation attack2Animation;
  final SpriteAnimation attack3Animation;

  PlayerComponent({
    required this.idleAnimation,
    required this.attack1Animation,
    required this.attack2Animation,
    required this.attack3Animation,
  }) : super(size: Vector2(50, 50), animation: idleAnimation);

  Future<void> playAttack1(int damage, Function(int) onDamage) async {
    final ticker = attack1Animation.createTicker();
    animation = attack1Animation;

    // Attack1 lands after 0.3 seconds (300ms)
    await Future.delayed(Duration(milliseconds: 200));
    onDamage(damage);

    // Complete the remaining animation (total 600ms - 300ms = 300ms)
    await Future.delayed(Duration(milliseconds: 200));

    animation = idleAnimation;
  }

  Future<void> playAttack2(int damage, Function(int) onDamage) async {
    final ticker = attack2Animation.createTicker();
    animation = attack2Animation;

    // Attack2 lands after 0.3 seconds (300ms)
    await Future.delayed(Duration(milliseconds: 200));
    onDamage(damage);

    // Complete the remaining animation
    await Future.delayed(Duration(milliseconds: 200));

    animation = idleAnimation;
  }

  Future<void> playAttack3(int damage, Function(int) onDamage) async {
    final ticker = attack3Animation.createTicker();
    animation = attack3Animation;

    // Attack3 lands after 0.5 seconds (500ms)
    await Future.delayed(Duration(milliseconds: 500));
    onDamage(damage);

    // Complete the remaining animation (total 600ms - 500ms = 100ms)
    await Future.delayed(Duration(milliseconds: 300));

    animation = idleAnimation;
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
                        _buildSquareButton('Attack', () async {
                          await game.performAttack();
                        }, !game.canAct),
                        _buildSquareButton('Defend', () {
                          if (!game.canAct ||
                              game.player.hp <= 0 ||
                              game.mob.hp <= 0) return;
                          game.canAct = false;
                          game.player.defense = 15;
                          game.messageText.text = "You brace for attack!";
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
