FROM alpine:3.17

ARG micro_plugin_list="detectindent manipulator quoter wc"

ENV TINI_KILL_PROCESS_GROUP=1
ENV MICRO_CONFIG_HOME=/config

EXPOSE 7681

RUN apk add --no-cache \
        tini=0.19.0-r1 \
        ttyd=1.7.2-r0 \
        micro=2.0.11-r6 && \
    micro -plugin install $micro_plugin_list; \
    micro -plugin update; \
    mkdir /data

COPY config config/

WORKDIR /data

ENTRYPOINT ["/sbin/tini", "--", "ttyd", "-s", "3", "--url-arg", "-t", "rendererType=webgl", "-t", "disableLeaveAlert=true", "-t", "disableResizeOverlay=true", "-t", "disableReconnect=true"]

CMD [ "-t", "titleFixed=Microw", "-t", "fontSize=18", "micro" ]
