#!/bin/bash
godot4 --headless --export-release "Web" web_build/index.html
# Need preserveDrawingBuffer on the MAIN canvas
sed -i 's/canvas.getContext("webgl2", {/canvas.getContext("webgl2", {preserveDrawingBuffer: true, /' web_build/index.js
sed -i 's/canvas.getContext("webgl", {/canvas.getContext("webgl", {preserveDrawingBuffer: true, /' web_build/index.js
