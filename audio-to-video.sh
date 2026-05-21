#!/bin/bash
#
# audio-to-video.sh
# Creates a YouTube-ready video from a static image and audio file.
#
# Usage:
#   ./audio-to-video.sh [options]
#
# Options:
#   -i, --image <file>    Input image file (default: auto-detect)
#   -a, --audio <file>    Input audio file (default: auto-detect)
#   -o, --output <file>   Output video file (default: output.mp4)
#   -h, --help            Show this help message
#

set -e

print_usage() {
    cat << EOF
Usage: $(basename "$0") [options]

Creates a YouTube-ready video from an image and audio file.

Options:
  -i, --image <file>      Input image file (auto-detects if not specified)
  -a, --audio <file>      Input audio file (auto-detects if not specified)
  -o, --output <file>     Output video file (default: output.mp4)
  --fps <n>               Frames per second (default: 1)
  --resolution <WxH>      Output resolution (default: 1280x720)
  --bg-color <color>      Letterbox color, e.g. black, white, 0xff0000 (default: black)
  -h, --help              Show this help message

Examples:
  $(basename "$0")
  $(basename "$0") -i cover.png -a beat.mp3
  $(basename "$0") -i artwork.jpg -a track.wav -o my-video.mp4
  $(basename "$0") --resolution 1920x1080 --fps 30 --bg-color white
EOF
}

error() { echo "Error: $1" >&2; exit 1; }

find_file() {
    for pattern in "$@"; do
        for file in $pattern; do
            [[ -f "$file" ]] && echo "$file" && return 0
        done
    done
    return 1
}

detect_image() {
    find_file "cover.png" "cover.jpg" "cover.jpeg" "cover.webp" \
              "image.png" "image.jpg" "image.jpeg" "image.webp" \
              "artwork.png" "artwork.jpg" "artwork.jpeg" "artwork.webp" \
              "*.png" "*.jpg" "*.jpeg" "*.webp"
}

detect_audio() {
    find_file "audio.mp3" "audio.wav" "audio.flac" "audio.m4a" \
              "beat.mp3" "beat.wav" "beat.flac" "beat.m4a" \
              "music.mp3" "music.wav" "music.flac" "music.m4a" \
              "*.mp3" "*.wav" "*.flac" "*.m4a"
}

get_audio_duration() {
    ffprobe -v error -show_entries format=duration -of csv=p=0 "$1" 2>/dev/null
}

format_duration() {
    local seconds="${1%.*}"
    local mins=$((seconds / 60))
    local secs=$((seconds % 60))
    if [[ $mins -gt 0 ]]; then
        echo "${mins}m ${secs}s"
    else
        echo "${secs}s"
    fi
}

# Parse arguments
IMAGE_FILE=""
AUDIO_FILE=""
OUTPUT_FILE="output.mp4"
FPS="1"
RESOLUTION="1280x720"
BG_COLOR="black"

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--image) IMAGE_FILE="$2"; shift 2 ;;
        -a|--audio) AUDIO_FILE="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        --fps) FPS="$2"; shift 2 ;;
        --resolution) RESOLUTION="$2"; shift 2 ;;
        --bg-color) BG_COLOR="$2"; shift 2 ;;
        -h|--help) print_usage; exit 0 ;;
        *) error "Unknown option: $1. Use --help for usage." ;;
    esac
done

# Validate and parse resolution / fps
[[ "$RESOLUTION" =~ ^[0-9]+x[0-9]+$ ]] || error "Invalid resolution: $RESOLUTION (expected WxH, e.g. 1280x720)"
VIDEO_WIDTH="${RESOLUTION%x*}"
VIDEO_HEIGHT="${RESOLUTION#*x}"
[[ "$FPS" =~ ^[0-9]+$ && "$FPS" -gt 0 ]] || error "Invalid fps: $FPS (expected positive integer)"

# Auto-detect files if not specified
[[ -z "$IMAGE_FILE" ]] && IMAGE_FILE=$(detect_image)
[[ -z "$AUDIO_FILE" ]] && AUDIO_FILE=$(detect_audio)

[[ -z "$IMAGE_FILE" ]] && error "No image file found. Use -i to specify one."
[[ -z "$AUDIO_FILE" ]] && error "No audio file found. Use -a to specify one."
[[ -f "$IMAGE_FILE" ]] || error "Image file not found: $IMAGE_FILE"
[[ -f "$AUDIO_FILE" ]] || error "Audio file not found: $AUDIO_FILE"

command -v ffmpeg >/dev/null 2>&1 || error "ffmpeg is not installed."
command -v ffprobe >/dev/null 2>&1 || error "ffprobe is not installed."

DURATION=$(get_audio_duration "$AUDIO_FILE")
[[ -z "$DURATION" || "$DURATION" == "N/A" ]] && error "Could not read audio file."

echo ""
echo "  Image: $IMAGE_FILE"
echo "  Audio: $AUDIO_FILE ($(format_duration "$DURATION"))"
echo "  Output: $OUTPUT_FILE"
echo ""

START_TIME=$(date +%s)

echo "Creating video..."

ffmpeg -y -hide_banner -loglevel error \
    -loop 1 -i "$IMAGE_FILE" \
    -i "$AUDIO_FILE" \
    -map 0:v -map 1:a \
    -vf "scale=${VIDEO_WIDTH}:${VIDEO_HEIGHT}:force_original_aspect_ratio=decrease,pad=${VIDEO_WIDTH}:${VIDEO_HEIGHT}:(ow-iw)/2:(oh-ih)/2:${BG_COLOR}" \
    -c:v libx264 -preset ultrafast -tune stillimage -crf 23 \
    -r "$FPS" -pix_fmt yuv420p \
    -g 30 -keyint_min 15 \
    -c:a aac -b:a 320k -ar 48000 -ac 2 \
    -shortest -movflags +faststart \
    "$OUTPUT_FILE"

OUTPUT_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
ELAPSED=$(( $(date +%s) - START_TIME ))

echo ""
echo "Done! Created $OUTPUT_FILE ($OUTPUT_SIZE) in ${ELAPSED}s"
echo ""
