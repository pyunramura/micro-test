FROM alpine:3.15

ARG micro=2.0.10
ARG micro-plugin-list="detectindent manipulator quoter wc"

ENV TINI_KILL_PROCESS_GROUP=1
ENV MICRO_CONFIG_HOME=/config

EXPOSE 7681

RUN [ ! -z ${TARGETPLATFORM+x} ] && \
        case $TARGETPLATFORM in \
              linux/amd64) echo "Building for x86_64." && platform="64-static";; \
              linux/386) echo "Building for x86." && platform="32";; \
              linux/arm64) echo "Building for arm64." && platform="-arm64";; \
              linux/arm/v7) echo "Building for armhf." && platform="-arm";; \
              *) echo -e "Unsupported platform.\nUse one of <platform>:\n\tlinux/amd64\n\tlinux/386\n\tlinux/arm64\n\tlinux/arm/v7\nin docker buildx build --platform <platform>,<platform>..." && exit 1;; \
        esac ; \
    apk add --no-cache \
        tini=0.19.0-r0 \
        ttyd=1.6.3-r2 && \
    mkdir /app && \
    wget -q -O - "https://github.com/zyedidia/micro/releases/download/v$micro/micro-$micro-linux${platform:-64-static}.tar.gz" | \
    tar xz --strip-components 1 micro-$micro/micro -C /app && \
    chown root:root /app/micro && \
    for plug in ${micro-plugin-list}; do \
        /app/micro -plugin install $plug; \
        done && \
    /app/micro -plugin update

COPY config config/

ENTRYPOINT ["/sbin/tini", "--"]

CMD [ "ttyd", "-s", "3", "--url-arg", "-t", "titleFixed=Microw", "-t", "rendererType=webgl", "-t", "disableLeaveAlert=true", "-t", "disableReconnect=true", "-t", "disableResizeOverlay=true", "-t", "fontSize=18", "/app/micro" ]
