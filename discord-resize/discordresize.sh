]#!/bin/bash
audstream_offsetzero=0
audstream_offsetone=0
streamcount=0

unset auddelay
target_video_size_MB="20"


fetch_seconds_mkv () {
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 file:"$1"
}

fetch_seconds_mp4 () {
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 file:"$1"
}

if [[ $1 == *.mp4 ]]
then
    origin_duration_s=$(fetch_seconds_mp4 $1)
    echo $origin_duration_s
elif [[ $1 == *.mov ]]
then
    origin_duration_s=$(fetch_seconds_mp4 $1)
elif [[ $1 == *.mkv ]]
then
    origin_duration_s=$(fetch_seconds_mkv $1)
else
    echo "unsupported filetype"
fi


#num_vidstreams=$(ffprobe -v error -select_streams v -show_entries stream=index -of csv=p=0 "$1" | wc -w)
num_audstreams=$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 file:"$1" | wc -w)

num_audstreams="$(($num_audstreams-1))"
#echo $num_audstreams

for ((c=0; c <= num_audstreams; ++c))
do
    checkvar=$(ffprobe -v error -hide_banner -show_entries stream=start_time -select_streams a:$c file:"$1" | grep -oP 'start_time=.{0,10}' | sed 's/^.*=//')
    auddelay+=("$checkvar")
done



for i in "${auddelay[@]}"
do
    echo "$i"
    ffmpeg -i file:"$1" -map 0:a:$streamcount stream$streamcount.opus
    ((streamcount++))

done

origin_audio_bitrate_kbit_s=128
target_audio_bitrate_kbit_s=$origin_audio_bitrate_kbit_s # TODO for now, make audio bitrate the same
target_video_bitrate_kbit_s=$(awk -v size="$target_video_size_MB" -v duration="$origin_duration_s" -v audio_rate="$target_audio_bitrate_kbit_s" 'BEGIN { print  ( ( size * 8388.608 ) / ( 1.048576 * duration ) - audio_rate ) }')

ffmpeg -y -i file:"$1" -map 0:v -c:v libx265 -b:v "$target_video_bitrate_kbit_s"k -pass 1 -c:a aac -b:a "$target_audio_bitrate_kbit_s"k -f mp4 /dev/null \
&& \
ffmpeg -y -i file:"$1" -map 0:v -c:v libx265 -b:v "$target_video_bitrate_kbit_s"k -pass 2 -c:a aac -b:a "$target_audio_bitrate_kbit_s"k file:"${1%.*}-24MB-noaudio.mp4"

if [[ $(ls -1q stream*.opus | wc -l) == 1 ]]
then
    echo "Only 1 Audio Track"
    mv stream0.opus output.opus
elif [[ $(ls -1q stream*.opus | wc -l) == 2 ]]
then
    ffmpeg -y -i "stream0.opus" -i "stream1.opus" -filter_complex amix=inputs=2:duration=first:dropout_transition=3 output.opus
fi

ffmpeg -y -i file:"${1%.*}-24MB-noaudio.mp4" -i output.opus -c copy -map 0:v:0 -map 1:a:0 file:"${1%.*}-24MB.mp4"

rm "${1%.*}-24MB-noaudio.mp4"
rm stream*.opus
rm output.opus
rm ffmpeg2pass-0.log
rm ffmpeg2pass-0.log.mbtree
rm ffmpeg2pass-0.log.cutree

