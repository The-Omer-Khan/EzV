#!/bin/bash


# Usage Guide 

# This particular script is intended for .mov recordings on Mac. 
# I found it a pain in the ass to keep processing videos to save space so I wrote this. 

# Make sure you have ffmpeg installed (install via brew if you dont :/ )

# Drop this script into your intended video folder
# Open terminal and run sudo process_video.sh chmod +x to grant execution permission
# Run the script via ./process_video.sh
# Wait while it converts your .mov videos into mp4 

# Exit if ffmpeg is not installed
if ! command -v ffmpeg &> /dev/null
then
    echo "WHERE IS FFMPEG DAWG, READ THE GOT DAMN INSTRUCTIONS"
    exit 1
fi

 echo "SO YOU GOT FFMPEG HUH?"

# Loop through all .mov files
for file in *.mov; do
    # Skip if no .mov files found
    [ -e "$file" ] || continue

    # Extract filename without extension
    filename="${file%.*}"

    echo "Converting '$file' → '${filename}.mp4'"


    # Adjust this however you want smartass
    ffmpeg -i "$file" \
        -vf "scale=-2:1080" \
        -c:v libx264 \
        -preset slow \
        -crf 23 \
        -c:a aac \
        -b:a 192k \
        "${filename}.mp4"
done

echo "All conversions completed. You're Welcome."
