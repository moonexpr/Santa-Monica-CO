#!/bin/bash

echo "Rendering flat stylesheets..."

python3 ./scripts/render_flat_stylesheet.py style.css > web.css
