#!/bin/sh
exec /usr/bin/env plackup -p 8080 \
    -Imodules/ax-jsonrpc/lib -Ilib -R=lib -R=etc etc/jsonrpc/app.psgi