# Astro Moments — Game Design Document (GDD)

## 0. Game Summary

Title: Astro Moments
Genre: Action Space Mining Microgame + Upgrade Loop
Engine: LÖVE (Love2D)
Theme: The player has a limited amount of time to mine as many asteroids as possible.
Core Loop: Play a timed mining round → Collect asteroids → Earn currency → Buy upgrades → Repeat.

## 1. Game Loop Overview

### 1.1 Macro Loop (Between Rounds)

- Player completes a timed round.
- Asteroids collected convert into currency.
- Player purchases upgrades.
- Player begins next round or unlocks the next sector.

### 1.2 Micro Loop (In-Round)

- Timer begins.
- Spaceship movement and asteroid spawning.
- Player collects asteroids by keeping them inside a collection field.
- Timer ends → Round summary → Upgrade menu.

## 2. Core Systems

### 2.1 Spaceship Movement

- Player moves using WASD or Arrow Keys.
- Speed and maneuverability upgradeable.

### 2.2 Asteroid Behavior

- Asteroids drift randomly through space.
- Each asteroid has:
  - Position
  - Speed
  - Value
  - Rarity
  - Collection meter (0–100)
- Asteroids spawn at intervals.

### 2.3 Collection Field System

- Player spaceship has a circular collection field.
- Asteroids inside field increase collection meter.
- Asteroids outside field decrease it.
- When meter reaches 100, asteroid is collected.

### 2.4 Timer System

- Default duration: 60 seconds.
- Countdown displayed during round.
- Round ends at 0.

### 2.5 Currency System

- Asteroids have set values.
- Total round currency = sum of asteroids collected.

### 2.6 Upgrades

Categories:

- Movement: speed, maneuverability
- Collection: field radius, collection speed, decay resistance
- Spawn: more asteroids, rarity chance
- Time: extra seconds, boost mode, time dilation ability

## 3. Space Sectors

Each sector introduces progressive difficulty through environmental obstacles and mechanics, creating a balanced learning curve that culminates in a boss encounter.

### Sector 01: Asteroid Belt

**Obstacle:** None
**Description:** This is the beginner level with no obstacles. Players learn the basic mechanics of movement, asteroid collection, and the collection field system without additional challenges.

### Sector 02: Solar Flare Zones

**Obstacle:** Solar Flare Warning Zones
**Description:** Occasional pulsing warning circles appear briefly before a harmless solar flare effect occurs. The flares don't damage or affect the player negatively—they may even slightly slow asteroids in the area momentarily (actually helpful). This teaches players to watch for visual cues and introduces the concept of environmental effects.

### Sector 03: Cosmic Dust Cloud

**Obstacle:** Reduced Visibility
**Description:** Cosmic dust reduces visibility in the playable area, making it harder to see distant asteroids and navigate. This challenge is purely visual and doesn't mechanically penalize the player, but requires more careful attention to surroundings.

### Sector 04: Debris Field

**Obstacle:** Space Debris (2-3 pieces)
**Description:** Non-moving space junk floats in the sector. If the player collides with debris, they bounce off and come to a stop. The collision also interrupts asteroid capture progress for one second before it restarts. Players must navigate around obstacles while pursuing asteroids.

### Sector 05: Radiation Belts

**Obstacle:** Radiation Bands
**Description:** Slow-moving colored radiation bands drift across the screen. Passing through them temporarily reduces capture speed by 25% for 2-3 seconds. This combines awareness of surroundings (like Sector 04) with a mild time penalty, but isn't instant like debris collision.

### Sector 06: Meteor Approach

**Obstacle:** Single Meteor
**Description:** A meteor periodically flies across the screen in a predictable path (edge to edge). If it collides with the player's ship, they bounce off and come to a stop, interrupting capture progress for one second. Skilled players can learn the pattern and time their movements.

### Sector 07: Meteor Shower

**Obstacle:** Multiple Meteors (2-3)
**Description:** An increased meteor presence with 2-3 meteors appearing with slightly varied timing. More frequent than Sector 06 but not chaotic. Players need to pay closer attention to their surroundings without feeling overwhelmed.

### Sector 08: Meteor Storm in Nebula

**Obstacle:** Meteor Shower + Reduced Visibility
**Description:** Combines the meteor shower from Sector 07 with the cosmic dust visibility reduction from Sector 03. This is the final skill check before the boss, requiring players to master both obstacle avoidance and navigation in poor visibility.

### Sector 09: Black Hole (Boss)

**Obstacle:** Black Hole with Gravitational Pull
**Description:** A slowly moving black hole with gravitational pull that affects both the player and asteroids. Asteroids are pulled toward the black hole and can be lost, but new asteroids continue spawning at normal (or slightly increased) rates. If the player touches the center of the black hole, the mining phase immediately ends and they're taken to the cashout screen, but all collected asteroids are lost (evacuated to escape). This creates risk/reward decisions: pursue asteroids near the black hole or play it safe? Should feel like a boss encounter but not be overly difficult—players should "win" most of the time unless careless.

### Sector 10: Tranquility Zone

**Obstacle:** None (Reward Level)
**Description:** The final sector has no obstacles and serves as a cooldown from Sector 09's climax. This is pure reward—a breath of fresh air.

## 4. Game Flow

### Start Screen

- Start Game
- Upgrades (after first round)
- Quit

### Round Flow

1. Round starts
2. Timer begins
3. Player catches fish
4. Round ends
5. Summary + upgrades

### Upgrade Screen

- Displays currency
- Buttons for upgrades
- Unlock next zone

## 5. User Interface

### During Round

- Timer
- Asteroids collected counter
- Collection field
- Asteroid sprites

### Round Summary

- Asteroids collected list
- Total currency
- Continue button

## 6. Technical Implementation

### Data Structures

Spaceship:

```lua
spaceship = { x, y, speed, radius, collectionSpeed, decaySpeed }
```

Asteroid:

```lua
asteroid = { x, y, speed, value, rarity, collectionMeter }
```

Round:

```lua
round = { timer, asteroidList, spawnTimer }
```

Upgrades:

```lua
upgrades = { speed, radius, collectionSpeed, decay, spawnRate, rareChance, timeBonus }
```

### Distance Check

```lua
distance = math.sqrt((sx - ax)^2 + (sy - ay)^2)
if distance < radius then collectionMeter = collectionMeter + collectionSpeed * dt
else collectionMeter = collectionMeter - decaySpeed * dt
```

## 7. Audio

- Ambient space atmosphere
- Soft mining beam sound
- Chime on collection

## 8. Art Style

- Cozy, pastel space tones
- Simple asteroid sprites
- Soft particle effects

## 9. Balancing

- Early: 3–5 asteroids per round
- Mid: 8–12 asteroids
- Late: rare asteroid focus

## 10. Future Expansions

- Power-ups
- Boss asteroids
- Space hazards
- Endless mode

## 11. Game Jam MVP Scope

### Required

- Spaceship movement
- Asteroid movement
- Collection system
- Timer
- Summary screen
- Upgrades

### Optional

- Multiple sectors
- Sound
- Animations
