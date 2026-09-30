#!/bin/bash

if [ "$1" == "-h" ]
then
    echo "\$1 is Video URL or File Path, \$2 is starting timecode, \$3 is length of gif"
    exit
fi

if [ ! -d /tmp/videotogif ]
then
    mkdir /tmp/videotogif
fi


if [ ! -f "$1" ]
then
    echo "input is a URL, downloading with yt-dlp"
    yt-dlp --format mp4 $1 --force-overwrites -P /tmp/videotogif/ -o "temp-video.mp4"
else
    echo "input is a file, copying to tmp"
    cp ./"$1" /tmp/videotogif/temp-video.mp4
fi

seconds=$(date -d "1970-01-01 $2 Z" +%s.%3N)

echo $seconds

ffmpeg -y -ss $seconds -t $3 -i /tmp/videotogif/temp-video.mp4 -vf "fps=20,scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 /tmp/videotogif/temp.gif

cp -f /tmp/videotogif/temp.gif ./output.gif

rm /tmp/videotogif/*
