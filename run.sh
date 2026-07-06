#!/bin/bash

echo "🎮 Compiling Willow..."
pdc source Willow.pdx

echo "🚀 Launching Playdate Simulator..."
# On macOS, the 'open' command automatically routes .pdx files to the Playdate Simulator!
open Willow.pdx
