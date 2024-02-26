ARG ENGINE_VERSION=5.7.0
FROM registry.gitlab.com/minetest/minetest/server:${ENGINE_VERSION}

USER root

RUN apk add --no-cache lua-dev luarocks &&\
    luarocks-5.1 install luacov &&\
    luarocks-5.1 install luacov-reporter-lcov

RUN apk add git &&\
    mkdir -p /root/.minetest/worlds/world/worldmods/ &&\
    git clone https://github.com/BuckarooBanzay/mtt /root/.minetest/worlds/world/worldmods/mtt &&\
    git clone https://github.com/mt-mods/wield_events /root/.minetest/worlds/world/worldmods/wield_events

ENTRYPOINT minetestserver --config /minetest.conf