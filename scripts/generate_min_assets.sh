#!/usr/bin/env bash

shopt -s extglob

cd "$(dirname ${BASH_SOURCE[0]})/.."

# clean-up old stuff.
rm *.min.css *.min.css.br

# minify everything
css-minify --dir . --output .

# compress everything
#brotli *.min.css
