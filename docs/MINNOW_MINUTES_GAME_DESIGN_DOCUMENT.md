# Minnow Minutes — Game Design Document (GDD)

## 0. Game Summary

Title: Minnow Minutes
Genre: Action Fishing Microgame + Upgrade Loop
Engine: LÖVE (Love2D)
Theme: The player has a limited amount of time to catch as many fish as possible.
Core Loop: Play a timed fishing round → Catch fish → Earn currency → Buy upgrades → Repeat.

## 1. Game Loop Overview

### 1.1 Macro Loop (Between Rounds)

- Player completes a timed round.
- Fish caught convert into currency.
- Player purchases upgrades.
- Player begins next round or unlocks the next zone.

### 1.2 Micro Loop (In-Round)

- Timer begins.
- Boat movement and fish spawning.
- Player catches fish by keeping them inside a capture circle.
- Timer ends → Round summary → Upgrade menu.

## 2. Core Systems

### 2.1 Boat Movement

- Player moves using WASD or Arrow Keys.
- Speed and turn rate upgradeable.

### 2.2 Fish AI

- Fish wander randomly.
- Each fish has:
  - Position
  - Speed
  - Value
  - Rarity
  - Capture meter (0–100)
- Fish spawn at intervals.

### 2.3 Capture Circle System

- Player boat has a circular capture radius.
- Fish inside radius increase capture meter.
- Fish outside radius decrease it.
- When meter reaches 100, fish is caught.

### 2.4 Timer System

- Default duration: 60 seconds.
- Countdown displayed during round.
- Round ends at 0.

### 2.5 Currency System

- Fish have set values.
- Total round currency = sum of fish caught.

### 2.6 Upgrades

Categories:

- Movement: speed, turning
- Capture: radius, speed, decay resistance
- Spawn: more fish, rarity chance
- Time: extra seconds, burst mode, freeze ability

## 3. Fishing Zones

### Zone 1: Shallow Bay

- Slow, common fish.

### Zone 2: Coral Pass

- Faster fish, more variety.

### Zone 3: Deepwater Rift

- Rare high-value fish.

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
- Fish caught counter
- Capture circle
- Fish sprites

### Round Summary

- Fish caught list
- Total currency
- Continue button

## 6. Technical Implementation

### Data Structures

Player:

```lua
player = { x, y, speed, radius, captureSpeed, decaySpeed }
```

Fish:

```lua
fish = { x, y, speed, value, rarity, captureMeter }
```

Round:

```lua
round = { timer, fishList, spawnTimer }
```

Upgrades:

```lua
upgrades = { speed, radius, captureSpeed, decay, spawnRate, rareChance, timeBonus }
```

### Distance Check

```lua
distance = math.sqrt((px - fx)^2 + (py - fy)^2)
if distance < radius then captureMeter = captureMeter + captureSpeed * dt
else captureMeter = captureMeter - decaySpeed * dt
```

## 7. Audio

- Gentle ocean ambience
- Soft splash sound
- Chime on catch

## 8. Art Style

- Cozy, pastel ocean tones
- Simple fish sprites
- Soft ripple effects

## 9. Balancing

- Early: 3–5 fish per round
- Mid: 8–12 fish
- Late: rare fish focus

## 10. Future Expansions

- Power-ups
- Boss fish
- Weather effects
- Endless mode

## 11. Game Jam MVP Scope

### Required

- Boat movement
- Fish movement
- Capture system
- Timer
- Summary screen
- Upgrades

### Optional

- Multiple zones
- Sound
- Animations
