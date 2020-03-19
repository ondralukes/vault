#!/bin/bash
echo "/* eslint-disable */" > public/index-crypto-browserified.js
browserify -s cryptoTools public/index-crypto.js >> public/index-crypto-browserified.js
