#!/usr/bin/env bash

# Usage Guide 

# This particular script is intended for .m4a recordings on Mac. 
# Make sure you have ffmpeg installed (install via brew if you dont :/ )

# Drop this script into your intended audio folder
# Open terminal and run sudo process_audio.sh chmod +x to grant execution permission
# Run the script via ./process_audio.sh


set -euo pipefail

shopt -s nullglob

for input in *.m4a *.M4A; do
    output="${input%.*}.mp3"

    if [[ -f "$output" ]]; then
        echo "Skipping '$input' (output already exists)."
        continue
    fi

    echo "Converting '$input' -> '$output'"

    ffmpeg -hide_banner -loglevel error \
        -i "$input" \
        -codec:a libmp3lame \
        -q:a 0 \
        -map_metadata 0 \
        "$output"
done

echo "Done."
