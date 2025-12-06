# Minnow Minutes - Epics and User Stories

## Epic 1: Core Micro Loop (In-Round Gameplay) - PRIORITY 1

### User Story 1.1: Basic Boat Movement

**As a** player
**I want to** move my boat using keyboard controls
**So that** I can navigate the play area to catch fish

**Acceptance Criteria:**

- Player boat can move in all directions using WASD or Arrow Keys
- Boat has basic position tracking (x, y)
- Boat stays within screen boundaries
- Movement is smooth and responsive

**Technical Tasks:**

- [ ] Create player data structure with x, y, speed properties
- [ ] Implement keyboard input handling (WASD + Arrow Keys)
- [ ] Implement movement calculation based on delta time
- [ ] Add boundary collision detection

---

### User Story 1.2: Fish Spawning and Movement

**As a** player
**I want to** see fish appear and move around the play area
**So that** I have targets to catch

**Acceptance Criteria:**

- Fish spawn at regular intervals
- Fish wander randomly within the play area
- Each fish has position, speed, value, and rarity
- Fish stay within screen boundaries

**Technical Tasks:**

- [ ] Create fish data structure (x, y, speed, value, rarity, captureMeter)
- [ ] Implement fish spawn timer system
- [ ] Implement random fish movement AI
- [ ] Add fish boundary collision detection
- [ ] Create fishList to track all active fish

---

### User Story 1.3: Capture Circle System

**As a** player
**I want to** see a circular capture radius around my boat
**So that** I know which fish are being caught

**Acceptance Criteria:**

- Circular capture radius is visible around the boat
- Radius is a configurable property
- System detects which fish are inside the radius
- Visual feedback shows the capture circle

**Technical Tasks:**

- [ ] Add radius property to player data structure
- [ ] Implement distance calculation function (sqrt formula)
- [ ] Draw capture circle around boat
- [ ] Implement collision detection between circle and fish

---

### User Story 1.4: Fish Capture Meter

**As a** player
**I want to** see a capture meter fill up when fish are in my radius
**So that** I know how close I am to catching each fish

**Acceptance Criteria:**

- Each fish has a capture meter (0-100)
- Meter increases when fish is inside capture radius
- Meter decreases when fish is outside radius
- Fish is caught when meter reaches 100
- Caught fish are removed from play area

**Technical Tasks:**

- [ ] Add captureMeter property to fish structure
- [ ] Implement capture speed calculation (increases meter)
- [ ] Implement decay speed calculation (decreases meter)
- [ ] Add meter clamping (0-100 range)
- [ ] Display capture meter visually above each fish
- [ ] Remove fish from fishList when captured

---

### User Story 1.5: Round Timer

**As a** player
**I want to** see a countdown timer during gameplay
**So that** I know how much time I have left to catch fish

**Acceptance Criteria:**

- Timer starts at 60 seconds (default)
- Timer counts down during gameplay
- Timer is displayed on screen
- Round ends when timer reaches 0

**Technical Tasks:**

- [ ] Create round data structure with timer property
- [ ] Implement countdown logic using delta time
- [ ] Display timer on screen (HH:MM or MM:SS format)
- [ ] Trigger round end when timer hits 0

---

### User Story 1.6: Fish Caught Counter

**As a** player
**I want to** see how many fish I've caught during the round
**So that** I can track my progress

**Acceptance Criteria:**

- Counter starts at 0 at round start
- Counter increments when a fish is caught
- Counter is displayed on screen during round
- Counter persists until round summary

**Technical Tasks:**

- [ ] Add fishCaught counter to round structure
- [ ] Increment counter when fish captureMeter reaches 100
- [ ] Display counter on screen

---

## Epic 2: Game State Management - PRIORITY 2

### User Story 2.1: Game States

**As a** developer
**I want to** manage different game states
**So that** the game flows correctly between screens

**Acceptance Criteria:**

- Game has distinct states: menu, playing, summary, upgrades
- State transitions are clean and predictable
- Each state has its own update and draw logic

**Technical Tasks:**

- [ ] Create gameState variable (menu, playing, summary, upgrades)
- [ ] Implement state-specific update functions
- [ ] Implement state-specific draw functions
- [ ] Add state transition logic

---

### User Story 2.2: Start Screen

**As a** player
**I want to** see a start screen with options
**So that** I can begin playing or view upgrades

**Acceptance Criteria:**

- Start screen displays game title
- "Start Game" button begins a round
- "Upgrades" button appears after first round
- "Quit" button exits the game

**Technical Tasks:**

- [ ] Create menu state layout
- [ ] Implement button interaction (mouse or keyboard)
- [ ] Add "Start Game" functionality
- [ ] Add "Upgrades" button (conditional display)
- [ ] Add "Quit" functionality

---

### User Story 2.3: Round Initialization

**As a** player
**I want to** start each round with a clean slate
**So that** each round is fair and consistent

**Acceptance Criteria:**

- Timer resets to default duration
- Fish list is cleared
- Player position resets to center
- Fish caught counter resets to 0

**Technical Tasks:**

- [ ] Create round initialization function
- [ ] Reset timer to default value
- [ ] Clear fishList array
- [ ] Reset player position
- [ ] Reset fishCaught counter
- [ ] Transition to playing state

---

### User Story 2.4: Round Summary Screen

**As a** player
**I want to** see a summary of my performance after each round
**So that** I know what I accomplished

**Acceptance Criteria:**

- Summary displays total fish caught
- Summary displays total currency earned
- List of fish caught with values shown
- "Continue" button returns to upgrade/menu screen

**Technical Tasks:**

- [ ] Create summary state layout
- [ ] Display fishCaught total
- [ ] Calculate and display total currency
- [ ] List all caught fish with values
- [ ] Add "Continue" button to proceed
- [ ] Transition to upgrades state

---

## Epic 3: Currency and Upgrade System - PRIORITY 3

### User Story 3.1: Currency System

**As a** player
**I want to** earn currency by catching fish
**So that** I can purchase upgrades

**Acceptance Criteria:**

- Each fish has a value property
- Currency is calculated at round end
- Total currency = sum of all caught fish values
- Currency persists between rounds

**Technical Tasks:**

- [ ] Add value property to fish structure
- [ ] Assign values based on fish rarity
- [ ] Create global currency variable
- [ ] Calculate round earnings at round end
- [ ] Add earnings to total currency
- [ ] Display currency on summary and upgrade screens

---

### User Story 3.2: Upgrades Screen

**As a** player
**I want to** spend currency on upgrades
**So that** I can improve my boat and catching ability

**Acceptance Criteria:**

- Upgrades screen displays current currency
- Available upgrades are shown with costs
- Player can purchase affordable upgrades
- Currency is deducted on purchase
- Upgrades are applied to player stats

**Technical Tasks:**

- [ ] Create upgrades state layout
- [ ] Display current currency
- [ ] Create upgrades data structure with costs
- [ ] Display upgrade buttons with costs
- [ ] Check if player can afford upgrade
- [ ] Deduct cost and apply upgrade on purchase
- [ ] Add "Start Next Round" button

---

### User Story 3.3: Movement Upgrades

**As a** player
**I want to** upgrade my boat's speed and turning
**So that** I can catch fish more efficiently

**Acceptance Criteria:**

- Speed upgrade increases boat movement speed
- Each upgrade has increasing cost
- Upgrades have multiple tiers
- Upgraded stats persist between rounds

**Technical Tasks:**

- [ ] Create speed upgrade entry in upgrades structure
- [ ] Implement speed multiplier on boat movement
- [ ] Add upgrade tier tracking
- [ ] Calculate upgrade costs (scaling)
- [ ] Apply speed upgrade to player

---

### User Story 3.4: Capture Upgrades

**As a** player
**I want to** upgrade my capture radius and speed
**So that** I can catch fish faster and from farther away

**Acceptance Criteria:**

- Radius upgrade increases capture circle size
- Capture speed upgrade fills meter faster
- Decay resistance reduces meter loss rate
- Each upgrade type has multiple tiers

**Technical Tasks:**

- [ ] Create radius upgrade entry
- [ ] Create captureSpeed upgrade entry
- [ ] Create decaySpeed (resistance) upgrade entry
- [ ] Apply radius changes to player
- [ ] Apply capture speed changes to fish capture logic
- [ ] Apply decay speed changes to fish capture logic

---

### User Story 3.5: Spawn Rate Upgrades

**As a** player
**I want to** upgrade fish spawn rate and rarity
**So that** I have more opportunities to catch valuable fish

**Acceptance Criteria:**

- Spawn rate upgrade reduces spawn interval
- Rarity chance upgrade increases rare fish probability
- More fish appear in later rounds with upgrades

**Technical Tasks:**

- [ ] Create spawnRate upgrade entry
- [ ] Create rareChance upgrade entry
- [ ] Apply spawn rate to fish spawn timer
- [ ] Implement rarity roll system for fish spawning
- [ ] Adjust spawn logic based on upgrades

---

### User Story 3.6: Time Upgrades

**As a** player
**I want to** upgrade my round duration
**So that** I have more time to catch fish

**Acceptance Criteria:**

- Time bonus upgrade adds seconds to round timer
- Upgrade is applied at round start
- Multiple tiers available

**Technical Tasks:**

- [ ] Create timeBonus upgrade entry
- [ ] Apply time bonus to round timer at initialization
- [ ] Calculate increased timer duration

---

## Epic 4: Polish and Balance - PRIORITY 4

### User Story 4.1: Game Balance

**As a** player
**I want to** experience a balanced progression
**So that** the game feels fair and rewarding

**Acceptance Criteria:**

- Early rounds: 3-5 fish spawned
- Mid rounds: 8-12 fish spawned
- Upgrade costs scale appropriately
- Fish values are balanced

**Technical Tasks:**

- [ ] Test and adjust fish spawn rates
- [ ] Test and adjust fish values
- [ ] Test and adjust upgrade costs
- [ ] Test and adjust capture speed/decay rates
- [ ] Implement difficulty scaling (optional)

---

### User Story 4.2: User Interface Polish

**As a** player
**I want to** see clear, readable UI elements
**So that** I can easily understand game information

**Acceptance Criteria:**

- Text is legible and properly positioned
- UI elements don't overlap
- Important information is prominent
- Colors provide good contrast

**Technical Tasks:**

- [ ] Review and adjust font sizes
- [ ] Position UI elements consistently
- [ ] Add padding/margins to text
- [ ] Choose readable color palette
- [ ] Test UI on different screen sizes

---

## Epic 5: Visual and Audio Assets - PRIORITY 5 (FINAL)

### User Story 5.1: Basic Visual Assets

**As a** player
**I want to** see simple, appealing visuals
**So that** the game is pleasant to look at

**Acceptance Criteria:**

- Boat has a simple sprite or shape
- Fish have distinct sprites based on rarity
- Background has ocean theme
- Capture circle is visible and styled

**Technical Tasks:**

- [ ] Create or source boat sprite
- [ ] Create or source fish sprites (common, uncommon, rare)
- [ ] Create ocean background
- [ ] Style capture circle
- [ ] Add ripple effects (optional)

---

### User Story 5.2: Audio Implementation

**As a** player
**I want to** hear appropriate sound effects
**So that** the game has better feedback and atmosphere

**Acceptance Criteria:**

- Gentle ocean ambience plays during rounds
- Splash sound plays when fish is caught
- Chime sound plays when round ends
- Audio volume is reasonable

**Technical Tasks:**

- [ ] Source or create ocean ambience loop
- [ ] Source or create splash sound effect
- [ ] Source or create chime sound effect
- [ ] Implement audio playback system
- [ ] Add audio triggers to game events
- [ ] Balance audio levels

---

## Development Priority Order

1. **Epic 1: Core Micro Loop** - Get the game playable
2. **Epic 2: Game State Management** - Add structure and flow
3. **Epic 3: Currency and Upgrade System** - Complete the core loop
4. **Epic 4: Polish and Balance** - Make it feel good
5. **Epic 5: Visual and Audio Assets** - Make it look and sound good

## Notes

- Each user story should be completed and tested before moving to the next
- Epic 1 is critical - focus on getting a playable prototype quickly
- Placeholder graphics (circles, rectangles) are fine until Epic 5
- Placeholder sounds can be silence or simple beeps until Epic 5
- Test frequently as you build each component
