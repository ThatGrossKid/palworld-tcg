# Palworld Trading Card Game (TCG)

A card-based TCG built in [Godot 4.x](https://godotengine.org/) with server-authoritative multiplayer networking via ENet. Players battle using their collection of Palworld-inspired creatures, structures, gear, and events — all featuring the game's signature Power/Strike stats, Elements, and flavor text.

![Godot](https://img.shields.io/badge/Godot-4.x-blue?logo=godotengine&logoColor=white)
![ENet](https://img.shields.io/badge/Networking--ENet-green)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow)

---

## Table of Contents

- [Game Overview](#game-overview)
- [Card Types & Mechanics](#card-types--mechanics)
- [Turn Structure (Phases)](#turn-structure--phases)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Game Modes](#game-modes)
- [Networking & Multiplayer](#networking--multiplayer)
- [Adding Cards to the Game](#adding-cards-to-the-game)
- [Building for Deployment](#building-for-deployment)
- [Future Work](#future-work)
- [Contributing](#contributing)
- [License](#license)

---

## Game Overview

Palworld TCG is a turn-based card game where players build decks around Palworld creatures and use them to battle opponents. The game draws heavy inspiration from Yu-Gi-Oh! style mechanics including **Power/Strike stats**, **Elements** (Forest, Fire, Ice, etc.), **SubTypes** (Normal/Lucky), **Interrupts**, **Taunt**, **Stealth**, **Vigilance**, and more — all wrapped in the familiar Palworld aesthetic.

The game currently supports:
- **PvP matches** with a 1v1 multiplayer lobby system
- **Solo mode** placeholder (structure exists, logic pending)
- Server-authoritative networking via ENet for cheat-resistant gameplay

---

## Card Types & Mechanics

| Type | Description | Examples |
|------|-------------|----------|
| **Pal Card** | Core creatures — have Power/Strike stats, Elements, SubType | Mossanda, Grizzbolt, Blazamut |
| **Structure** | Base-building cards that provide ongoing effects when Pals are assigned to them | Berry Plantation, Campfire, Stone Pit |
| **Gear** | Equipment that modifies a Pal's capabilities (buffs/rest) | Refined Metal Spear, Cawgnito Hat |
| **Event** | One-time effects — often cost-based activations or graveyard recursion | Ignis Breath, Medical Supplies, Strike from the Darkness |
| **Soul** | Special cards with rest-to-draw mechanics (unique to Palworld lore) | ESOUL-001 |

### Key Card Attributes

- **Cost**: Resource required to play/activate the card (lower = easier to play early game)
- **Power**: Combat strength stat — higher Power deals more damage on attack
- **Strike**: Speed/stun counter — affects turn priority and battle resolution
- **Element**: Elemental affinity (Forest, Fire, Ice, etc.) — may interact with opponent's elements in future expansions
- **SubType**: `Normal Pal` or `Lucky Pal` — Lucky Pals typically have higher stats but are harder to obtain
- **WorkSuitability**: Pal-specific work tags (Harvesting, Crafting, Transporting) — lore flavor
- **Flavor Text**: Lore descriptions and character personalities from the Palworld universe

### Card Mechanics Glossary

| Mechanic | Description | Example |
|----------|-------------|---------|
| **Interrupt** | Can be activated during opponent's turn to nullify attacks | Dinossom, Foxparks |
| **Taunt** | Opponent must target this card when attacking | Eikthyrdeer Terra, Broncherry |
| **Stealth** | Cannot be blocked by opponents — acts as a sneaker/ambusher | Cawgnito |
| **Vigilance** | At end of turn, automatically stands back up (prevents being knocked out) | Suzaku Aqua |
| **Assault** | Can attack Pals in Stand state (normally only standing Pals can attack) | Grizzbolt |
| **Consume** | Requires discarding other cards from hand to activate this card's effect | Mossanda Lux, Campfire |

---

## Turn Structure (Phases)

The game follows a structured turn cycle enforced by the server:

```
  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
  │   Stand Phase│ →  │   Draw Phase │ → │   Soul Phase │ → │   Main Phase  │
  └──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
```

1. **Stand Phase**: Pals are set to Standing state. Opponents may attack in Assault mode.
2. **Draw Phase**: Draw cards from the deck (specific draw effects can be card-activated here).
3. **Soul Phase**: Activate Soul cards by resting 3 Souls once per turn to draw additional cards.
4. **Main Phase**: Primary phase for playing Pal/Structure/Gear/Event cards, attacking, and activating abilities.

---

## Project Structure

```
palworld-tcg/
├─ .git/                  # Git repository
├─ .godot/                # Godot workspace cache (editor state)
├─ autoloads/             # Global singletons loaded in every scene
│   ├─ game_state.gd      # Shared game state: scores, turn counter, phase tracking
│   └─ network.gd         # Core ENet networking singleton (lobbies, RPCs, signals)
├─ cards/                 # Card data & scenes
│   ├─ cards.json          # Full card database (48+ Palworld TCG cards across all types)
│   ├─ pal_card.tscn/.gd  # PalCard scene + stats (Power, Strike, Element, Cost)
│   ├─ soul_card.gd       # Soul card subclass — rest-to-draw mechanics
│   ├─ card_logic.gd      # Core Card base class (rest/unrest state management)
│   └─ event_card.tscn    # Event card scene template
├─ scenes/                # Game scenes & UI
│   ├─ main.tscn/.gd       # Entry point — launches server/client mode
│   ├─ main_menu.tscn/.gd  # Username entry, create/join lobby dialogs
│   ├─ lobby.tscn/.gd      # In-lobby player list, ready button, host controls
│   ├─ game.tscn/.gd       # Active battle scene (stub logic — needs full implementation)
│   └─ menus/              # Sub-menus for gameplay
│       ├─ play_menu.gd    # Solo/PvP mode selection
│       ├─ settings_menu.gd # Settings panel toggle
│       └─ pause_menu.tscn # Pause screen (scene exists, logic pending)
├─ ui/                    # Reusable UI components
│   ├─ create_lobby_dialog.tscn  # Dialog for creating new lobbies
│   ├─ join_lobby_dialog.tscn    # Dialog for joining existing lobbies
│   └─ player_card.tscn          # Player slot card in lobby (name, ready status)
├─ server/                # Dedicated headless server build
│   └─ server.tscn/.gd    # Server entry point — runs on VPS/Raspberry Pi etc.
├─ assets/                # Game art & icons
│   ├─ icon.svg           # Project icon for Godot launcher
│   ├─ palworld_start_image.png  # Title screen background
│   └─ playmat.png        # Battle mat texture (3840×2160 resolution)
├─ textures/              # Sprite sheets & card art
│   └─ cards/             # Individual card PNGs per CardNumber
├─ tools/                 # Editor utilities
│   ├─ EventBus.gd        # Central event bus — decouples game systems via signals
│   │                       (phase changes, card draws, hover events)
│   └─ GlobalCardData.gd  # Card database singleton with full card definitions
├─ export_presets.cfg     # Pre-configured export templates
└─ project.godot          # Godot project configuration file

```

---

## Prerequisites

- **Godot Engine 4.6+** (with export templates installed) — Forward+ renderer recommended for the playmat visuals
- A server running Ubuntu 22.04 (or similar Linux distro) with a public IP address  
- SSH client (`ssh`, `scp`) — built-in on macOS/Linux; use [PuTTY](https://www.putty.org/) or Windows Terminal on Windows

---

## Getting Started

### 1. Open in Godot

Launch Godot 4.x, click **Import**, and select the `project.godot` file. The project will load with all scenes, autoloads, and card data ready to go.

### 2. Configure Server IP

Edit `scenes/main.gd`:
```gdscript
const SERVER_IP = "YOUR_SERVER_IP_HERE"  # Change this to your server's public IP address
```

### 3. Run the Game

Launch Godot with the project file:
- **Client**: Opens the main menu automatically, connects to server on startup.
- **Server** (optional): Run from command line with `--server` flag to launch headless mode:
  ```bash
  godot4 path/to/palworld-tcg/project.godot --server
  ```

### 4. Play Solo / Local PvP Test

Before deploying, test locally by running two Godot instances on the same machine:
1. In one instance, temporarily set `scenes/main.gd` to launch `res://server/server.tscn` as main scene (or call `_launch_server()` directly).
2. In another instance, connect normally — it will reach localhost.

### 5. Deploy to Server

Follow the [Server Setup](#networking--multiplayer) section to set up a permanent VPS and run the dedicated server build.

---

## Game Modes

| Mode | Description | Status |
|------|-------------|--------|
| **PvP** | 1v1 multiplayer match via lobby system | ✅ Implemented (stub battle logic in `game.tscn`) |
| **Solo** | Single-player vs AI or tutorial mode | 🏗️ Structure exists, logic pending |

---

## Networking & Multiplayer

The game uses [ENet](https://enet.lip.fi/) for reliable UDP networking with a server-authoritative architecture:

### Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                     SERVER (Dedicated)               │
│                                                     │
│  ENetMultiplayerPeer (port 7777, max 64 clients)    │
│  Lobby registry (Dictionary of active lobbies)      │
│  RPC handlers (authoritative — all game logic runs here) │
└───────────────────────┬─────────────────────────────┘
                        │ ENet / UDP packets
          ┌─────────────┴──────────────┐
          │                            │
┌──────────▼────────┐      ┌──────────▼────────┐
│    CLIENT A       │      │    CLIENT B       │
│                   │      │                   │
│  Network singleton│      │  Network singleton│
│  Lobby UI         │      │  Lobby UI         │
│  game.tscn        │      │  game.tscn        │
└───────────────────┘      └───────────────────┘
```

### Core Features (Network Layer)

- **Lobby creation** — configurable player limits, 4-digit lobby code
- **Join by code** — no external matchmaking service needed
- **Ready system** — host can only start game once all non-host players are ready
- **Automatic host migration** — if host disconnects, leadership passes to next player
- **Kick & ban** — host can remove/ban participants; banned players cannot rejoin that lobby
- **Disconnection handling** — players are removed from lobbies on drop

### Network API (autoloads/network.gd)

Key signals and functions available across the project:

```gdscript
# Server management
Network.host_server()        # Start a local ENet server
Network.join_server(ip)      # Connect to remote server
Network.disconnect_from_server()

# Lobby operations
Network.request_create_lobby()
Network.request_join_lobby(code)
Network.request_leave_lobby()
Network.request_kick_player(id)
Network.request_ban_player(id)

# State tracking (client-side mirrors)
Network.lobby_created.connect(callback)
Network.player_joined.connect(peer_id, data)
Network.ready_state_changed.connect(peer_id, is_ready)
```

---

## Adding Cards to the Game

### Step 1: Add card definition to `tools/GlobalCardData.gd` or `cards/cards.json`

Add a new entry following the existing format. Example (a new Pal):

```json
{
    "CardNumber": "ETD03-001",
    "CardName": "YourNewPal - Flavor Title",
    "Rarities": ["TD"],
    "CardType": "Pal",
    "SubType": "Normal Pal",
    "Color": "Red",
    "Cost": 4,
    "Power": 600,
    "Strike": 1,
    "Element": [],
    "WorkSuitability": ["Harvesting", "Crafting"],
    "Text": null,
    "Flavor": "A newly discovered creature waiting to be explored."
}
```

### Step 2: Create card scene (extend `cards/card.tscn`)

- For a Pal Card: use `pal_card.tscn` as template and edit the sprite + stats display
- For other types: create new `.tscn/.gd` files in `cards/` extending the appropriate base class (`Card`, `PalCard`, `SoulCard`)

### Step 3: Add card texture to `textures/cards/`

Name your PNG file after `CardNumber.png` (e.g., `ETD03-001.png`). The game references textures at `res://textures/cards/%s.png`.

---

## Building for Deployment

### Export Presets

The project includes pre-configured export presets in `export_presets.cfg`:
- **Windows client** — standard Godot build with D3D12 renderer (Windows)
- **Linux server** — headless build optimized for VPS deployment (Ubuntu 22.04+)

### Server Deployment Options

#### Option A — I already have a server

If you have Ubuntu 22.04+ running, ensure UDP port `7777` is open:
```bash
sudo ufw allow 7777/udp
sudo ufw reload
```

#### Option B — Create a free Oracle Cloud server

Oracle Cloud's **Always Free** tier includes an AMD VM.Standard.E2.1.Micro (1 OCPU, 1 GB RAM) with no time limit and no credit card charges within the free tier. See [Godot Multiplayer Lobby System README](https://github.com/godotmultiplayerlobby/...) for full step-by-step deployment instructions.

---

## Future Work

The game is in early development — here's what still needs to be implemented:

- **[ ] Full battle logic** in `scenes/game.tscn` — attacking, damage calculation, graveyard management
- **[ ] Deck building system** — construct decks from your Palworld collection
- **[ ] Card art assets** — high-resolution card sprites for each card (currently using placeholder textures)
- **[ ] Game modes** — Solo vs AI, ranked matches, custom rulesets
- **[ ] Element interactions** — Forest/Fire/Ice/etc. type advantages between elements
- **[ ] More mechanics** — Exhaust, Discard pile management, deck search effects, graveyard recursion
- **[ ] UI polish** — Animations for card plays/attacks, damage numbers, life point tracking
- **[ ] Settings menu** — Full settings panel (audio, video, controls)

---

## Contributing

This is a personal project. Contributions are welcome if you want to help with:
- Card art design or asset creation
- Bug fixes in existing code
- New card entries or balance adjustments

Feel free to open an issue or fork and contribute!

---

## License

MIT — see [LICENSE](./LICENSE) for details.