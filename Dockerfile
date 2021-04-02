FROM tarantool/tarantool:2.3.1
COPY /home/rhernandez/lucy/prj/dev/watcher /opt/tarantool/watcher
CMD ["sh"]