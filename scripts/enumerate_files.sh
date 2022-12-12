#!/usr/bin/env bash

shopt -s extglob

# Query directory struct and dump it all into `files`.
files=$(ls --group-directories-first)

IFS='\''
# Grab all of our files and setup html.
for file in $files; do
    if [[ -d $file ]]; then
        echo $file
    else
        echo $file
        continue
        read -a line <<< $(ls $file --human-readable --format verbose) 
        # '-rw-r--r--' '1'
        permission=${line[0]} && file_descriptor=${line[1]}
        # 'johnny' 3: 'johnny' 
        owner="${line[2]}" && group="${line[3]}" 
        # '3.1K'
        file_size="${line[4]}"
        # 'Sep' 6: '27'; 7: '14:30'
        date="${line[5]} ${line[6]} ${line[7]}"
        # 'creators.scss'
        file_name="${line[8]}"

        echo $file_name
    fi
done
