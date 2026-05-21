# audio-to-video

A small Bash script that pairs a static image with an audio file and produces a YouTube-ready MP4 using `ffmpeg`. Useful for uploading music, podcasts, or any audio content that needs a single still image as its video track.

---

## Quick start

```bash
# 1. Clone
git clone https://github.com/<your-username>/audio-to-video.git
cd audio-to-video

# 2. Make the script executable (macOS / Linux / WSL only)
chmod +x audio-to-video.sh

# 3. Drop an image and an audio file into the folder, then run
./audio-to-video.sh
```

That's it. The script picks up any image and any audio file in the folder and writes `output.mp4`.

---

## Installation

You need two things: **`ffmpeg`** (which also installs `ffprobe`) and **a Bash shell**. Pick your OS below.

### macOS

```bash
# Install Homebrew if you don't have it: https://brew.sh
brew install ffmpeg
```

Bash is built in. You're done — jump to **Quick start**. If you'd rather not use the terminal, rename `audio-to-video.sh` to `audio-to-video.command` after cloning — `.command` files run in Terminal when double-clicked.

### Linux

Debian / Ubuntu / Mint:

```bash
sudo apt update && sudo apt install -y ffmpeg
```

Fedora / RHEL:

```bash
sudo dnf install -y ffmpeg
```

Arch / Manjaro:

```bash
sudo pacman -S ffmpeg
```

Bash is built in. You're done — jump to **Quick start**. If your file manager supports running executables (most GNOME/KDE setups do), you can also double-click the script after `chmod +x`.

### Windows

You need a Bash environment to run the script. Pick **one** of these — easiest first:

**Option A — Git Bash (simplest, recommended)**

1. Install [Git for Windows](https://git-scm.com/download/win) — this gives you Git _and_ Bash.
2. Install `ffmpeg` using `winget` (built into Windows 10/11) in PowerShell:

   ```powershell
   winget install ffmpeg
   ```

   Restart your terminal so the new `PATH` takes effect.

3. Open **Git Bash**, `cd` into the project folder, and run `./audio-to-video.sh`. Or, since Git Bash registers itself as the handler for `.sh` files, you can simply **double-click `audio-to-video.sh`** in File Explorer — output appears in the same folder. (Note: on double-click the window closes when the script finishes, so re-run from Git Bash if you need to see error output.)

**Option B — WSL (Windows Subsystem for Linux)**

If you already use WSL, just follow the Linux instructions above inside your WSL distro.

```powershell
wsl --install      # one-time, if you don't have WSL yet
```

Then inside WSL: `sudo apt install -y ffmpeg`.

**Option C — Scoop or Chocolatey**

If you prefer these package managers:

```powershell
scoop install ffmpeg          # via Scoop
choco install ffmpeg          # via Chocolatey
```

You still need Git Bash or WSL to run the `.sh` script.

---

## Usage

```bash
./audio-to-video.sh [options]
```

| Flag                  | Description                                                                      |
| --------------------- | -------------------------------------------------------------------------------- |
| `-i, --image <file>`  | Input image file (auto-detected if omitted)                                      |
| `-a, --audio <file>`  | Input audio file (auto-detected if omitted)                                      |
| `-o, --output <file>` | Output video file (default: `output.mp4`)                                        |
| `--fps <n>`           | Frames per second (default: `1`)                                                 |
| `--resolution <WxH>`  | Output resolution (default: `1280x720`)                                          |
| `--bg-color <color>`  | Letterbox color: named (`black`, `white`) or hex (`0xff0000`) (default: `black`) |
| `-h, --help`          | Show usage                                                                       |

### Examples

```bash
# Auto-detect image and audio in the current directory
./audio-to-video.sh

# Specify inputs explicitly
./audio-to-video.sh -i cover.png -a beat.mp3

# Custom output name
./audio-to-video.sh -i artwork.jpg -a track.wav -o my-video.mp4

# 1080p at 30 fps with a white letterbox
./audio-to-video.sh --resolution 1920x1080 --fps 30 --bg-color white
```

### Why these defaults?

The defaults are tuned for the most common use case: **uploading to YouTube**, which re-encodes everything server-side.

- **`--fps 1`** — YouTube re-encodes uploads, so source fps doesn't affect viewer experience. A 1 fps source produces a file that's a fraction of the size and encodes far faster. If you plan to use the output elsewhere (local playback, social platforms that don't re-encode), bump to `--fps 24` or `--fps 30` for compatibility.
- **`--resolution 1280x720`** — 720p is YouTube's minimum HD tier and a static image gets no real benefit from 1080p. Override with `--resolution 1920x1080` if you'd rather upload at 1080p.
- **`--bg-color black`** — Standard letterbox. Set this to match your image's background if you'd rather not see bars.

### Auto-detection

If `-i` / `-a` are not provided, the script will use **any** image or audio file it finds in the current directory.

Supported extensions:

- **Image**: `.png`, `.jpg`, `.jpeg`, `.webp`
- **Audio**: `.mp3`, `.wav`, `.flac`, `.m4a`

If multiple files match, the script prefers conventional names in this order, then falls back to whatever it finds:

- **Image**: `cover.*` → `image.*` → `artwork.*` → any matching file
- **Audio**: `audio.*` → `beat.*` → `music.*` → any matching file

So if you only have one image and one audio file in the folder, naming doesn't matter at all.

---

## Output

- **Resolution:** `1280x720` by default (override with `--resolution`), letterboxed to preserve the source image's aspect ratio
- **Frame rate:** `1` fps by default (override with `--fps`)
- **Video codec:** H.264 (`libx264`, `yuv420p`)
- **Audio codec:** AAC, 320 kbps, 48 kHz stereo
- **Container:** MP4 with `faststart` enabled for streaming

---

## Troubleshooting

**`ffmpeg: command not found`** — `ffmpeg` isn't on your `PATH`. Re-open your terminal after installing, or check with `ffmpeg -version`.

**`Permission denied`** — Run `chmod +x audio-to-video.sh` (macOS / Linux / WSL).

**Script won't run on Windows in PowerShell or CMD** — You need a Bash shell. Use **Git Bash** or **WSL** (see Windows install options above).

**No image / audio detected** — Make sure your files use one of the supported extensions (`.png/.jpg/.jpeg/.webp` for images, `.mp3/.wav/.flac/.m4a` for audio), or pass them explicitly with `-i` and `-a`.

---

## License

MIT
