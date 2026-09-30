#!/bin/bash

if [ "$1" == "-h" ]
then
    echo "\$1 is Video URL or File Path, \$2 is starting timecode, \$3 is length of gif"
    echo "run with -c for manual cleanup"
    exit
fi

if [ "$1" == "-c" ]
then
    echo "manual cleanup"
    rm -f /tmp/videotogif/*
    exit
fi

trimmed=${1##*/}

if [ ! -d /tmp/videotogif ]
then
    mkdir /tmp/videotogif
fi

echo $trimmed

if [ -f "/tmp/videotogif/$trimmed.mp4" ]
then
	echo "not cleaning up, retrying cut"
else
	echo "cleaning up tmpdir"
	rm -f /tmp/videotogif/*
fi

if [ ! -f "$1" ]
then
    echo "input is a URL, downloading with yt-dlp"
    if [ -f "/tmp/videotogif/$trimmed.mp4" ]
    then
	    echo "retrying cut detected, skipping download"
    else
        yt-dlp -t mp4 $1 -S "res:1080,+size" --force-overwrites -P /tmp/videotogif/ -o "$trimmed.mp4"
    fi
else
    echo "input is a file, copying to tmp"
    cp ./"$1" /tmp/videotogif/temp-video.mp4
fi

seconds=$(date -d "1970-01-01 $2 Z" +%s.%3N)

echo $seconds

ffmpeg -y -ss $seconds -t $3 -i "/tmp/videotogif/$trimmed.mp4" -vf "fps=20,scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 /tmp/videotogif/temp.gif

cp -f /tmp/videotogif/temp.gif ./output.gif

#rm /tmp/videotogif/*
