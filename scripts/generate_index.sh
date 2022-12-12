#!/usr/bin/env bash

shopt -s extglob

# helper: logging shortcut function
[[ -z $LOG_PREFIX ]] && LOG_PREFIX=""
log()
{
    echo -e "${LOG_PREFIX}$1"
}

# helper: make sure we're where we're suppose to be.
cd "$(dirname ${BASH_SOURCE[0]})"

# helper: include all scripts from script dir for easy access
PATH+=":$(dirname $(realpath ${BASH_SOURCE[0]}))"

for i in ${@}; do
    # [-h] flag: dumps help message and exits
    if [[ "$i" = "-h" || "$i" == --h* ]]; then
        log "usage: ./generate_index [OPTION] USER"
        log "\t-f, --force: forces index generation regarless of changes."
        log "\t-s, --scan=shallow: only checks current dir."
        log "\t-d, --scan=deep: recursively checks current and subdirs."
        exit 0

    # [-h] flag: forces indexing regardless of last index time.
    elif [[ "$i" = "-f" || "$i" == "--force" ]]; then
        FORCE_INDEX=1
        NO_CRC=1

    # [-s] flag: shallow scan, only checks current directory.
    elif [[ "$i" == "-s" || "$i" == "--scan=shallow" ]]; then
        SCAN_REC_SHALLOW=1

    # [-d] flag: deep scan, recursively checks current and subdirectories.
    elif [[ "$i" == "-d" || "$i" == "--scan=deep" ]]; then
        SCAN_REC_SHALLOW=0
    fi
done

# <USER> arg: directly sets the username (optimizes recursive execution)
[[ -z ${BASH_ARGV} ||  "${BASH_ARGV:0:1}" == "-" ]] \
    && username="$(keybase whoami)" || username="$BASH_ARGV"


KB_PRIMARY_HOSTNAME="https://$username.keybase.pub"
KB_PRIMARY="$KB_PRIMARY_HOSTNAME"
KB_RESOURCES="$KB_PRIMARY/Resources"
KB_FALLBACK="https://keybase.pub/$username"
cwd="$(pwd)"
crc="$(ls -lI generate_index.sh -I index.html | md5sum)"
crc="${crc:0:32}"

www_path="$(basename "$cwd")"
if [[ "$www_path" = $username ]]; then
    www_path="Root Directory"
fi

# Detect HTTP path and basepath
if [[ "$cwd" =~ $username(.*)\/?$ ]]; then
    KB_PRIMARY="$KB_PRIMARY${BASH_REMATCH[1]}"
    KB_FALLBACK="$KB_FALLBACK${BASH_REMATCH[1]}"
else
    echo -e "${LOG_PREFIX}bad directory: $cwd\n"
    exit 1
fi

# Print directories with bold and underline
log "📂 \\033[1m$www_path\\033[0m"

if [[ -z "$NO_CRC" && -f "$cwd/index.html" ]]; then
    crc_index="$(grep -oh "md5sum \w*" "$cwd/index.html" | cut -c 8-)"
    [[ "$crc" = "$crc_index" ]] && no_save=1
fi


# Begin HTML
html=""
html+="<table>"
html+="<thead><tr>"
    html+="<th>Filename</th>"
    html+="<th>Size</th>"
    html+="<th>Description</th>"
html+="</tr></thead>"
summary="Files available: "

[[ -z $LOG_PREFIX ]] \
    && LOG_PREFIX="    " || LOG_PREFIX+="$LOG_PREFIX"

# Query directory struct and dump it all into `files`.
IFS2=$IFS; IFS=$'\n'
files=$(ls --group-directories-first | sed -e 's/ /<__SP>/g')
# TODO(John): Files with spaces are entirely missing.

html+="<tbody>"
# Grab all of our files and setup html.
REGULAR_FILE_ICONS="📒📓📔📕📗📘📙💌"
for str in $files; do
    IFS=$IFS2

    file="$(echo $str | sed -e 's/<__SP>/ /g')"
    read -a line <<< $(ls "$file" --human-readable --format verbose);

    # '-rw-r--r--' '1'
    permission=${line[0]} && file_descriptor=${line[1]}
    # 'johnny' 3: 'johnny' 
    owner="${line[2]}" && group="${line[3]}" 
    # '3.1K'
    file_size="${line[4]}"
    # 'Sep' 6: '27'; 7: '14:30'
    date="${line[5]} ${line[6]} ${line[7]}"

    [[ ! -d "$file" ]]; CLASSk_DIRECTORY=$?
    [[ ! -r "$file" ]]; CLASSk_REGULAR=$?

                                                                        ## index.scan: Filter out specific files
    [[ "$file" = "index.html"           \
    || "$file" = "sitemap.xml"          \
    || "$file" = "robots.txt"           \
    || "$file" = "generate_index.sh"    \
    || "$file" =~ footnote*             \
    ]] && continue

    [[ ! $CLASSk_REGULAR ]] && continue                                 ## index.scan: [pass] This isn't a directory or regular file.

    if [[ $CLASSk_DIRECTORY = 1 && $SCAN_REC_SHALLOW != 1 ]]; then                                ## index.scan: Recursively scan directories first.

        # index.scan_rec: Link generate_index for directories missing it. 
        if [[ ! -f "$file/generate_index.sh" && $FORCE_INDEX = 1 ]]; then
            ln -s "$(realpath $0)" "$file/generate_index.sh" 
        fi

        if [[ -f "$file/generate_index.sh" ]]; then
            # index.scan_rec: Execute index script

            cd "$file"

            LOG_PREFIX="$LOG_PREFIX" bash "generate_index.sh" "$@" "$username"
            # index.scan_rec: [fatal] Subprocess failed, bail out main tread!
            if [[ "$?" != "0" ]]; then
                log "\nRECURSIVE SCAN FAILED! Terminating main tread..."
                log "  \tDirectory: $file"
                log "  \tExit code: $?"

                exit 1
            fi

            cd ..
        fi
    fi


    entry=""
    entry_desc=""
    entry_prefix="🎁"
    entry_url="$KB_PRIMARY"

                                                                        ## index.scan: resolve file's URL to working path.
    if [[ -L "$file" ]]; then
        entry_url+="/"$(realpath --relative-to="$(dirname $file)" "$file")
    else
        entry_url+="/$file"
    fi

    entry_desc=""
    attrs=""
    a_attrs=""

    if [[ $no_save != 1 ]]; then
        entry_desc=$(file -bL "$file")
        attrs="title=\"$file ($file_size): $entry_desc\""
        a_attrs="href=\"$entry_url\""
    fi

    entry_file="$file"

    if [[ $CLASSk_DIRECTORY = 1 ]]; then                                       ## index.sweep: 📦 directory
        entry_prefix="📦"

        # Do not use fallback redir for markdown folders.
        [[ -f $file/index\.md ]] && continue

        # Use external indexer
        url="$KB_FALLBACK/$file"

        # Style these directories the same as recursive ones
        if [[ ! -f "$file/generate_index.sh" ]]; then
            log "📁 \\033[1m${file^}\\033[0m"
        fi

        entry_file+="/"
    else                                                                    ## index.sweep: 📓 regular file
        icon_i=$(($RANDOM % ${#REGULAR_FILE_ICONS}))
        entry_prefix=${REGULAR_FILE_ICONS:$icon_i:1}

        log "$entry_prefix \\033[2m$entry_file\\033[0m"
        summary+="$file ($file_size); "

    fi

    [[ $no_size = 1 ]] && continue

    command -v render_file_entry.sh &>/dev/null                 \
        && entry_file="$(render_file_entry.sh "$file")"         \
        || entry_file="<label>$entry_prefix $entry_file</label>"

    entry+="<td><a $a_attrs>$entry_file</a></td>"
    entry+="<td>$file_size</td>"
    entry+="<td>$entry_desc</td>"

    html+="<tr $attrs>$entry</tr>"
done

# Close the list
html+="</tbody>"                                                       
html+="</table>"                                                       
revised="$(date +'%A, %B %d, %Y, %R')"

if [[ $no_save = 1 ]]; then
    exit 0
fi


# Johnny 5/26: KB doesn't like this for some reason:
# <link rel=\"icon\" type=\"image/vnd.microsoft.icon;charset=binary\" sizes="16x16" href=\"$KB_RESOURCES/favicon.ico\">

                                                                    ## index.generate_page: Begin making the actual page.
html='''<!DOCTYPE html>
<html itemscope itemtype="https://schema.org/CollectionPage" lang="en">
<head>
'''"""
<title>$www_path • ${KB_PRIMARY_HOSTNAME:8}</title>

<!-- Identity -->
<link rel=\"manifest\" type=\"application/json\" href=\"/$KB_RESOURCES/app.webmanifest\">
<link rel=\"stylesheet\" type=\"text/css\" href=\"$KB_RESOURCES/style.min.css\" />

<!-- Icons -->
<link rel=\"icon\" type=\"image/png;charset=binary\" sizes="16x16" href=\"$KB_RESOURCES/favicon-16x16.png\">
<link rel=\"icon\" type=\"image/png;charset=binary\" sizes="32x32" href=\"$KB_RESOURCES/favicon-32x32.png\">
<link rel=\"icon\" type=\"image/png;charset=binary\" sizes="192x192" href=\"$KB_RESOURCES/android-chrome-192x192.png\">
<link rel=\"icon\" type=\"image/png;charset=binary\" sizes="512x512" href=\"$KB_RESOURCES/android-chrome-512x512.png\">
<link rel=\"apple-touch-icon\" type=\"image/png;charset=binary\" sizes="180x180" href=\"$KB_RESOURCES/apple-touch-icon.png\">
<link rel=\"mask-icon\" type=\"image/png;charset=binary\" href=\"$KB_RESOURCES/mask-icon.png\" color=\"#000000\">

<!-- A bunch of SEO stuff -->
<link rel=\"index\" title=\"Public files\" href=\"$KB_PRIMARY\" />
<meta name=\"description\" content=\"$summary\" />
<meta name=\"revised\" content=\"$revised\" />
<meta name=\"application-name\" content=\"${username^} Public Files\" />
<meta name=\"apple-mobile-web-app-title\" content=\"${username^} Public Files\" />
"""'''
<meta name="apple-mobile-web-app-status-bar-style" content="black">
<meta name="language" content="en" />
<meta name="robots" content="all" />
<meta name="X-Robots-Tag" content="all" />
<meta name="author" content="John Chandara" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />

<!-- Mobile stuff -->
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body>
'''"""
<header>
<div style=\"min-width: max-content\">
<h4><a href=\"/\">$username.keybase.pub</a></h4>
<h1><a href=\".\"><img src=\"/Resources/thumbnails/icons8-folder-48.png\" style=\"width: 42px; margin-right: .25rem; transform: translateY(10px)\"> $www_path</a></h1>
</div>
<div style=\"min-width: min(20cm, 100%);\">
<p>This directory listing serves as a directory to different files available within this folder, note that this is an automatically generated page using a bash script and is subject to ad-hoc change. This page was last updated on $revised, if you have any questions or concerns please email me at <a href=\"mailto:email@john.science\">email@john.science</a>.</p>
</div>
</header>
<main role=\"main\">$html</main>
</body>
</html>
"""

if [ -x "$(command -v html-minifier)" ]; then
    echo "${html}" | html-minifier          \
        --collapse-whitespace               \
        --remove-comments                   \
        --remove-optional-tags              \
        --remove-redundant-attributes       \
        --remove-script-type-attributes     \
        --remove-tag-whitespace             \
        --use-short-doctype > "$cwd/index.html"

else
    echo "${html}" > "$cwd/index.html"
fi 


echo "<!-- md5sum $crc -->" >> "$cwd/index.html"



if [[ $www_path = "Root Directory" ]]; then
    log "\n---------------------- style guide ----------------------"
    log "  \033[1mbold\\033[0m = directory;  \\033[9mcrossed-out\\033[0m = un-indexed file"
    log "\n---------------------------------------------------------"
fi
