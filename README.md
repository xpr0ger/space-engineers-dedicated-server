# Space Engineers Dedicated ArchLinux Docker Container
Special thanks to [Devidian](https://github.com/Devidian/docker-spaceengineers), my work based on his repository.

# Key difference from Devidian's repository
1. Graceful shutdown of server to allow save world on close
2. Reduced image size in cost of container first start time
3. Different dependencies set which comply [requirements](https://www.spaceengineersgame.com/dedicated-servers/)
4. No automation for paths in config files

# How to use

## ENV Varibales

Name|Default|Description
---|---|---
WINEDEBUG|-all| Reffer to official documentation [documentation](https://wiki.winehq.org/Wine_User%27s_Guide#WINEDEBUG.3Dchannels)
ENV_GRACEFUL_TIMEOUT|10|How log wait after signal to server to shutdown, help to avoid termination in middle of saving process
ENV_LISTEN_TO_IP|0.0.0.0|Which IP server should listen to for new connection, value in `SpaceEngineers-Dedicated.cfg` is ignored
ENV_CONSOLE_TYPE|-console|How to start application, available values: `-console` and `-noconsole`
ENV_WORLD_NAME||Which world to load from directory `/worlds` mandatory parameter
ENV_IGNORE_LAST_SESSION|true|Refer to official [pdocumentation](https://www.spaceengineersgame.com/dedicated-servers/) on -ignorelastsession parameter. 

## Creating world

1. Use `Space Engineers Dedicated Server` tool which available on Steam to generate and configure new world and its settings.

2. Save save configured world

2. Upload world directory to `/worlds`.


## Updating paths in config

Due to fact world is generating on different computer you have to fix all paths in config files of the world directory before starting server. You have to check next files:

* `SpaceEngineers-Dedicated.cfg`
* `<WORLD_DIRECTORY>Saves\LastSession.sbl` in case it exists


Open for edit  and fix all paths prefixes ins next way:
For example if you have path `C:\Program Files\SpaceEngineersDedicated\World Directory\Saves\Your World Name` you should fix it in next way: `Z:\worlds\World Directory\Saves\Your World Name`.

## Using docker-compose with premade docker image

Create a `docker-compose.yml` (see example below) and execute `docker-compose up -d`

Do not forget to rename `TestInstance` with your instance name!

### example composer file (just copy and adjust)

```yaml
version: "3.8"

services:
  se-server:
    image: xpr0ger/space-engineers-dedicated-server:latest
    # if you want to run multiple servers you will have to change container_name and published ports
    container_name: se-ds-docker
    restart: unless-stopped
    volumes:
      # left side: your docker-host machine
      # right side: the paths in the image (!!do not change!!)
      - <path to worlds directory on host PC>:/worlds
      # Optional      
      - <path to runtime files>:/runtime      
    ports:
      - target: 8080
        published: 8080
        protocol: tcp
        mode: host
      - target: 27016
        published: 27016
        protocol: udp
        mode: host
    environment:      
      # change TestInstance to your instance name
      - ENV_WORLD_NAME=TestWorld
      # Do not change if you are not sure what you are doing
      - ENV_IGNORE_LAST_SESSION=false
```
## Can i run mods?

Yes as they are saved in your world, the server will download them on the first start.

# Known issues

- **VRage Remote Client**
  - I personally could not manage to connect with te remote client
- **Error: No IP assigned.**
  - Should be fixed by keen [see this issue](https://github.com/KeenSoftwareHouse/SpaceEngineers/issues/611)
