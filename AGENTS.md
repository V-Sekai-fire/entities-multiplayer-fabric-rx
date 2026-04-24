# AGENTS.md — multiplayer-fabric-rx

Guidance for AI coding agents working in this submodule.

## What this is

Godot 4 project providing the V-Sekai game client (social VR / VRSNS).
Includes multiplayer framework, VoIP, VRM avatar support with IK, and
user-generated content loading. This is the player-facing client that
connects to zone servers.

## Running

Import the project in the V-Sekai custom Godot editor fork
(`multiplayer-fabric-godot`). Nightly editor builds are available at
nightly.link from the `world-godot` CI workflow.

```sh
# Headless smoke test
godot --headless --quit
```

## Key files

| Path | Purpose |
|------|---------|
| `project.godot` | Godot 4 project config |
| `addons/` | V-Sekai addons (avatar, networking, VoIP, UGC) |
| `docker/` | Docker context for containerised builds |

## Conventions

- Requires the custom Godot fork — standard Godot 4 will be missing modules.
- GDScript files need SPDX headers:
  ```gdscript
  # SPDX-License-Identifier: MIT
  # Copyright (c) 2026 K. S. Ernest (iFire) Lee
  ```
- Commit message style: sentence case, no `type(scope):` prefix.
  Example: `Fix avatar IK root offset on uneven terrain`
