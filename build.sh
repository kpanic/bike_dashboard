#!/usr/bin/env bash
set -o errexit

mix deps.get --only prod
MIX_ENV=prod mix compile

pushd assets
npm install leaflet
npm install leaflet-geosearch
popd

MIX_ENV=prod mix assets.build
MIX_ENV=prod mix assets.deploy


MIX_ENV=prod mix phx.gen.release
MIX_ENV=prod mix release --overwrite
