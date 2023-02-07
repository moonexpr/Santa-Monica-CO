#!/usr/bin/env bash

if [[ ${#@} < 1 ]]; then
    echo "usage: $0 <filename>"
    exit 1
fi


################################################################################

## RESOURCE_PATH="/Resources/thumbnails/"
RESOURCE_PATH="https://github.com/wholesome-wiz/Santa-Monica-CO/raw/main/thumbnails/"

DEFAULT="icons8-file-48.png"

ICO_AUDIO="icons8-audio-48.png"
ICO_TYPE="icons8-alpha-48.png"
ICO_ZIP="icons8-archive-folder-48.png"
ICO_COMPONENT="icons8-blockchain-technology-48.png"
ICO_CODE="icons8-code-file-48.png"
ICO_CONSOLE="icons8-console-48.png"
ICO_DOCUMENT="icons8-document-48.png"
ICO_PDF="icons8-pdf-48.png"
ICO_PICTURE="icons8-picture-48.png"
ICO_REBAR="icons8-reinforced-concrete-48.png"
ICO_SNOOPY="icons8-snoopy-48.png"
ICO_MEASURE="icons8-tape-measure-48.png"
ICO_PYTHAGREON="icons8-trigonometry-48.png"
ICO_FOLDER="icons8-folder-48.png"

################################################################################

attempt_to_select_an_icon() {
    case $1 in
        site.webmanifest|       \
        sitemap_style.xsl|      \
        sitemap.xml|            \
        robots.txt)
            icon=$ICO_REBAR
            return 0
        ;;
    esac

    case $2 in
        png|    \
        jpg|    \
        ico)
            icon=$ICO_PICTURE
            return 0
        ;;
        ttf)
            icon=$ICO_TYPE
            return 0
        ;;
        css)
            icon=$ICO_MEASURE
            return 0
        ;;
        sh)
            icon=$ICO_CONSOLE
            return 0
        ;;
        svg)
            icon=$ICO_PYTHAGREON
            return 0
        ;;
        txt|    \
        py)
            icon=$ICO_CODE
            return 0
        ;;
        html|   \
        docx)
            icon=$ICO_DOCUMENT
            return 0
        ;;
        pdf)
            icon=$ICO_PDF
            return 0
        ;;
        mp3|    \
        wav)
            icon=$ICO_AUDIO
            return 0
        ;;
        directory)
            icon=$ICO_FOLDER
            return 0
        ;;
    esac

    return 1
}


file="$1"
[[ $file =~ \.([a-zA-Z0-9]+)$ ]] \
    && file_ext="${BASH_REMATCH[1]}" || file_ext="directory"

icon="$DEFAULT"
attempt_to_select_an_icon "$file" "$file_ext"

icon="$RESOURCE_PATH$icon"

echo "<label style=\"display: flex; align-items: center;\"><img src=\"$icon\" style=\"width: 32px; margin-right: .25rem\" /> <b>$file</b></label>"
