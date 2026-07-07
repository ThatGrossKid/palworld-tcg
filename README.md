# Godot Multiplayer Lobby System

A ready-to-use, server-authoritative multiplayer lobby system for Godot 4.6, built on ENet. Drop it into any project and get lobby creation, lobby joining by code, player ready states, host transfer, kick/ban, and automatic host migration — all wired up and working.

![Godot 4.6](https://img.shields.io/badge/Godot-4.6-blue?logo=godotengine&logoColor=white)
![ENet](https://img.shields.io/badge/Networking-ENet-green)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow)

---

## Table of Contents

- [Features](#features)
- [Architecture Overview](#architecture-overview)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Server Setup](#server-setup)
  - [Option A — I already have a server](#option-a--i-already-have-a-server)
  - [Option B — Create a free Oracle Cloud server](#option-b--create-a-free-oracle-cloud-server)
- [Building and Deploying](#building-and-deploying)
  - [Exporting the project](#exporting-the-project)
  - [Uploading the server build](#uploading-the-server-build)
  - [Running as a systemd service](#running-as-a-systemd-service)
- [Configuration](#configuration)
- [Integrating Into Your Game](#integrating-into-your-game)
- [Network API Reference](#network-api-reference)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **Lobby creation** with configurable player limits
- **Join by 4-digit code** — no matchmaking service needed
- **Ready system** — host can only start once all non-host players are ready
- **Automatic host migration** — if the host disconnects, leadership passes to the next player
- **Kick & ban** — host can remove players; banned players cannot rejoin the same lobby
- **Disconnection handling** — players are removed from lobbies on drop
- **Dedicated server export** — a separate headless Linux build that runs on any VPS

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                     SERVER                          │
│                                                     │
│  server.tscn  →  Network (autoload)                 │
│                  ├─ ENetMultiplayerPeer (port 7777) │
│                  ├─ Lobby registry (Dictionary)     │
│                  └─ RPC handlers (authoritative)    │
└────────────────────────┬────────────────────────────┘
                         │ ENet / UDP
          ┌──────────────┴──────────────┐
          │                             │
┌─────────▼───────┐           ┌─────────▼───────┐
│    CLIENT A     │           │    CLIENT B     │
│                 │           │                 │
│  Network        │           │  Network        │
│  GameState      │           │  GameState      │
│  Scenes:        │           │  Scenes:        │
│  main_menu →    │           │  main_menu →    │
│  lobby →        │           │  lobby →        │
│  game           │           │  game           │
└─────────────────┘           └─────────────────┘
```

All game logic runs through the server. Clients send RPCs to the server; the server validates them and broadcasts updates back. Clients never trust each other directly.

---

## Project Structure

```
godot-multiplayer-lobby-system/
├── autoloads/
│   ├── network.gd          # Core networking singleton (ENet, lobby RPCs, signals)
│   └── game_state.gd       # Game state singleton (scores, phase, start/end RPCs)
├── scenes/
│   ├── main.tscn/.gd       # Entry point — connects to the server on launch
│   ├── main_menu.tscn/.gd  # Username entry, create/join lobby dialogs
│   ├── lobby.tscn/.gd      # In-lobby UI — player cards, ready/start, kick/ban
│   ├── game.tscn/.gd       # Your game scene (stub — replace with your logic)
│   └── ui/
│       ├── create_lobby_dialog.tscn/.gd
│       ├── join_lobby_dialog.tscn/.gd
│       └── player_card.tscn/.gd
├── server/
│   └── server.tscn/.gd     # Dedicated server entry point
├── builds/
│   ├── release/            # Windows client build output
│   └── server/             # Linux server build output
├── export_presets.cfg      # Pre-configured Windows + Server export templates
└── project.godot
```

---

## Prerequisites

- [Godot Engine 4.6](https://godotengine.org/download) (with export templates installed)
- A server running Ubuntu 22.04 with a public IP address (see [Server Setup](#server-setup))
- SSH client (`ssh`, `scp`) — built-in on macOS/Linux; use [PuTTY](https://www.putty.org/) or Windows Terminal on Windows

---

## Getting Started

1. **Open in Godot**

   Launch Godot 4.6, click **Import**, and select the `project.godot` file.

2. **Setup a Server**

	See [Server Setup](#server-setup) to configure your existing server or create a new one.

3. **Set your server IP**

   Open `scenes/main.gd` and replace the placeholder IP with your server's public IP address:

   ```gdscript
   const SERVER_IP = "YOUR_SERVER_IP_HERE"
   ```

4. **Run a local test** (optional)

   Before deploying, you can test locally by running two Godot instances. In one instance, call `Network.host_server()` directly (or launch `server.tscn` as the main scene in Project Settings temporarily). In the other, connect to `127.0.0.1`.

---

## Server Setup

### Option A — I already have a server

If you have a server running Ubuntu 22.04 (or similar) with a public IP, skip ahead to [Building and Deploying](#building-and-deploying).

The only requirement is that **UDP port 7777** is open in your firewall. On Ubuntu with `ufw`:

```bash
sudo ufw allow 7777/udp
sudo ufw reload
```

---

### Option B — Create a free Oracle Cloud server

Oracle Cloud's **Always Free** tier includes a VM that is genuinely free with no time limit — no credit card charges as long as you stay within the free tier. Follow these steps carefully.

#### 1. Create an Oracle Cloud account

1. Go to [cloud.oracle.com](https://cloud.oracle.com) and click **Start for free**.
2. Fill in your name, email address, and home region. **Choose your home region carefully — it cannot be changed later.** Pick the region closest to your players (e.g. `us-ashburn-1` for North America, `eu-frankfurt-1` for Europe).
3. Enter your phone number for verification.
4. Enter payment card details. Oracle requires this for identity verification but **will not charge you** as long as you only use Always Free resources.
5. Complete the account setup and sign in to the Oracle Cloud Console.

#### 2. Create a Virtual Machine instance

1. From the Oracle Cloud Console home page, click the **≡ (hamburger menu)** in the top-left corner.
2. Navigate to **Compute → Instances**.
3. Click **Create instance**.

**Name and compartment**
- Set the instance name to something descriptive, e.g. `game-server`.
- Leave the compartment as the default (your root compartment).

**Image and shape**
- Under *Image and shape*, click **Edit**.
- For **Image**, select **Ubuntu** and choose **Ubuntu 22.04**. Make sure you pick the plain Ubuntu image, not the Minimal or GPU variants.
- Click **Change shape**.
- Under *Shape series*, select **AMD**.
- Select **VM.Standard.E2.1.Micro** — this is the Always Free shape. It has 1 OCPU and 1 GB RAM.
- Click **Select shape**.

**Networking**
- Leave the default VCN and subnet settings. Oracle will create a new Virtual Cloud Network for you automatically if this is your first instance.
- Make sure **Assign a public IPv4 address** is set to **Yes**.

**Add SSH keys**
- This is how you will log into your server securely. Select **Generate a key pair for me**.
- Click **Save private key** and download the file (e.g. `ssh-key-2024-01-01.key`). **Keep this file safe — you cannot download it again.**
- Optionally download the public key as well.

**Boot volume**
- Leave the defaults (50 GB is free and sufficient).

Click **Create** at the bottom. The instance will take 1–2 minutes to provision. The status dot will turn green when it is running.

#### 3. Find your public IP address

1. Click on your new instance name in the list.
2. Under **Instance information → Primary VNIC**, you will see **Public IP address**. Copy this — you will need it throughout the rest of this guide.

#### 4. Open port 7777 in the Oracle firewall

Oracle has two layers of firewall: the **Security List** (Oracle's network-level firewall) and the **OS firewall** (Ubuntu's `ufw`). You need to open port 7777 in both.

**Security List (Oracle Console)**

1. From your instance page, scroll down to **Primary VNIC** and click the **Subnet** link.
2. Click **Security Lists** in the left sidebar, then click the default security list.
3. Click **Add Ingress Rules**.
4. Fill in the form:
   - **Source CIDR:** `0.0.0.0/0`
   - **IP Protocol:** `UDP`
   - **Destination Port Range:** `7777`
5. Click **Add Ingress Rules** to save.

**OS Firewall (Ubuntu `ufw`)**

Connect to your server first (see the next step), then run:

```bash
sudo ufw allow 7777/udp
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw status
```

#### 5. Connect to your server via SSH

**On macOS or Linux**, open Terminal and run:

```bash
chmod 400 /path/to/ssh-key-2024-01-01.key
ssh -i /path/to/ssh-key-2024-01-01.key ubuntu@YOUR_PUBLIC_IP
```

**On Windows**, use Windows Terminal or PowerShell:

```powershell
ssh -i C:\path\to\ssh-key-2024-01-01.key ubuntu@YOUR_PUBLIC_IP
```

Type `yes` when asked to confirm the server fingerprint. You are now logged into your server.

#### 6. Update the system

```bash
sudo apt update && sudo apt upgrade -y
```

Your server is ready. Continue to the next section to build and deploy the game.

---

## Building and Deploying

### Exporting the project

The project comes with two export presets already configured in `export_presets.cfg`:

| Preset | Platform | Output | Purpose |
|--------|----------|--------|---------|
| **Windows** | Windows Desktop | `builds/release/game.exe` | Client release build |
| **Server** | Linux (headless) | `builds/server/game_server.x86_64` | Dedicated server build |

> **Install export templates first if you haven't already.** In the Godot editor, go to **Editor → Manage Export Templates** and download the templates for Godot 4.6.

**To export:**

1. In the Godot editor, go to **Project → Export…**
2. Select the **Windows** preset from the list on the left and click **Export Project**. Leave the path as-is (`builds/release/game.exe`) and click **Save**.
3. Select the **Server** preset and click **Export Project**. Leave the path as-is (`builds/server/game_server.x86_64`) and click **Save**.

You should now have these files in your project folder:

```
builds/
├── release/
│   └── game.exe
└── server/
    ├── game_server.x86_64
    └── game_server.pck
```

---

### Uploading the server build

From your local machine, copy the server files to your Oracle Cloud instance using `scp`. Replace `YOUR_PUBLIC_IP` with your instance's actual IP address.

**macOS / Linux:**

```bash
scp -i /path/to/ssh-key.key \
    builds/server/game_server.x86_64 \
    builds/server/game_server.pck \
    ubuntu@YOUR_PUBLIC_IP:/home/ubuntu/
```

**Windows (PowerShell):**

```powershell
scp -i C:\path\to\ssh-key.key `
    builds\server\game_server.x86_64 `
    builds\server\game_server.pck `
    ubuntu@YOUR_PUBLIC_IP:/home/ubuntu/
```

Then SSH into your server and make the binary executable:

```bash
ssh -i /path/to/ssh-key.key ubuntu@YOUR_PUBLIC_IP
chmod +x /home/ubuntu/game_server.x86_64
```

You can do a quick sanity check to confirm it starts:

```bash
./game_server.x86_64 --server --headless
# Should print:
# [Server] Starting server...
# [Server] Ready. Listening on port 7777
```

Press `Ctrl+C` to stop it. In the next step you will set it up to run automatically as a service.

---

### Running as a systemd service

Running the server as a `systemd` service means it starts automatically on boot and restarts itself if it ever crashes — you never have to SSH in and start it manually.

#### 1. Create the service file

While logged into your server via SSH, run:

```bash
sudo nano /etc/systemd/system/game-server.service
```

Paste the following content exactly:

```ini
[Unit]
Description=Godot Multiplayer Game Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/home/ubuntu/game_server.x86_64 --server --headless
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Save and exit: press `Ctrl+X`, then `Y`, then `Enter`.

#### 2. Enable and start the service

```bash
# Reload systemd so it sees the new service file
sudo systemctl daemon-reload

# Enable the service so it starts automatically on every boot
sudo systemctl enable game-server

# Start it right now
sudo systemctl start game-server
```

#### 3. Check that it is running

```bash
sudo systemctl status game-server
```

You should see `Active: active (running)`. The output will look something like:

```
● game-server.service - Godot Multiplayer Game Server
     Loaded: loaded (/etc/systemd/system/game-server.service; enabled)
     Active: active (running) since ...
   Main PID: 12345 (game_server.x86_)
```

#### 4. View live logs

```bash
sudo journalctl -u game-server -f
```

This tails the server log in real time (Ctrl+C to exit). You will see `[Server]` messages whenever players connect, create lobbies, or disconnect.

#### 5. Useful service commands

```bash
# Stop the server
sudo systemctl stop game-server

# Restart the server (e.g. after uploading a new build)
sudo systemctl restart game-server

# Disable auto-start on boot
sudo systemctl disable game-server
```

#### 6. Deploying updates

Whenever you export a new server build, upload the new files and restart the service:

```bash
# From your local machine
scp -i /path/to/ssh-key.key \
    builds/server/game_server.x86_64 \
    builds/server/game_server.pck \
    ubuntu@YOUR_PUBLIC_IP:/home/ubuntu/

# Then SSH in and restart
ssh -i /path/to/ssh-key.key ubuntu@YOUR_PUBLIC_IP
sudo systemctl restart game-server
```

---

## Configuration

All tweakable constants live at the top of `autoloads/network.gd`:

```gdscript
const PORT = 7777          # UDP port the server listens on
const MAX_CLIENTS = 64     # Maximum simultaneous connections across all lobbies
const MAX_USERNAME_LENGTH = 32
const LOBBY_CODE_LENGTH = 4
```

And in `autoloads/game_state.gd` you can store any per-game state (scores, turns, phase) that needs to be synchronised across clients.

If you change `PORT`, remember to also open the new port in both the Oracle Security List and `ufw`.

---

## Integrating Into Your Game

The lobby system is intentionally decoupled from game logic. To hook it into your game:

1. **Replace `scenes/game.tscn`** with your actual game scene.

2. **Listen for the `game_started` signal** in your game scene — this fires on all clients (and the server) when the host presses Start:

   ```gdscript
   func _ready() -> void:
       GameState.game_started.connect(_on_game_started)

   func _on_game_started() -> void:
       # Your game begins here
   ```

3. **Use `GameState` to sync state.** Add RPCs to `game_state.gd` following the existing pattern (`update_score`, `end_game`). Call them on the server, which replicates to all clients via `call_local`:

   ```gdscript
   # Server calls this; all clients (including server) receive it
   @rpc("authority", "call_local", "reliable")
   func update_score(peer_id: int, new_score: int) -> void:
       scores[peer_id] = new_score
       state_changed.emit()
   ```

4. **Send actions from clients to the server** using `rpc_id(1, ...)` (peer ID 1 is always the server):

   ```gdscript
   submit_action.rpc_id(1, Network.my_id, "action_data")
   ```

5. **Access player info** anywhere via `Network.players` (a Dictionary of `peer_id → {username, lobby_code}`) and `Network.my_id`, `Network.my_username`, `Network.my_lobby_code`.

---

## Network API Reference

### Signals (connect to these in your scenes)

| Signal | Arguments | Fires when |
|--------|-----------|------------|
| `connection_succeeded` | — | Client successfully connects to the server |
| `connection_failed` | — | Client fails to connect |
| `server_disconnected` | — | Server closes or drops the connection |
| `lobby_created` | `code: String` | Lobby is created and the code is known |
| `lobby_joined` | `code: String` | Successfully joined an existing lobby |
| `lobby_join_failed` | `reason: String` | Join attempt was rejected (full, banned, not found, in-game) |
| `player_joined` | `id: int, data: Dictionary` | A player entered the lobby |
| `player_left` | `id: int, lobby_code: String` | A player left or disconnected |
| `ready_state_changed` | `peer_id: int, is_ready: bool` | A player toggled their ready state |
| `all_ready_changed` | `all_ready: bool` | Whether all non-host players are ready (host only) |
| `host_changed` | `new_host_id: int` | Host was transferred (voluntary or on disconnect) |
| `kicked_from_lobby` | — | The local player was kicked |
| `banned_from_lobby` | — | The local player was banned |

### Methods

| Method | Description |
|--------|-------------|
| `join_server(ip: String)` | Connect to the game server |
| `disconnect_from_server()` | Cleanly disconnect |
| `request_create_lobby_with_settings(max_players: int)` | Create a new lobby |
| `request_join_lobby(code: String)` | Join a lobby by its 4-digit code |
| `request_leave_lobby()` | Leave the current lobby |
| `request_kick_player(target_id: int)` | (Host only) Kick a player |
| `request_ban_player(target_id: int)` | (Host only) Kick and ban a player |
| `is_local_player_host() -> bool` | Check if the local player is the lobby host |
| `get_lobby_host() -> int` | Get the peer ID of the current host |

---

## Contributing

Pull requests are welcome. For large changes, please open an issue first to discuss what you'd like to change.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
