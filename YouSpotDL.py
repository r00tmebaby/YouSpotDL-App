import os
import asyncio
import subprocess
import shutil
import sys
import zipfile

from dotenv import load_dotenv
import spotipy
from spotipy.oauth2 import SpotifyOAuth
from tqdm import tqdm
from rich.panel import Panel
from rich.console import Console

load_dotenv()

BANNER = """[bold cyan]
 █████ █████                      █████████                      █████    ██████████   █████      
░░███ ░░███                      ███░░░░░███                    ░░███    ░░███░░░░███ ░░███       
 ░░███ ███    ██████  █████ ████░███    ░░░  ████████   ██████  ███████   ░███   ░░███ ░███       
  ░░█████    ███░░███░░███ ░███ ░░█████████ ░░███░░███ ███░░███░░░███░    ░███    ░███ ░███       
   ░░███    ░███ ░███ ░███ ░███  ░░░░░░░░███ ░███ ░███░███ ░███  ░███     ░███    ░███ ░███       
    ░███    ░███ ░███ ░███ ░███  ███    ░███ ░███ ░███░███ ░███  ░███ ███ ░███    ███  ░███      █
    █████   ░░██████  ░░████████░░█████████  ░███████ ░░██████   ░░█████  ██████████   ███████████
   ░░░░░     ░░░░░░    ░░░░░░░░  ░░░░░░░░░   ░███░░░   ░░░░░░     ░░░░░  ░░░░░░░░░░   ░░░░░░░░░░░ 
                                             ░███                                                  
                                             █████                                                  
                                            ░░░░░                                       

                    Author: [bold blue]https://github.com/r00tmebaby[/bold blue]
                    Email:  zgeorg01@gmail.com
                    Date:   11/02/2025

        🎵 [bold yellow]Welcome to YouSpotDL - The Ultimate Downloader[/bold yellow] 🎵
[/bold cyan]"""

console = Console()

SPOTIFY_CLIENT_ID = os.getenv("SPOTIFY_CLIENT_ID")
SPOTIFY_CLIENT_SECRET = os.getenv("SPOTIFY_CLIENT_SECRET")
SPOTIFY_REDIRECT_URI = os.getenv("SPOTIFY_REDIRECT_URI", "http://127.0.0.1:8888/callback")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


def resolve_ytdlp_command():
    """Find an available yt-dlp executable command."""
    local_dlp = os.path.join(SCRIPT_DIR, "dlp.exe")
    if os.path.isfile(local_dlp):
        return [local_dlp]

    ytdlp_in_path = shutil.which("yt-dlp")
    if ytdlp_in_path:
        return [ytdlp_in_path]

    module_command = [sys.executable, "-m", "yt_dlp"]
    try:
        check = subprocess.run(
            module_command + ["--version"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=20,
        )
        if check.returncode == 0:
            return module_command
    except Exception:
        pass

    return None


YTDLP_COMMAND = resolve_ytdlp_command()


def resolve_ffmpeg_location():
    """Find ffmpeg location for yt-dlp post-processing."""
    candidates = [
        os.path.join(SCRIPT_DIR, "ffmpeg.exe"),
        os.path.join(SCRIPT_DIR, "ffmpeg", "ffmpeg.exe"),
        os.path.join(SCRIPT_DIR, "ffmpeg", "bin", "ffmpeg.exe"),
    ]

    ffmpeg_root = os.path.join(SCRIPT_DIR, "ffmpeg")
    if os.path.isdir(ffmpeg_root):
        for root, _, files in os.walk(ffmpeg_root):
            if "ffmpeg.exe" in files:
                candidates.append(os.path.join(root, "ffmpeg.exe"))

    for candidate in candidates:
        if os.path.isfile(candidate):
            return os.path.dirname(candidate)

    ffmpeg_in_path = shutil.which("ffmpeg")
    if ffmpeg_in_path:
        return os.path.dirname(ffmpeg_in_path)

    return None


FFMPEG_LOCATION = resolve_ffmpeg_location()
FFMPEG_WARNING_SHOWN = False


def extract_zip_archive(zip_path, destination):
    """Extract a zip archive and return True when extraction succeeds."""
    try:
        with zipfile.ZipFile(zip_path, "r") as archive:
            archive.extractall(destination)
        return True
    except Exception as error:
        console.print(f"\n❌ [red]Failed to extract {os.path.basename(zip_path)}: {error}[/red]")
        return False


def try_install_ytdlp():
    """Attempt to install yt-dlp into the current Python environment."""
    console.print("\n🧰 [yellow]yt-dlp not found. Trying to install it...[/yellow]")
    install_command = [sys.executable, "-m", "pip", "install", "yt-dlp"]

    result = subprocess.run(install_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode == 0:
        return True

    console.print("\n❌ [red]Automatic yt-dlp installation failed.[/red]")
    stderr_tail = result.stderr.strip().splitlines()[-1] if result.stderr.strip() else "Unknown pip error"
    console.print(f"[red]{stderr_tail}[/red]")
    return False


def bootstrap_dependencies():
    """Validate external tools and try safe auto-recovery steps."""
    global YTDLP_COMMAND
    global FFMPEG_LOCATION

    if not YTDLP_COMMAND:
        dlp_zip = os.path.join(SCRIPT_DIR, "dlp.zip")
        if os.path.isfile(dlp_zip):
            console.print("\n📦 [yellow]Found dlp.zip. Extracting...[/yellow]")
            extract_zip_archive(dlp_zip, SCRIPT_DIR)
            YTDLP_COMMAND = resolve_ytdlp_command()

    if not YTDLP_COMMAND and try_install_ytdlp():
        YTDLP_COMMAND = resolve_ytdlp_command()

    if not YTDLP_COMMAND:
        console.print("\n❌ [red]yt-dlp is required but not available.[/red]")
        console.print("[yellow]Install it manually with: python -m pip install yt-dlp[/yellow]")
        raise SystemExit(1)

    if not FFMPEG_LOCATION:
        ffmpeg_zip = os.path.join(SCRIPT_DIR, "ffmpeg.zip")
        if os.path.isfile(ffmpeg_zip):
            console.print("\n📦 [yellow]Found ffmpeg.zip. Extracting...[/yellow]")
            extract_zip_archive(ffmpeg_zip, os.path.join(SCRIPT_DIR, "ffmpeg"))
            FFMPEG_LOCATION = resolve_ffmpeg_location()

    if not FFMPEG_LOCATION:
        console.print("\n❌ [red]ffmpeg is required for MP3 conversion but was not found.[/red]")
        console.print("[yellow]Place ffmpeg.exe in project folder, or keep ffmpeg.zip in the project root.[/yellow]")
        raise SystemExit(1)


def get_optimal_threads():
    """Returns the best thread count for parallel downloads."""
    return max(5, min(os.cpu_count(), 24))


MAX_CONCURRENT_DOWNLOADS = get_optimal_threads()


def get_spotify_client():
    """Authenticate with Spotify using OAuth."""
    missing = []
    if not SPOTIFY_CLIENT_ID:
        missing.append("SPOTIFY_CLIENT_ID")
    if not SPOTIFY_CLIENT_SECRET:
        missing.append("SPOTIFY_CLIENT_SECRET")

    if missing:
        console.print(f"\n❌ [red]Missing Spotify credentials in .env: {', '.join(missing)}[/red]")
        console.print("[yellow]Create a .env file with your credentials from https://developer.spotify.com/dashboard[/yellow]")
        raise SystemExit(1)

    try:
        auth_manager = SpotifyOAuth(
            client_id=SPOTIFY_CLIENT_ID,
            client_secret=SPOTIFY_CLIENT_SECRET,
            redirect_uri=SPOTIFY_REDIRECT_URI,
            scope="playlist-read-private playlist-read-collaborative",
            cache_path=".cache-spotify"
        )
        return spotipy.Spotify(auth_manager=auth_manager)
    except Exception as e:
        console.print(f"\n❌ [red]Spotify authentication failed: {e}[/red]")
        raise SystemExit(1)


def get_user_playlists():
    """Fetches all playlists from a user's Spotify profile."""
    spotify = get_spotify_client()
    playlists = []
    user_id = spotify.current_user()["id"]
    results = spotify.user_playlists(user_id)

    while results:
        playlists.extend(results["items"])
        results = spotify.next(results) if results["next"] else None

    return [f'https://open.spotify.com/playlist/{pl["id"]}' for pl in playlists]


async def fetch_playlist_songs(platform, url):
    """Fetches song list from Spotify or YouTube based on platform."""
    playlist_name = None
    songs = []

    if platform == "Spotify":
        spotify = get_spotify_client()
        playlist_id = url.split("/")[-1].split("?")[0]

        try:
            playlist_data = spotify.playlist(playlist_id)
            playlist_name = playlist_data.get("name", "Unknown_Playlist")

            offset = 0
            limit = 100  # Maximum allowed by Spotify
            while True:
                results = spotify.playlist_tracks(playlist_id, offset=offset, limit=limit)
                track_items = results.get("items", [])

                if not track_items:
                    break  # No more tracks to fetch

                songs.extend([
                    f"{track['track']['name']} - {track['track']['artists'][0]['name']}"
                    for track in track_items if track.get("track")
                ])

                offset += limit  # Move to next batch

        except spotipy.SpotifyException as e:
            console.print(f"\n❌ [red]Error accessing Spotify playlist: {e}[/red]")

    elif platform == "YouTube":
        command = YTDLP_COMMAND + ["--flat-playlist", "--print", "%(title)s|%(url)s", url]
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        for line in result.stdout.splitlines():
            parts = line.split("|", 1)
            if len(parts) == 2:
                songs.append(parts[0])

        playlist_name = "YouTube_Playlist"

    return playlist_name, songs


async def download_song(song_name, output_folder):
    """Downloads a single song using yt-dlp."""
    global FFMPEG_WARNING_SHOWN

    command = YTDLP_COMMAND + [
        "-x",
        "--audio-format", "mp3",
        "--output", f"{output_folder}/%(title)s.%(ext)s",
        "--concurrent-fragments", str(get_optimal_threads()),
        "--limit-rate", "5M",
        "--audio-quality", "0",
        f"ytsearch:{song_name}"
    ]

    if FFMPEG_LOCATION:
        command[2:2] = ["--ffmpeg-location", FFMPEG_LOCATION]
    elif not FFMPEG_WARNING_SHOWN:
        console.print("\n⚠ [yellow]ffmpeg not found. yt-dlp will keep original audio format (e.g., .webm).[/yellow]")
        FFMPEG_WARNING_SHOWN = True

    process = await asyncio.create_subprocess_exec(
        *command, stdout=asyncio.subprocess.DEVNULL, stderr=asyncio.subprocess.PIPE
    )
    _, stderr_data = await process.communicate()

    if process.returncode != 0 and stderr_data:
        message = stderr_data.decode(errors="ignore").strip().splitlines()
        if message:
            console.print(f"\n❌ [red]yt-dlp failed for '{song_name}': {message[-1]}[/red]")

    return process.returncode == 0


async def worker(queue, output_folder, progress_bar, status):
    """Worker function for parallel downloads."""
    while not queue.empty():
        song_name = await queue.get()
        try:
            success = await download_song(song_name, output_folder)

            if success:
                status["downloaded"] += 1
            else:
                status["errors"] += 1
        except Exception:
            status["errors"] += 1
        finally:
            progress_bar.update(1)
            queue.task_done()


async def download_concurrent(playlist_name, songs, download_dir):
    """Downloads songs in parallel using workers with tqdm."""
    output_folder = os.path.join(download_dir, playlist_name)
    os.makedirs(output_folder, exist_ok=True)
    queue = asyncio.Queue()

    for song in songs:
        await queue.put(song)

    status = {"total": len(songs), "downloaded": 0, "errors": 0}

    with tqdm(total=len(songs), desc=f"🎵 Downloading {playlist_name}", ncols=80) as progress_bar:
        tasks = [
            asyncio.create_task(worker(queue, output_folder, progress_bar, status))
            for _ in range(MAX_CONCURRENT_DOWNLOADS)
        ]
        await queue.join()

        for task in tasks:
            task.cancel()

    return status


async def handle_download(platform, urls=None):
    """Handles playlist input and ensures each playlist gets its own folder."""

    download_dir = console.input("\n📂 [bold cyan]Enter download folder: [/bold cyan]").strip()
    if urls is None:
        urls = console.input(
            f"\n🎵 [bold cyan]Enter {platform} Playlist URL(s) (comma-separated): [/bold cyan]"
        ).strip().split(",")

    for url in urls:
        url = url.strip()
        if not url:
            continue

        console.print(f"\n⏳ [yellow]Fetching {platform} playlist...[/yellow]")
        playlist_name, songs = await fetch_playlist_songs(platform, url)

        if not songs:
            console.print(f"❌ [red]No songs found in {playlist_name}! Skipping.[/red]")
            continue  # Skip empty playlists

        console.print(f"\n✅ [bold cyan]Playlist: {playlist_name} - Total Songs: {len(songs)}[/bold cyan]")

        # Ensure each playlist gets a separate folder
        playlist_folder = os.path.join(download_dir, playlist_name)
        os.makedirs(playlist_folder, exist_ok=True)

        console.print("\n🚀 [bold blue]Downloading... Please wait.[/bold blue]")
        status = await download_concurrent(playlist_name, songs, download_dir)

        console.print("\n🎉 [bold green]Download Complete![/bold green]")
        console.print(f"✅ [bold cyan]Total Songs: {status['total']}[/bold cyan]")
        console.print(f"⬇ [bold green]Successfully Downloaded: {status['downloaded']}[/bold green]")
        console.print(f"❌ [bold red]Errors: {status['errors']}[/bold red]")

async def menu():
    """Main interactive menu with navigation."""
    while True:
        console.clear()
        console.print(Panel(BANNER, style="bold blue"))
        console.print("\n[1] 🎶 Download Spotify Playlist")
        console.print("[2] 📺 Download YouTube Playlist")
        console.print("[3] 📥 Download All Playlists from Spotify Profile")
        console.print("[4] ❌ Exit")

        action = console.input("\n[bold yellow]Enter choice: [/bold yellow]").strip()
        if action == "4":
            console.print("\n👋 [green]Exiting program. Have a great day![/green]")
            break
        elif action == "1":
            await handle_download("Spotify")
        elif action == "2":
            await handle_download("YouTube")
        elif action == "3":
            await handle_download("Spotify", get_user_playlists())

        console.input("\n🔄 [yellow]Press Enter to return to the menu...[/yellow]")


if __name__ == "__main__":
    bootstrap_dependencies()
    asyncio.run(menu())
