FROM ubuntu:24.04
FROM jlesage/baseimage-gui:ubuntu-22.04-v4 AS builder
FROM jlesage/baseimage-gui:ubuntu-24.04-v4.6.7
FROM alpine:3.14


RUN apk --no-cache add build-base linux-head
RUN \
    add-pkg \
        # WebGL support.
        mesa-dri-gallium \
        # Audio support.
        libpulse \
        # Icons used by folder/file selection window (when saving as).
        adwaita-icon-theme \
        # A font is needed.
        font-dejavu \
        # The following package is used to send key presses to the X process.
        xdotool \
        && \
    # Remove unneeded icons.
    find /usr/share/icons/Adwaita -type d -mindepth 1 -maxdepth 1 -not -name 16x16 -not -name scalable -exec rm -rf {} ';' && \
    true


# Generate and install favicons.
ARG LOCALE="en-US"RUN \
    


ENV WATERFOX_ICON_URL="https://github.com/GitXpresso/docker-waterfox/blob/master/waterfox-icon.png"
RUN install_app_icon.sh "${WATERFOX_ICON_URL}"

### Final image
FROM jlesage/baseimage-gui:ubuntu-22.04-v4

ENV APP_NAME="Waterfox"

ENV show_output=1

ARG DEBIAN_FRONTEND="noninteractive"
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    file \
    libdbus-glib-1-2 \
    libgtk-3-0 \
    libx11-xcb1 \
    libxt6 \
    libasound2 \
  && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/noVNC/app/images/icons/* /opt/noVNC/app/images/icons/
COPY --from=builder /opt/noVNC/index.html /opt/noVNC/index.htm

LABEL AboutImage "Waterfox"

LABEL Maintainer "William . gitxpresso@duck.com"

#VNC Server Password
ENV	VNC_PASS= \
#VNC Server Title(w/o spaces)
	VNC_TITLE="Waterfox" \
#VNC Resolution(720p is preferable)
	VNC_RESOLUTION="1280x720" \
#VNC Shared Mode
	VNC_SHARED=false \
#Local Display Server Port
	DISPLAY=:0 \
#NoVNC Port
	NOVNC_PORT=$PORT \
	PORT=5900 \
#Locale
	LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8 \
	LC_ALL=C.UTF-8 \
	TZ="America/NYC

COPY assets/ /

RUN	sudo apt update && \
        curl https://raw.githubusercontent.com/gitxpresso/docker-waterfox/refs/heads/mastet/waterfox.sh | bash && \
	sudo apt install tzdata ca-certificates supervisor curl wget openssl bash python3 py3-requests sed unzip xvfb x11vnc websockify openbox firefox nss alsa-lib font-noto font-noto-cjk && \
# noVNC SSL certificate
	openssl req -new -newkey rsa:4096 -days 36500 -nodes -x509 -keyout /etc/ssl/novnc.key -out /etc/ssl/novnc.cert > /dev/null 2>&1 && \
# TimeZone
	cp /usr/share/zoneinfo/$TZ /etc/localtime && \
	echo $TZ > /etc/timezone && \
# Wipe Temp Files
	apk del build-base curl wget unzip tzdata openssl && \
	rm -rf /var/cache/apk/* /tmp/*
ENTRYPOINT ["supervisord", "-l", "/var/log/supervisord.log", "-c"]

CMD ["/config/supervisord.conf"]
