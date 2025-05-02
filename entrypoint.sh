#!/bin/bash

# Function to validate game type
validate_gametype() {
    local gt=$1
    case "$gt" in
        "R6Game.R6TeamBomb"|"R6Game.R6HostageRescueAdvGame"|"R6Game.R6TeamDeathMatchGame"|"R6Game.R6EscortPilotGame"|"R6Game.R6DeathMatch"|"R6Game.R6TerroristHuntCoopGame")
            return 0
            ;;
        *)
            echo "WARNING: Invalid game type '$gt'. Valid types are:"
            echo "- R6Game.R6TeamBomb"
            echo "- R6Game.R6HostageRescueAdvGame"
            echo "- R6Game.R6TeamDeathMatchGame"
            echo "- R6Game.R6EscortPilotGame"
            echo "- R6Game.R6DeathMatch"
            echo "- R6Game.R6TerroristHuntCoopGame"
            return 1
            ;;
    esac
}

# Start Xvfb
Xvfb :0 -screen 0 1024x768x16 &
sleep 1

# Make the update_ini script executable
chmod +x /update_ini.sh

# Set base ports, these are calculated due to OpenRVS requirements
if [ ! -z "$PORT" ]; then
    SERVER_BEACON_PORT=$((PORT + 1000))
    BEACON_PORT=$((PORT + 2000))

    # Set port configurations
    crudini --set "/rvs/System/$INI_CFG" "URL" "Port" "$PORT"
    crudini --set "/rvs/System/$INI_CFG" "IpDrv.UdpBeacon" "ServerBeaconPort" "$SERVER_BEACON_PORT"
    crudini --set "/rvs/System/$INI_CFG" "IpDrv.UdpBeacon" "BeaconPort" "$BEACON_PORT"
fi

if [ ! -z "$GAME_PRESET" ]; then
    case "$GAME_PRESET" in
        "ADVERSARIAL")
            # Set adversarial preset values
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "MaxPlayers" "16"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "NbTerro" "0"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "RoundTime" "240"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "BetweenRoundTime" "45"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "BombTime" "45"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "CamFirstPerson" "True"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "CamThirdPerson" "True"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "CamFreeThirdP" "True"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "CamGhost" "True"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "CamFadeToBlack" "False"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "CamTeamOnly" "True"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "FriendlyFire" "True"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "Autobalance" "True"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "TeamKillerPenalty" "True"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "AllowRadar" "True"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "RoundsPerMatch" "10"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "ForceFPersonWeapon" "True"

            declare -A maps=([0]="Airport" [1]="Alpines" [2]="Bank" [3]="Garage" [4]="Import_Export" 
                           [5]="Island_Dawn" [6]="MeatPacking" [7]="Mountain_High" [8]="Oil_Refinery"
                           [9]="Parade" [10]="Peaks" [11]="Penthouse" [12]="Presidio" [13]="Prison"
                           [14]="Shipyard" [15]="Streets" [16]="Training" [17]="Warehouse")

            declare -A gametypes=([0]="R6Game.R6TeamBomb" [1]="R6Game.R6HostageRescueAdvGame" 
                                [2]="R6Game.R6TeamBomb" [3]="R6Game.R6TeamDeathMatchGame"
                                [4]="R6Game.R6EscortPilotGame" [5]="R6Game.R6DeathMatch"
                                [6]="R6Game.R6TeamBomb" [7]="R6Game.R6EscortPilotGame"
                                [8]="R6Game.R6HostageRescueAdvGame" [9]="R6Game.R6TeamBomb"
                                [10]="R6Game.R6TeamDeathMatchGame" [11]="R6Game.R6TeamDeathMatchGame"
                                [12]="R6Game.R6DeathMatch" [13]="R6Game.R6TeamBomb"
                                [14]="R6Game.R6TeamBomb" [15]="R6Game.R6TeamDeathMatchGame"
                                [16]="R6Game.R6DeathMatch" [17]="R6Game.R6EscortPilotGame")

            for i in {0..31}; do
                if [ ! -z "${maps[$i]}" ]; then
                    crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6MapList" "Maps[$i]" "${maps[$i]}"
                    crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6MapList" "GameType[$i]" "${gametypes[$i]}"
                fi
            done
            ;;
        "COOP")
            # Set cooperative preset values
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "MaxPlayers" "8"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "NbTerro" "20"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "RoundTime" "600"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "BetweenRoundTime" "30"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "BombTime" "300"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "CamFirstPerson" "True"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "CamThirdPerson" "True"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "CamFreeThirdP" "False"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "CamGhost" "False"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "CamFadeToBlack" "True"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "CamTeamOnly" "True"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "FriendlyFire" "False"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "Autobalance" "False"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "TeamKillerPenalty" "False"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "AllowRadar" "True"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "RoundsPerMatch" "1"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "ForceFPersonWeapon" "False"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "AIBkp" "True"
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "DiffLevel" "2"

            declare -A maps=([0]="Airport" [1]="Alpines" [2]="Bank" [3]="Garage" [4]="Import_Export" 
                           [5]="Island_Dawn" [6]="MeatPacking" [7]="Mountain_High" [8]="Oil_Refinery"
                           [9]="Parade" [10]="Peaks" [11]="Penthouse" [12]="Presidio" [13]="Prison"
                           [14]="Shipyard" [15]="Streets" [16]="Training" [17]="Warehouse")

            declare -A gametypes=([0]="R6Game.R6TerroristHuntCoopGame" [1]="R6Game.R6TerroristHuntCoopGame" 
                                [2]="R6Game.R6TerroristHuntCoopGame" [3]="R6Game.R6TerroristHuntCoopGame"
                                [4]="R6Game.R6TerroristHuntCoopGame" [5]="R6Game.R6TerroristHuntCoopGame"
                                [6]="R6Game.R6TerroristHuntCoopGame" [7]="R6Game.R6TerroristHuntCoopGame"
                                [8]="R6Game.R6TerroristHuntCoopGame" [9]="R6Game.R6TerroristHuntCoopGame"
                                [10]="R6Game.R6TerroristHuntCoopGame" [11]="R6Game.R6TerroristHuntCoopGame"
                                [12]="R6Game.R6TerroristHuntCoopGame" [13]="R6Game.R6TerroristHuntCoopGame"
                                [14]="R6Game.R6TerroristHuntCoopGame" [15]="R6Game.R6TerroristHuntCoopGame"
                                [16]="R6Game.R6TerroristHuntCoopGame" [17]="R6Game.R6TerroristHuntCoopGame")

            for i in {0..31}; do
                if [ ! -z "${maps[$i]}" ]; then
                    crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6MapList" "Maps[$i]" "${maps[$i]}"
                    crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6MapList" "GameType[$i]" "${gametypes[$i]}" 
                fi                               
            done
            ;;
        *)
            echo "ERROR: Invalid game preset '$GAME_PRESET'. Valid options are 'ADVERSARIAL' or 'COOP'."
            exit 1
            ;;
    esac
fi

# Set common server.ini values from environment variables with proper naming
[ ! -z "$NAME" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "ServerName" "$NAME"
[ ! -z "$MOTD" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "MOTD" "$MOTD"
[ ! -z "$MAX_PLAYERS" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "MaxPlayers" "$MAX_PLAYERS"
[ ! -z "$ROUND_TIME" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "RoundTime" "$ROUND_TIME"
[ ! -z "$BETWEEN_ROUND_TIME" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "BetweenRoundTime" "$BETWEEN_ROUND_TIME"
[ ! -z "$ROUNDS_PER_MATCH" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "RoundsPerMatch" "$ROUNDS_PER_MATCH"
[ ! -z "$ROTATE_MAP" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "RotateMap" "$ROTATE_MAP"
[ ! -z "$ADMIN_PASSWORD" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "AdminPassword" "$ADMIN_PASSWORD"
[ ! -z "$GAME_PASSWORD" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "GamePassword" "$GAME_PASSWORD"
[ ! -z "$FRIENDLY_FIRE" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "FriendlyFire" "$FRIENDLY_FIRE"
[ ! -z "$FORCE_FIRST_PERSON" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "ForceFPersonWeapon" "$FORCE_FIRST_PERSON"
[ ! -z "$CAM_THIRD_PERSON" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "CamThirdPerson" "$CAM_THIRD_PERSON"
[ ! -z "$CAM_TEAM_ONLY" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "CamTeamOnly" "$CAM_TEAM_ONLY"
[ ! -z "$NUM_TERRORISTS" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "NbTerro" "$NUM_TERRORISTS"
[ ! -z "$DIFFICULTY_LEVEL" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "DiffLevel" "$DIFFICULTY_LEVEL"
[ ! -z "$AI_BACKUP" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "AIBkp" "$AI_BACKUP"
[ ! -z "$BOMB_TIME" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "BombTime" "$BOMB_TIME"
[ ! -z "$CAM_FIRST_PERSON" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "CamFirstPerson" "$CAM_FIRST_PERSON"
[ ! -z "$CAM_FREE_THIRD_P" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "CamFreeThirdP" "$CAM_FREE_THIRD_P"
[ ! -z "$CAM_GHOST" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "CamGhost" "$CAM_GHOST"
[ ! -z "$CAM_FADE_TO_BLACK" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "CamFadeToBlack" "$CAM_FADE_TO_BLACK"
[ ! -z "$ALLOW_ARM_PATCH" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "AllowArmPatch" "$ALLOW_ARM_PATCH"
[ ! -z "$LOUD_FOOT" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "LoudFoot" "$LOUD_FOOT"
[ ! -z "$SHOW_NAMES" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "ShowNames" "$SHOW_NAMES"
[ ! -z "$INTERNET_SERVER" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "InternetServer" "$INTERNET_SERVER"
[ ! -z "$AUTOBALANCE" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "Autobalance" "$AUTOBALANCE"
[ ! -z "$TEAM_KILLER_PENALTY" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "TeamKillerPenalty" "$TEAM_KILLER_PENALTY"
[ ! -z "$ALLOW_RADAR" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "AllowRadar" "$ALLOW_RADAR"
[ ! -z "$USE_ADMIN_PASSWORD" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "UseAdminPassword" "$USE_ADMIN_PASSWORD"
[ ! -z "$DEDICATED_SERVER" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "DedicatedServer" "$DEDICATED_SERVER"
[ ! -z "$SPAM_THRESHOLD" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "SpamThreshold" "$SPAM_THRESHOLD"
[ ! -z "$CHAT_LOCK_DURATION" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "ChatLockDuration" "$CHAT_LOCK_DURATION"
[ ! -z "$VOTE_BROADCAST_MAX_FREQUENCY" ] && crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6ServerInfo" "VoteBroadcastMaxFrequency" "$VOTE_BROADCAST_MAX_FREQUENCY"

# Process MAP_0 through MAP_31 environment variables
for i in {0..31}; do
    map_var="MAP_${i}"
    gametype_var="GAMETYPE_${i}"
    
    if [ ! -z "${!map_var}" ]; then
        crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6MapList" "Maps[$i]" "${!map_var}"
        
        # Set game type if specified, validate it first
        if [ ! -z "${!gametype_var}" ]; then
            if validate_gametype "${!gametype_var}"; then
                crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6MapList" "GameType[$i]" "${!gametype_var}"
            else
                echo "Error: Invalid game type '${!gametype_var}' for map '${!map_var}'."
                exit 1
            fi
        else
            # Default to TDM if no game type specified
            crudini --set "/rvs/System/$SERVER_CFG" "Engine.R6MapList" "GameType[$i]" "R6Game.R6TeamDeathMatchGame"
        fi
    fi
done

# Update INI files using the dedicated script
/update_ini.sh "SERVER_" "/rvs/System/$SERVER_CFG"
/update_ini.sh "RAVENSHIELD_" "/rvs/System/$INI_CFG"

# Start the RavenShield server
cd /rvs/System
wine UCC.exe server -ini="$INI_CFG" -serverini="$SERVER_CFG" -log