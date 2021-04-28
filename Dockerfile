FROM tarantool/tarantool:2.3.1
COPY src/*.lua /opt/watcher/
COPY src/db/*.lua /opt/watcher/db/
COPY src/plugins/*.lua /opt/watcher/plugins/
COPY src/types/*.lua /opt/watcher/types/
COPY LICENSE /opt/watcher/
WORKDIR /opt/watcher/
CMD ["sh"]