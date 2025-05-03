# RavenShield Dedicated Server

This Docker container sets up an environment to host the RavenShield Dedicated Server using Ubuntu, Wine, and Xvfb.

## Overview
- The container expects `/rvs` to contain the root of your game files (ie. `/system` `/mods` etc)
- Map the correct UDP ports that are specified in your game init files to be able to connect to the game server (usually `7777`, `8777`,`9777`)

# Environment Variables

## Game Presets
You can use the `GAME_PRESET` variable to quickly configure common server settings:

| Preset | Description |
|--------|-------------|
| `ADVERSARIAL` | PVP preset with competitive settings |
| `COOP` | PVE preset optimized for cooperative play |

## Server Configuration
The following environment variables can be used to configure the server these will override any settings applied via the game preset:

| Variable | Description | Section | Key | Default |
|----------|-------------|---------|-----|---------|
| `PORT` | Base port for server (automatically sets beacon ports) | URL | Port | `7777` |
| `NAME` | Name of the server | Engine.R6ServerInfo | ServerName | `Raven Shield ADVER` |
| `MOTD` | Message of the day | Engine.R6ServerInfo | MOTD | ` ` |
| `MAX_PLAYERS` | Maximum number of players | Engine.R6ServerInfo | MaxPlayers | `16` |
| `ROUND_TIME` | Time limit per round (seconds) | Engine.R6ServerInfo | RoundTime | `240` |
| `BETWEEN_ROUND_TIME` | Time between rounds (seconds) | Engine.R6ServerInfo | BetweenRoundTime | `45` |
| `ROUNDS_PER_MATCH` | Number of rounds per match | Engine.R6ServerInfo | RoundsPerMatch | `10` |
| `ROTATE_MAP` | Enable/disable map rotation | Engine.R6ServerInfo | RotateMap | `True` |
| `GAME_PASSWORD` | Password to join the server | Engine.R6ServerInfo | GamePassword | ` ` |
| `ADMIN_PASSWORD` | Admin password | Engine.R6ServerInfo | AdminPassword | ` ` |
| `USE_ADMIN_PASSWORD` | Enable admin password (set to True if USE_PASSOWRD IS SET)| Engine.R6ServerInfo | UseAdminPassword | `False` |
| `FRIENDLY_FIRE` | Enable/disable friendly fire | Engine.R6ServerInfo | FriendlyFire | `True` |
| `FORCE_FIRST_PERSON` | Force first person view | Engine.R6ServerInfo | ForceFPersonWeapon | `True` |
| `CAM_FIRST_PERSON` | Allow first person camera | Engine.R6ServerInfo | CamFirstPerson | `True` |
| `CAM_THIRD_PERSON` | Allow third person camera | Engine.R6ServerInfo | CamThirdPerson | `True` |
| `CAM_FREE_THIRD_P` | Allow free third person camera | Engine.R6ServerInfo | CamFreeThirdP | `True` |
| `CAM_GHOST` | Allow ghost camera | Engine.R6ServerInfo | CamGhost | `True` |
| `CAM_FADE_TO_BLACK` | Enable fade to black on death | Engine.R6ServerInfo | CamFadeToBlack | `False` |
| `CAM_TEAM_ONLY` | Restrict camera to team only | Engine.R6ServerInfo | CamTeamOnly | `True` |
| `NUM_TERRORISTS` | Number of terrorists (PVE mode) | Engine.R6ServerInfo | NbTerro | `0` |
| `DIFFICULTY_LEVEL` | AI difficulty level (1-3) | Engine.R6ServerInfo | DiffLevel | `2` |
| `AI_BACKUP` | Enable/disable AI backup | Engine.R6ServerInfo | AIBkp | `False` |
| `BOMB_TIME` | Time limit for bomb defusal (seconds) | Engine.R6ServerInfo | BombTime | `45` |
| `ALLOW_ARM_PATCH` | Allow custom arm patches | Engine.R6ServerInfo | AllowArmPatch | `True` |
| `LOUD_FOOT` | Enable loud footsteps | Engine.R6ServerInfo | LoudFoot | `True` |
| `SHOW_NAMES` | Show player names | Engine.R6ServerInfo | ShowNames | `True` |
| `INTERNET_SERVER` | Mark as internet server | Engine.R6ServerInfo | InternetServer | `True` |
| `AUTOBALANCE` | Enable team autobalance | Engine.R6ServerInfo | Autobalance | `True` |
| `TEAM_KILLER_PENALTY` | Enable team killer penalties | Engine.R6ServerInfo | TeamKillerPenalty | `True` |
| `ALLOW_RADAR` | Enable radar | Engine.R6ServerInfo | AllowRadar | `True` |
| `DEDICATED_SERVER` | Mark as dedicated server | Engine.R6ServerInfo | DedicatedServer | `True` |
| `SPAM_THRESHOLD` | Chat spam threshold | Engine.R6ServerInfo | SpamThreshold | `4` |
| `CHAT_LOCK_DURATION` | Chat lock duration (seconds) | Engine.R6ServerInfo | ChatLockDuration | `30` |
| `VOTE_BROADCAST_MAX_FREQUENCY` | Vote broadcast frequency | Engine.R6ServerInfo | VoteBroadcastMaxFrequency | `30` |

## Port Configuration
When setting the `PORT` variable, the following ports are automatically configured:
- Game Port: `PORT` (default: 7777)
- Server Beacon Port: `PORT + 1000` (default: 8777)
- Beacon Port: `PORT + 2000` (default: 9777)

## Map Configuration
You can configure up to 32 maps (0-31) using these environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `MAP_n` | Map name for slot n (0-31) | None |
| `GAMETYPE_n` | Game type for map n (0-31) | `R6Game.R6TeamDeathMatchGame` |

Valid game types are:
- `R6Game.R6TeamBomb` (PVP - Team Bomb Mission)
- `R6Game.R6HostageRescueAdvGame` (PVP - Hostage Rescue)
- `R6Game.R6TeamDeathMatchGame` (PVP - Team Deathmatch)
- `R6Game.R6EscortPilotGame` (PVP - Pilot Escort)
- `R6Game.R6DeathMatch` (PVP - Free for All)
- `R6Game.R6TerroristHuntCoopGame` (PVE - Terrorist Hunt)

Example:
```sh
MAP_0=Training_MP
GAMETYPE_0=R6Game.R6TeamDeathMatchGame
MAP_1=Airport_MP
GAMETYPE_1=R6Game.R6TerroristHuntCoopGame
```

## Advanced Configuration
Additional configuration options can be set using, this overrides all other values set by other environment variable means:
- `SERVER_*` prefix for Server.ini values
- `RAVENSHIELD_*` prefix for RavenShield.ini values

The format is `PREFIX_SECTION__KEY=VALUE` (note double underscore for section separation)

ie. `SERVER_Engine__R6ServerInfo_ServerName=MyServer`

# Usage
Example command to run the server

```sh 
docker run -p:7777:7777/udp -p:8777:8777/udp -p:9777:9777/udp ghcr.io/danpowell88/ravenshield_dedicatedserver
```

Use a different port
```sh
docker run -e PORT=5555 -p:5555:5555/udp -p:6555:6555/udp -p:7555:7555/udp ghcr.io/danpowell88/ravenshield_dedicatedserver
```

Run a coop server
```sh
docker run -e GAME_PRESET=COOP -p:7777:7777/udp -p:8777:8777/udp -p:9777:9777/udp ghcr.io/danpowell88/ravenshield_dedicatedserver
```

Run an adversarial server
```sh
docker run -e GAME_PRESET=ADVERSARIAL -p:7777:7777/udp -p:8777:8777/udp -p:9777:9777/udp ghcr.io/danpowell88/ravenshield_dedicatedserver
```

# Future Enhancements
Create a debug build of OpenRVS so its easier to tell what is going on when the server isnt being registered
Download the game files from internet archive at runtime