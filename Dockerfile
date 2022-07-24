ARG STEAM_LINK="https://aur.archlinux.org/cgit/aur.git/snapshot/steamcmd.tar.gz"
ARG STEAM_PACKAGE_NAME="steamcmd.pkg.tar.zst"
ARG STEAM_PACKAGE_PATH="/artifacts/$STEAM_PACKAGE_NAME"

FROM archlinux:base-devel AS devel

ARG STEAM_LINK
ARG STEAM_PACKAGE_PATH

RUN printf "nobody   ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    pacman -Sy --noconfirm && \    
    mkdir -p /artifacts && \    
    chown -R nobody /artifacts && \
    cd /artifacts && \
    sudo -u nobody curl ${STEAM_LINK} --output steamcmd.tar.gz && \
    sudo -u nobody tar -xvpf steamcmd.tar.gz && \
    cd steamcmd && \
    sudo -u nobody makepkg --noconfirm -rcCs && \
    sudo -u nobody mv $(ls *pkg.tar.zst) $STEAM_PACKAGE_PATH



FROM archlinux:latest

ARG STEAM_PACKAGE_PATH

COPY --from=devel $STEAM_PACKAGE_PATH  $STEAM_PACKAGE_PATH

RUN useradd -u 1000 -m steamcmd && \
    mkdir -p /{runtime,worlds} && \
    chown steamcmd:nobody /{runtime,worlds} &&\
    cd /home/steamcmd && \
    printf "[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf && \
    pacman -Sy wine xorg-server-xvfb cabextract --noconfirm && \    
    pacman -U $STEAM_PACKAGE_PATH --noconfirm && \
    rm $STEAM_PACKAGE_PATH && \
    curl  https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -o /usr/local/bin/winetricks && \
    chmod +x /usr/local/bin/winetricks

COPY entrypoint.sh /usr/local/bin
WORKDIR /home/steamcmd
VOLUME ["/runtime", "/worlds"]
USER steamcmd
ENTRYPOINT [ "entrypoint.sh" ]