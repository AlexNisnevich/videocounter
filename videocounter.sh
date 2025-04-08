#!/bin/bash

# Requirements:
#       brew install jq mediainfo
# IF handling RED camera files (*.r3d), download REDCINE: https://www.red.com/download/redcine-x-pro-mac

# Usage:
#       videocounter.sh [path of root directory to traverse]

#set -evx
shopt -s nocasematch

print_total_duration_of_directory () {
    total_seconds=0
    width=0
    height=0

    while read filepath; do
        if [[ $(file --mime-type -b "$filepath" | grep video) ]] || [[ "$filepath" == *.mp4 ]] || [[ "$filepath" == *.mxf ]] || [[ "$filepath" == *.braw ]]; then
            duration=$(mediainfo --Output=JSON "$filepath" | jq -r .media.track.[0].Duration)
            total_seconds=$(echo "$duration+$total_seconds"|bc)

            if [[ "$width" == "0" ]]; then 
                width=$(mediainfo --Output=JSON "$filepath" | jq -r '.media.track[] | select(.["@type"]=="Video").Width')
                height=$(mediainfo --Output=JSON "$filepath" | jq -r '.media.track[] | select(.["@type"]=="Video").Height')
            fi
        elif [[ "$filepath" == *.r3d ]]; then
            fps=$(REDline -i "$filepath" --useMeta --printMeta 1 | grep FPS -m 1 | cut -f2)
            frames=$(REDline -i "$filepath" --useMeta --printMeta 1 | grep "Total Frames" -m 1 | cut -f2)
            duration=$(bc <<< "$frames/$fps")
            total_seconds=$(echo "$duration+$total_seconds"|bc)

            if [[ "$width" == "0" ]]; then 
                width=$(REDline -i "$filepath" --useMeta --printMeta 1 | grep "Frame Width" -m 1 | cut -f2)
                height=$(REDline -i "$filepath" --useMeta --printMeta 1 | grep "Frame Height" -m 1 | cut -f2)
            fi
        fi
    done <<< "$(find "$1" -type f -maxdepth 1)"

    if (( $((${total_seconds%.*}+0)) > 0 )); then 
        h=$(bc <<< "$total_seconds/3600")
        m=$(bc <<< "($total_seconds%3600)/60")
        s=$(bc <<< "$total_seconds%60")
        printf "%s,%02d:%02d:%05.2f,%dx%d\n" "$1" $h $m $s $width $height
    fi
}

while read dirpath; do
    # echo $dirpath
    print_total_duration_of_directory "$dirpath"
done <<< "$(find "$1" -type d | sort)"
