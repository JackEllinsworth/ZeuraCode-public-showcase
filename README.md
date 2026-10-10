# ZeuraCore

The server and client codebase behind **Zeura**, an airline roleplay experience on Roblox. Players check in, drop off their bags, go through security, board and fly. Staff run the airport through in-game tools. It is a multiplayer game with an external REST backend, built with Luau on [AeroGameFramework](https://github.com/Sleitnick/AeroGameFramework) and synced from VS Code with [Rojo](https://rojo.space).

> **When this was made:** written between **August 2021 and July 2024**, mostly in my own time, from high school through to the end of sixth form. The dates come from the header of each file. It is published as a portfolio piece and is no longer actively developed. Its age shows in places, for example AeroGameFramework has since been archived by its author in favour of Knit.

<!-- TODO: add player numbers if you have them, e.g. "Peak of X concurrent players, Y total visits", plus screenshots or a short clip. -->

---

## What I built

Everything under `src/Server/Services` and `src/Client/Controllers` (except the files listed in [Third-party code](#third-party-code)) is my own work, as are the custom Cmdr commands and the configuration modules. That's roughly **100 files and 11,000 lines of Luau** out of about 24,000 lines in the repo.

### Backend API (not in this repo)
Player data isn't saved in Roblox DataStores. I wrote a **custom Node.js REST API hosted on my own VPS** that handles all data saving and loading, with **MongoDB** as the database. It has separate endpoints for player data, moderation records and flight data, each protected by its own API key. The game talks to it over HTTPS, so several Roblox places (and external tools) can share one data source. The API's source code is not part of this repository.

### Data layer (`src/Server/Services/Data`)
- **DataService**: the in-game HTTP client for that API. It builds the endpoint URLs and handles JSON encoding and decoding, failures and logging, and also posts Discord webhook embeds.
- **ProfileService** (my own, not the community library of the same name): loads, caches and saves player profiles with about two requests per player per session, plus metadata and atomic-style increments.
- **CacheService**: a server-only in-memory store with per-store defaults, used by the other services for per-player session state.
- **PurchaseService**: processes Developer Product receipts against registered "purchase monitors". It records receipts that fail and alerts staff through a webhook so purchases can be restored manually.
- **ClassService**: the ticket system for permanent and one-time class tickets (Executive, Premium, Standard+, Standard). It works out which classes a player can access from what they own, their group rank and their current booking.
- **PermissionService**: centralised permissions mapped from Roblox group rank ranges. Every staff-only RemoteFunction is checked here on the server, so the client is never trusted.
- **ModerationService**: warnings, kicks, temporary and permanent bans stored on the backend, with Discord webhook logging.
- **MilesService**: an air-miles currency earned while flying, with batched and throttled autosaves.
- **SuitcaseService**: luggage tags that follow the player's bag from check-in to baggage reclaim.

### Airport infrastructure (`src/Server/Services/Game/Infrastructure`)
- **QueueService** (4th rewrite): generic queue management used by check-in desks.
- **ManualCheckInService / SelfCheckInService**: staffed desks and self-service kiosks. Staff claim a desk, serve the next passenger in the queue and issue tickets.
- **ScannersService**: security scanners and boarding-pass gates.
- **ConveyorService**: baggage belt simulation.
- **Screens/** (rewritten June 2024): departures, arrivals, baggage and info boards, all driven from a single flight event.
- **GateScreenService, BoardingService, IFEService, PowerPointService, ATCControlService**: gate displays, boarding flow, in-flight entertainment, presentation screens for staff training, and an ATC panel.

### Game, staff and moderation (`src/Server/Services/Game`)
- **FlightService**: creates and updates the active flight and broadcasts changes to every system that depends on it.
- **AudioAnnouncementService**: builds spoken airport announcements (e.g. gate numbers) by playing timestamped segments from a single audio asset.
- **HRPanelService + HRPanelController**: an in-game admin panel for managing flights, infractions, staff lock, music, weather and aircraft spawning.
- **StaffLockService, TeamService, UniformService, LanyardService, SpawningService, MusicService** and others.

### Client (`src/Client/Controllers`)
Controllers paired with the server services: the HR panel UI, check-in UIs, the IFE, leaderboards, announcements, uniforms and suitcase customisation.

### Admin commands (`src/Server/Modules/Cmdr/Commands`)
My own command set built on Cmdr, covering moderation (`warn`, `kick`, `tempBan`, `permBan`), flight control, tickets, miles and developer data tools. The custom argument types `Class`, `SuitcaseTheme` and `TeamRole` in `Cmdr/BuiltInTypes` are mine too.

---

## Architecture

```
            ┌──────────────── Roblox server ─────────────────┐
 Client     │  Aero services                                 │      External
 controllers│                                                │
   ──Remote─┼─▶ HRPanel / CheckIn / ... ──▶ PermissionService │
   (server- │         │                                      │
   validated)        ▼                                      │
            │  FlightService ──events──▶ Screens, Gates,     │
            │         │                  Queues, Audio ...   │
            │         ▼                                      │
            │  ProfileService ◀──▶ CacheService              │
            │         │                                      │
            │         ▼                                      │
            │  DataService ────────────HTTPS─────────────────┼──▶ Node.js REST API (VPS)
            │                                                │          │
            │                                                │          ▼
            │                                                │       MongoDB
            │  ModerationService / PurchaseService ──────────┼──▶ Discord webhooks
            └────────────────────────────────────────────────┘
```

- **Server-authoritative:** clients ask through remotes and the server checks permissions and state before acting.
- **Event-driven:** services expose events (e.g. `FlightService` → `"Flight"`), so infrastructure updates without tight coupling.
- **External persistence:** data lives in MongoDB behind my own Node.js API on a VPS instead of Roblox DataStores, so the same player data works across several places and can be reached outside Roblox.

---

## Third-party code

These files were **not written by me**. They're included as dependencies under their original licences, with their author headers kept.

| Path | Project | Author | Licence |
|---|---|---|---|
| `src/_framework/**`, `.agf` | [AeroGameFramework](https://github.com/Sleitnick/AeroGameFramework) | Stephen Leitnick (Sleitnick) | MIT |
| `src/Shared/{Date,ListenerList,NumberUtil,Signal,StringUtil,TableUtil,Thread,VectorUtil}.lua` | AeroGameFramework shared modules | Stephen Leitnick | MIT |
| `src/Client/Controllers/Fade.lua`, `src/Client/Modules/{CameraShaker,Smooth,Tween}/**`, `src/Client/Modules/PID.lua` | AeroGameFramework client modules | Stephen Leitnick | MIT |
| `src/Client/Controllers/TaskScheduler.lua` | Task Scheduler (AGF-modified) | EchoReaper | As released by the author |
| `src/Shared/Base64.lua` | Base64 for AGF | antifragileer | BSD |
| `src/Shared/Maid.lua`, `src/Shared/ZoneModule/Maid.lua` | [NevermoreEngine](https://github.com/Quenty/NevermoreEngine) Maid | Quenty | MIT |
| `src/Shared/Promise.lua` | [roblox-lua-promise](https://github.com/evaera/roblox-lua-promise) | evaera | MIT |
| `src/Shared/RotatedRegion3.lua`, `src/Shared/ZoneModule/RotatedRegion3/**` | [RotatedRegion3](https://devforum.roblox.com/t/rotated-region-3-module/334068) | EgoMoose | See source |
| `src/Shared/ZoneModule/**` | [ZonePlus](https://github.com/1ForeverHD/ZonePlus) | ForeverHD | See upstream repo |
| `src/Server/Modules/Cmdr/**` (except `Commands/` and the three custom types above) | [Cmdr](https://github.com/evaera/Cmdr) | evaera | MIT |
| `src/Client/Modules/Aesthetics/Rain.lua` | Rain module v1.0 | buildthomas | Apache-2.0 |
| `roblox.toml` | Generated Selene standard library for Roblox | generated by `generate-roblox-std` | n/a |

---

## Running it

Requirements: [Aftman](https://github.com/LPGhatguy/aftman) (installs Rojo 7.3), Roblox Studio with the Rojo plugin.

```bash
aftman install
cp config/Secrets.example.lua src/Server/Modules/Secrets.lua   # then fill in your own values
rojo serve default.project.json
```

Then connect from the Rojo plugin in Studio. Note:
- **The code only, not the map.** Services expect specific Workspace models and GUIs (e.g. `Workspace.Infrastructure.Queues`, `PlayerGui.ManualCheckIn`) that live in the original place file, which isn't included. Many systems won't do anything in an empty baseplate.
- **Backend not included.** The Node.js API (VPS) and MongoDB database aren't part of this repo. Without `Secrets.lua` and a compatible API, external data calls fail and log a warning instead of crashing.
- Linting: `selene src` (config in `selene.toml`).

## Security note

No credentials are included in this repository. API keys and webhook URLs are loaded from `src/Server/Modules/Secrets.lua`, which is git-ignored. See `config/Secrets.example.lua` for the expected shape.

## Licence

The original code in this repository (see [What I built](#what-i-built)) is © Jack Ellinsworth, all rights reserved. It's published for viewing as a portfolio piece. Third-party code stays under the licences listed above.
