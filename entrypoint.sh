#!/bin/bash

set -e

GAMEFILES_DIR="/rvs/gamefiles"
SETUP_DIR="/rvs/setup"

mkdir -p "$SETUP_DIR"
mkdir -p "$GAMEFILES_DIR"

if [[ "${FORCE_INITIALISE,,}" == "true" ]]; then
    rm -rf /rvs/*
    rm -rf /rvs/.[!.]*
    rm -rf /rvs/..?*
fi

if [[ "${FORCE_INITIALISE_GAMEFILES,,}" == "true" ]]; then
    echo "Force initialisation is enabled, removing all files in $GAMEFILES_DIR directory."
    rm -rf $GAMEFILES_DIR
fi

if [[ "${FORCE_INITIALISE_SETUP,,}" == "true" ]]; then
    echo "Force initialisation is enabled, removing all files in $SETUP_DIR directory."
    rm -rf $SETUP_DIR
fi

if [[ "${BYO_GAMEFILES,,}" == "true" ]]; then
    echo "BYO_GAMEFILES is true, skipping download and extraction of server files."
else
    # Skip download_server_files if $GAMEFILES_DIR is not empty, allows providing own source for game files
    if [ "$(ls -A "$SETUP_DIR/game" 2>/dev/null)" ]; then
        echo "Setup games files directory is not empty, skipping downloading server files."    
    else
        echo "Downloading server files..."
        ZIP_URL="https://archive.org/download/ravenshield-windows-dedicated-server-files-and-patches/Ravenshield%20Windows%20Dedicated%20Server%20Files%20and%20Patches.zip"
        mkdir -p $SETUP_DIR/game
        curl -L -o "$SETUP_DIR/game/dedicated_server_files.zip" "$ZIP_URL"
    fi

    if [ "$(ls -A "$SETUP_DIR/openrvs" 2>/dev/null)" ]; then
        echo "Setup openrvs files directory is not empty, skipping downloading server files."    
    elif [[ "${INSTALL_OPENRVS,,}" == "true" ]]; then        
        echo "Downloading OpenRVS..."
        mkdir -p $SETUP_DIR/openrvs 
        curl -L -o $SETUP_DIR/openrvs/openrvs.zip "https://github.com/OpenRVS-devs/OpenRVS/releases/download/v1.6/OpenRVS-v1.6.zip" 
    else
        echo "Skipping OpenRVS download as INSTALL_OPENRVS is not set to true."
    fi

    echo "Check to Extracting server files..."
    if [ ! "$(ls -A "$GAMEFILES_DIR" 2>/dev/null)" ]; then
        echo "Extracting server files..."
        unzip -o "$SETUP_DIR/game/dedicated_server_files.zip" -d "$SETUP_DIR/extracted_files"

        find "$SETUP_DIR/extracted_files" -type f -name '*.zip' | while read zipfile; do
            dir=$(dirname "$zipfile")
            base=$(basename "$zipfile" .zip)
            # Remove 'win32' (case-insensitive) from the filename before extracting numbers
            nums=$(echo "$base" | sed 's/[Ww][Ii][Nn]32//g' | grep -o '[0-9]\+' | tr -d '\n')
            if [ -n "$nums" ]; then
                newname="$dir/$nums.zip"
                if [ "$zipfile" != "$newname" ]; then
                    mv "$zipfile" "$newname"
                fi
            fi
        done

        # Directories to look for (case-insensitive)
        DIRS="Animations ArmPatches KarmaData Maps Mods Save Sounds StaticMeshes System Template Textures"

        # Process each internal zip file one after the other, alphabetically
        find "$SETUP_DIR/extracted_files" -type f -name '*.zip' | sort | while read innerzip; do
            # Create a directory named after the zip file (without .zip)
            innerdir="${innerzip%.zip}"
            mkdir -p "$innerdir"
            unzip -o "$innerzip" -d "$innerdir"

            # After each unzip, check for the highest directory containing any required dirs
            HIGHEST_DIR=""
            while IFS= read -r dir; do
                for d in $DIRS; do
                    if [ -d "$dir/$d" ] || [ -d "$dir/$(echo $d | tr '[:upper:]' '[:lower:]')" ]; then
                        HIGHEST_DIR="$dir"
                        break 2
                    fi
                done            
            done < <(find "$innerdir" -type d -print | sort)

            if [ ! -z "$HIGHEST_DIR" ]; then
                cd "$HIGHEST_DIR"
                # Rename all immediate subdirectories to lowercase, but only if the case is different
                for d in */; do
                    d="${d%/}"
                    lower=$(echo "$d" | tr '[:upper:]' '[:lower:]')
                    if [ "$d" != "$lower" ]; then
                        # use a temporary folder in case the volume mount is a windows share
                        # and the rename fails due to case insensitivity
                        echo "Renaming $d to $lower"
                        tmp="${d}_tmp_mv"
                        mv "$d" "$tmp"
                        mv "$tmp" "$lower"
                    fi
                done

                # copy pwd to $GAMEFILES_DIR
                echo "Copying files from $HIGHEST_DIR to $GAMEFILES_DIR" 
                cp -a . "$GAMEFILES_DIR/"
            else
                echo "No required directories found in $innerzip"
                exit 1
            fi
        done
        
        rm -rf $SETUP_DIR/extracted_files
    fi 
fi   

if [[ "${PATCH_R6GAMESERVICE,,}" == "true" ]]; then
    echo "Patching R6GameService.dll hex values"
    cd $GAMEFILES_DIR/system 
    xxd -p R6GameService.dll > R6GameService.hex 
    sed -i 's/dfe0f6c44175/dfe0f6c441eb/g' R6GameService.hex 
    xxd -p -r R6GameService.hex > R6GameService.dll 
    rm R6GameService.hex  
fi   

# Patch OpenRVS if BYO_GAMEFILES is false or INSTALL_OPENRVS is true
if [[ "${BYO_GAMEFILES,,}" != "true" || "${INSTALL_OPENRVS,,}" == "true" ]]; then
    echo "Patching OpenRVS"
    mkdir -p $SETUP_DIR/extracted_files/openrvs
    unzip $SETUP_DIR/openrvs/openrvs.zip -d "$SETUP_DIR/extracted_files/openrvs"
    
    cp -f $SETUP_DIR/extracted_files/openrvs/openrvs.ini $SETUP_DIR/extracted_files/openrvs/OpenRVS.u $SETUP_DIR/extracted_files/openrvs/R6ClassDefines.ini $SETUP_DIR/extracted_files/openrvs/Servers.list $GAMEFILES_DIR/system/ 
    cp -f $SETUP_DIR/extracted_files/openrvs/OpenRenderFix.utx $GAMEFILES_DIR/textures/OpenRenderFix.utx    
    
    echo "Patching OpenRVS configuration"
    # Add OpenRVS configuration to Ravenshield.mod
    MOD_FILE="$GAMEFILES_DIR/mods/RavenShield.mod"
    sed -i '/ServerActions=IpDrv.UdpBeacon/d' "$MOD_FILE"
    grep -q "ServerActors=OpenRVS.OpenServer" "$MOD_FILE" || echo "ServerActors=OpenRVS.OpenServer" >> "$MOD_FILE"
    grep -q "ServerActors=OpenRVS.OpenBeacon" "$MOD_FILE" || echo "ServerActors=OpenRVS.OpenBeacon" >> "$MOD_FILE"
    grep -q "ServerActors=OpenRenderFix.OpenFix" "$MOD_FILE" || echo "ServerActors=OpenRenderFix.OpenFix" >> "$MOD_FILE"
    grep -q "ServerPackages=OpenRenderFix" "$MOD_FILE" || echo "ServerPackages=OpenRenderFix" >> "$MOD_FILE"

    rm -rf "$SETUP_DIR/extracted_files"
fi

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

# If INTERNET_SERVER is not set, read it from the server config INI
if [ -z "$INTERNET_SERVER" ]; then
    INTERNET_SERVER=$(crudini --get "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "InternetServer" 2>/dev/null || echo "")
fi

# Set base ports, these are calculated due to OpenRVS requirements
if [ -z "$PORT" ]; then
    # Read port from INI file if not set in environment
    PORT=$(crudini --get "$GAMEFILES_DIR/system/$INI_CFG" "URL" "Port")
fi

if [ ! -z "$PORT" ]; then
    SERVER_BEACON_PORT=$((PORT + 1000))
    BEACON_PORT=$((PORT + 2000))

    # Set port configurations
    crudini --set "$GAMEFILES_DIR/system/$INI_CFG" "URL" "Port" "$PORT"
    crudini --set "$GAMEFILES_DIR/system/$INI_CFG" "IpDrv.UdpBeacon" "ServerBeaconPort" "$SERVER_BEACON_PORT"
    crudini --set "$GAMEFILES_DIR/system/$INI_CFG" "IpDrv.UdpBeacon" "BeaconPort" "$BEACON_PORT"
fi

if [ ! -z "$GAME_PRESET" ]; then
    case "$GAME_PRESET" in
        "ADVERSARIAL")
            echo "Setting up server for adversarial mode"
            # Set adversarial preset values
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "MaxPlayers" "16"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "NbTerro" "0"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "RoundTime" "240"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "BetweenRoundTime" "45"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "BombTime" "45"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamFirstPerson" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamThirdPerson" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamFreeThirdP" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamGhost" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamFadeToBlack" "False"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamTeamOnly" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "FriendlyFire" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "Autobalance" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "TeamKillerPenalty" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "AllowRadar" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "RoundsPerMatch" "10"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "ForceFPersonWeapon" "True"

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
                    crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6MapList" "Maps[$i]" "${maps[$i]}"
                    crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6MapList" "GameType[$i]" "${gametypes[$i]}"
                fi
            done
            ;;
        "COOP")
            echo "Setting up server for cooperative mode"
            # Set cooperative preset values
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "MaxPlayers" "8"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "NbTerro" "20"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "RoundTime" "600"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "BetweenRoundTime" "30"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "BombTime" "300"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamFirstPerson" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamThirdPerson" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamFreeThirdP" "False"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamGhost" "False"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamFadeToBlack" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamTeamOnly" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "FriendlyFire" "False"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "Autobalance" "False"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "TeamKillerPenalty" "False"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "AllowRadar" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "RoundsPerMatch" "1"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "ForceFPersonWeapon" "False"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "AIBkp" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "DiffLevel" "2"

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
                    crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6MapList" "Maps[$i]" "${maps[$i]}"
                    crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6MapList" "GameType[$i]" "${gametypes[$i]}" 
                fi                               
            done
            ;;
        "DEATHMATCH")
            echo "Setting up server for deathmatch mode"
            # Set deathmatch preset values
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "MaxPlayers" "16"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "NbTerro" "0"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "RoundTime" "240"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "BetweenRoundTime" "45"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "BombTime" "45"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamFirstPerson" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamThirdPerson" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamFreeThirdP" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamGhost" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamFadeToBlack" "False"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamTeamOnly" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "FriendlyFire" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "Autobalance" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "TeamKillerPenalty" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "AllowRadar" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "RoundsPerMatch" "10"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "ForceFPersonWeapon" "True"

            declare -A maps=([0]="Airport" [1]="Alpines" [2]="Bank" [3]="Garage" [4]="Import_Export" 
                           [5]="Island_Dawn" [6]="MeatPacking" [7]="Mountain_High" [8]="Oil_Refinery"
                           [9]="Parade" [10]="Peaks" [11]="Penthouse" [12]="Presidio" [13]="Prison"
                           [14]="Shipyard" [15]="Streets" [16]="Training" [17]="Warehouse")

            for i in {0..31}; do
                if [ ! -z "${maps[$i]}" ]; then
                    crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6MapList" "Maps[$i]" "${maps[$i]}"
                    crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6MapList" "GameType[$i]" "R6Game.R6DeathMatch"
                fi
            done
            ;;
        "TEAMDEATHMATCH")
            echo "Setting up server for team deathmatch mode"
            # Set team deathmatch preset values
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "MaxPlayers" "16"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "NbTerro" "0"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "RoundTime" "240"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "BetweenRoundTime" "45"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "BombTime" "45"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamFirstPerson" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamThirdPerson" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamFreeThirdP" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamGhost" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamFadeToBlack" "False"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamTeamOnly" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "FriendlyFire" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "Autobalance" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "TeamKillerPenalty" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "AllowRadar" "True"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "RoundsPerMatch" "10"
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "ForceFPersonWeapon" "True"

            declare -A maps=([0]="Airport" [1]="Alpines" [2]="Bank" [3]="Garage" [4]="Import_Export" 
                           [5]="Island_Dawn" [6]="MeatPacking" [7]="Mountain_High" [8]="Oil_Refinery"
                           [9]="Parade" [10]="Peaks" [11]="Penthouse" [12]="Presidio" [13]="Prison"
                           [14]="Shipyard" [15]="Streets" [16]="Training" [17]="Warehouse")

            for i in {0..31}; do
                if [ ! -z "${maps[$i]}" ]; then
                    crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6MapList" "Maps[$i]" "${maps[$i]}"
                    crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6MapList" "GameType[$i]" "R6Game.R6TeamDeathMatchGame"
                fi
            done
            ;;
        *)
            echo "ERROR: Invalid game preset '$GAME_PRESET'. Valid options are 'ADVERSARIAL', 'COOP', 'DEATHMATCH', or 'TEAMDEATHMATCH'."
            exit 1
            ;;
    esac
fi

# Set common server.ini values from environment variables with proper naming
[ ! -z "$NAME" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "ServerName" "$NAME"
[ ! -z "$MOTD" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "MOTD" "$MOTD"
[ ! -z "$MAX_PLAYERS" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "MaxPlayers" "$MAX_PLAYERS"
[ ! -z "$ROUND_TIME" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "RoundTime" "$ROUND_TIME"
[ ! -z "$BETWEEN_ROUND_TIME" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "BetweenRoundTime" "$BETWEEN_ROUND_TIME"
[ ! -z "$ROUNDS_PER_MATCH" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "RoundsPerMatch" "$ROUNDS_PER_MATCH"
[ ! -z "$ROTATE_MAP" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "RotateMap" "$ROTATE_MAP"
[ ! -z "$ADMIN_PASSWORD" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "AdminPassword" "$ADMIN_PASSWORD"
[ ! -z "$GAME_PASSWORD" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "GamePassword" "$GAME_PASSWORD"
[ ! -z "$FRIENDLY_FIRE" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "FriendlyFire" "$FRIENDLY_FIRE"
[ ! -z "$FORCE_FIRST_PERSON" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "ForceFPersonWeapon" "$FORCE_FIRST_PERSON"
[ ! -z "$CAM_THIRD_PERSON" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamThirdPerson" "$CAM_THIRD_PERSON"
[ ! -z "$CAM_TEAM_ONLY" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamTeamOnly" "$CAM_TEAM_ONLY"
[ ! -z "$NUM_TERRORISTS" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "NbTerro" "$NUM_TERRORISTS"
[ ! -z "$DIFFICULTY_LEVEL" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "DiffLevel" "$DIFFICULTY_LEVEL"
[ ! -z "$AI_BACKUP" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "AIBkp" "$AI_BACKUP"
[ ! -z "$BOMB_TIME" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "BombTime" "$BOMB_TIME"
[ ! -z "$CAM_FIRST_PERSON" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamFirstPerson" "$CAM_FIRST_PERSON"
[ ! -z "$CAM_FREE_THIRD_P" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamFreeThirdP" "$CAM_FREE_THIRD_P"
[ ! -z "$CAM_GHOST" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamGhost" "$CAM_GHOST"
[ ! -z "$CAM_FADE_TO_BLACK" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "CamFadeToBlack" "$CAM_FADE_TO_BLACK"
[ ! -z "$ALLOW_ARM_PATCH" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "AllowArmPatch" "$ALLOW_ARM_PATCH"
[ ! -z "$LOUD_FOOT" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "LoudFoot" "$LOUD_FOOT"
[ ! -z "$SHOW_NAMES" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "ShowNames" "$SHOW_NAMES"
[ ! -z "$INTERNET_SERVER" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "InternetServer" "$INTERNET_SERVER"
[ ! -z "$AUTOBALANCE" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "Autobalance" "$AUTOBALANCE"
[ ! -z "$TEAM_KILLER_PENALTY" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "TeamKillerPenalty" "$TEAM_KILLER_PENALTY"
[ ! -z "$ALLOW_RADAR" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "AllowRadar" "$ALLOW_RADAR"
[ ! -z "$USE_ADMIN_PASSWORD" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "UseAdminPassword" "$USE_ADMIN_PASSWORD"
[ ! -z "$DEDICATED_SERVER" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "DedicatedServer" "$DEDICATED_SERVER"
[ ! -z "$SPAM_THRESHOLD" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "SpamThreshold" "$SPAM_THRESHOLD"
[ ! -z "$CHAT_LOCK_DURATION" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "ChatLockDuration" "$CHAT_LOCK_DURATION"
[ ! -z "$VOTE_BROADCAST_MAX_FREQUENCY" ] && crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6ServerInfo" "VoteBroadcastMaxFrequency" "$VOTE_BROADCAST_MAX_FREQUENCY"

# Process MAP_0 through MAP_31 environment variables
for i in {0..31}; do
    map_var="MAP_${i}"
    gametype_var="GAMETYPE_${i}"
    
    if [ ! -z "${!map_var}" ]; then
        crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6MapList" "Maps[$i]" "${!map_var}"
        
        # Set game type if specified, validate it first
        if [ ! -z "${!gametype_var}" ]; then
            if validate_gametype "${!gametype_var}"; then
                crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6MapList" "GameType[$i]" "${!gametype_var}"
            else
                echo "Error: Invalid game type '${!gametype_var}' for map '${!map_var}'."
                exit 1
            fi
        else
            # Default to TDM if no game type specified
            crudini --set "$GAMEFILES_DIR/system/$SERVER_CFG" "Engine.R6MapList" "GameType[$i]" "R6Game.R6TeamDeathMatchGame"
        fi
    fi
done

# Update INI files using the dedicated script
/update_ini.sh "SERVER_" "$GAMEFILES_DIR/system/$SERVER_CFG"
/update_ini.sh "RAVENSHIELD_" "$GAMEFILES_DIR/system/$INI_CFG"
/update_ini.sh "OPENRVS_" "$GAMEFILES_DIR/system/openrvs.ini"

# Define the pattern with wildcards (e.g. "*OpenRVS is up to date*")
OPENRVS_UPTODATE_PATTERN="${OPENRVS_UPTODATE_PATTERN:-*OpenRVS is up to date*}"

# Convert shell wildcards to regex
OPENRVS_UPTODATE_REGEX="^${OPENRVS_UPTODATE_PATTERN//\*/.*}$"

# Registration interval in seconds (default 3600 = 60 minutes)
OPENRVS_REGISTRATION_INTERVAL="${OPENRVS_REGISTRATION_INTERVAL:-3600}"

register_with_openrvs() {
    # Use PUBLIC_IP if provided, otherwise determine current public IP
    local ip port
    if [ -n "$PUBLIC_IP" ]; then
        ip="$PUBLIC_IP"
    else
        ip=$(curl -s https://api.ipify.org || true)
    fi
    if [ -z "$ip" ]; then
        echo "Warning: Could not determine public IP address for OpenRVS registration."
        return 1
    fi
    port="$PORT"
    if [ -z "$port" ]; then
        port=$(crudini --get "$GAMEFILES_DIR/system/$INI_CFG" "URL" "Port")
    fi
    if [ -z "$port" ]; then
        echo "Warning: Could not determine server port for OpenRVS registration."
        return 1
    fi
    local address="${ip}:${port}"

    # Only register if IP has changed
    if [ "$ip" != "$LAST_OPENRVS_IP" ]; then
        echo "Registering server with OpenRVS: $address"
        curl -s -o - -X POST https://openrvs.org/servers/add -d "$address"
        echo "Server registered with OpenRVS: $address"
        export LAST_OPENRVS_IP="$ip"
    else
        echo "OpenRVS registration skipped (IP unchanged: $ip)"
    fi
}

# Start the RavenShield server and optionally register with OpenRVS once it's up
cd $GAMEFILES_DIR/system
OPENRVS_REGISTERED=0
wine UCC.exe server -ini="$INI_CFG" -serverini="$SERVER_CFG" -log 2>&1 | while read -r line; do
    echo "$line"

    if [[ "${OPENRVS_MANUAL_REGISTRATION,,}" == "true" ]] && [[ "${INTERNET_SERVER,,}" == "true" ]]; then
        if [[ "$line" =~ $OPENRVS_UPTODATE_REGEX ]] && [[ "$OPENRVS_REGISTERED" -eq 0 ]]; then
            # Register immediately
            register_with_openrvs

            # Start background registration loop if not already running
            if [ -z "$OPENRVS_REGISTRATION_LOOP_STARTED" ]; then
                export OPENRVS_REGISTRATION_LOOP_STARTED=1
                (
                    while true; do
                        sleep "$OPENRVS_REGISTRATION_INTERVAL"
                        register_with_openrvs
                    done
                ) &
            fi
            OPENRVS_REGISTERED=1
        fi
    fi
done