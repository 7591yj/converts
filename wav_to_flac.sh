#!/bin/zsh

mkdir -p ./flac

for wav_file in *.wav; do
    base_name=$(basename "$wav_file" .wav)
    
    ffmpeg -i "$wav_file" "./flac/$base_name.flac"
done
