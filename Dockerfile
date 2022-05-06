FROM alpine:3.15

ARG micro_plugin_list="detectindent manipulator quoter wc"

ENV TINI_KILL_PROCESS_GROUP=1
ENV MICRO_CONFIG_HOME=/config

EXPOSE 7681

RUN apk add --no-cache \
        tini=0.19.0-r0 \
        ttyd=1.6.3-r3 \
        micro=2.0.10-r4 && \
    micro -plugin install $micro_plugin_list; \
    micro -plugin update

COPY config config/

ENTRYPOINT ["/sbin/tini", "--", "ttyd", "-s", "3", "--url-arg", "-t", "rendererType=webgl", "-t", "disableLeaveAlert=true", "-t", "disableResizeOverlay=true", "-t", "disableReconnect=true"]

CMD [ "-t", "titleFixed=Microw", "-t", "fontSize=18", "micro" ]
