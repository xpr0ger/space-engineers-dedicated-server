#!/bin/bash

# Fail entire script on error
set -e

# Directory where to store all downloaded runtime files
RUNTIME_DIR="/runtime"

# Lock wine files to not install every time when container starts
LOCK_FILE_WINE="${RUNTIME_DIR}/wine.lock"

# Space Engineers Dedicated Server home directory
SEDS_HOME_DIR="$RUNTIME_DIR/seds"
# Space Engiers Dedicated Server binary to launch
SEDS_BINARY="$SEDS_HOME_DIR/DedicatedServer64/SpaceEngineersDedicated.exe"

# Wine configuration
export WINEPREFIX="${RUNTIME_DIR}/pfx"
export WINEARCH="win64"
export WINEDEBUG=${WINEDEBUG="-all"}

# ENV Parameters
# How log wait after signal to server to shutdown
ENV_GRACEFUL_TIMEOUT="${ENV_GRACEFUL_TIMEOUT:=10}"
# Which IP server should listen to for new connection
ENV_LISTEN_TO_IP="${ENV_LISTEN_TO_IP:=0.0.0.0}"
# How to start application available values: -console and -noconsole
ENV_CONSOLE_TYPE="${ENV_CONSOLE_TYPE:=-console}"
# Which world to load from directory /worlds mandatory parameter
ENV_WORLD_NAME=$ENV_WORLD_NAME
# Refer to official documentation on -ignorelastsession parameter. 
ENV_IGNORE_LAST_SESSION="${ENV_IGNORE_LAST_SESSION:=true}"

if [ -z "${ENV_WORLD_NAME}" ]; then
echo "===> Environment variable ENV_WORLD_NAME is undefined exiting"
    exit 1;
fi

if [ ! -d "/worlds/${ENV_WORLD_NAME}" ]; then
    echo "===> Directory /worlds/${ENV_WORLD_NAME} with game word does not exists, exiting"
    exit 1;
fi

if [[ "${ENV_IGNORE_LAST_SESSION}" == 'true' ]]; then
    ENV_IGNORE_LAST_SESSION="-ignorelastsession"
else
    unset ENV_IGNORE_LAST_SESSION
fi

# Configure wine if needed
if [[ ! -f "$LOCK_FILE_WINE" ]]; then    
    echo "===> Starting fake display to install winetricks dependencies"    
    export DISPLAY=":5.0"
    Xvfb :5 -screen 0 1024x768x16 > /dev/null &    

    echo "===> Creating wine prefix in $WINEPREFIX"
    env WINEDLLOVERRIDES="mscoree=d" wineboot --init /nogui

    # See "requirements" section of https://www.spaceengineersgame.com/dedicated-servers/
    echo "===> Installing Visual C++ Redistributable package 2013"    
    winetricks -q vcrun2013

    # See "requirements" section of https://www.spaceengineersgame.com/dedicated-servers/
    echo "===> Installing Visual C++ Redistributable package 2017"    
    winetricks -q vcrun2017

    # See "requirements" section of https://www.spaceengineersgame.com/dedicated-servers/
    echo "===> Installing .NET Redistributable 4.8"    
    winetricks --force -q dotnet48

    echo "===> Stopping fake display"
    ps -au | grep Xvfb | grep -v grep | awk '{ print $2 }' | xargs -I{} kill -15 {}
    unset DISPLAY

    echo "===> Creating lock file for Wine $LOCK_FILE_WINE"
    touch "$LOCK_FILE_WINE"    
else
    echo "===> Wine configured"
fi


echo "===> Updating game files in direcotry $SEDS_HOME_DIR"
steamcmd +force_install_dir "$SEDS_HOME_DIR" +login anonymous +app_update 298740 +quit

# To trigger state save on the server stop we should send SIGINT to Space Engineers Dedicated Server not to wine process itself  
function _ProcessSigTerm() {
    echo "===> Recived SIGTERM"
    PID=$(ps -aux | grep -e "Z:.*SpaceEngineersDedicated\.exe" | grep -v grep | awk '{print $2}')
    echo "===> Sending SIGINT to process $PID"
    kill -s SIGINT "$PID"
    echo "===> Waiting for graceful shutdown $ENV_GRACEFUL_TIMEOUT second(s)"
    sleep $ENV_GRACEFUL_TIMEOUT
}

echo "===> Installing handler for SIGTERM signal"
trap _ProcessSigTerm SIGTERM

echo "===> Staring dedicated server using command 'wine $SEDS_BINARY $ENV_CONSOLE_TYPE -path Z:\\worlds\\${ENV_WORLD_NAME} -ip $ENV_LISTEN_TO_IP"
wine $SEDS_BINARY $ENV_IGNORE_LAST_SESSION $ENV_CONSOLE_TYPE -path "Z:\\worlds\\${ENV_WORLD_NAME}" -ip $ENV_LISTEN_TO_IP &

child=$!
wait "$child"
