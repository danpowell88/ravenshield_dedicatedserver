# RavenShield Dedicated Server

This Docker container sets up an environment to host the RavenShield Dedicated Server using Ubuntu, Wine, and Xvfb.

## Overview
- The container expects `/rvs` to contain the root of your game files (ie. `/system` `/mods` etc)
- Map the correct UDP ports that are specified in your game init files to be able to connect to the game server (usually `7777`, `8777`,`9777`)

Example command to run the server

```sh 
docker run -it --volume="C:\Ravenshield":/rvs -p:7777:7777/udp -p:8777:8777/udp -p:9777:9777/udp ghcr.io/danpowell88/ravenshield_dedicatedserver
```