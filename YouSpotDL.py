import os
import asyncio
import subprocess

import spotipy
from spotipy.oauth2 import SpotifyOAuth
from tqdm import tqdm

from rich.panel import Panel
from rich.console import Console

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

SPOTIFY_CLIENT_ID = "1af4e8b8a8874ddbb4a8768ba474e9e2"
SPOTIFY_CLIENT_SECRET = "ec10aacd1add456e8e7bbfce82f18b22"

FFMPEG_PATH = os.getcwd()


def get_optimal_threads():
    """Returns the best thread count for parallel downloads."""
    return max(5, min(os.cpu_count(), 24))


MAX_CONCURRENT_DOWNLOADS = get_optimal_threads()


def get_spotify_client():
    """Authenticate with Spotify using OAuth."""
    auth_manager = SpotifyOAuth(
        client_id=SPOTIFY_CLIENT_ID,
        client_secret=SPOTIFY_CLIENT_SECRET,
        redirect_uri="http://127.0.0.1:8888/callback",
        scope="playlist-read-private playlist-read-collaborative",
        cache_path=".cache-spotify"
    )
    return spotipy.Spotify(auth_manager=auth_manager)


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
            songs = [
                f"{track['track']['name']} - {track['track']['artists'][0]['name']}"
                for track in playlist_data["tracks"]["items"]
                if track.get("track")
            ]
        except spotipy.SpotifyException as e:
            console.print(f"\n❌ [red]Error accessing Spotify playlist: {e}[/red]")

    elif platform == "YouTube":
        command = ["dlp.exe", "--flat-playlist", "--print", "%(title)s|%(url)s", url]
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        for line in result.stdout.splitlines():
            parts = line.split("|", 1)
            if len(parts) == 2:
                songs.append(parts[0])

        playlist_name = "YouTube_Playlist"

    return playlist_name, songs


async def download_song(song_name, output_folder):
    """Downloads a single song using yt-dlp."""
    command = [
        "dlp.exe",
        "-x",
        "--audio-format", "mp3",
        "--ffmpeg-location", FFMPEG_PATH,
        "--output", f"{output_folder}/%(title)s.%(ext)s",
        "--concurrent-fragments", str(get_optimal_threads()),
        "--limit-rate", "5M",
        "--audio-quality", "0",
        f"ytsearch:{song_name}"
    ]

    process = await asyncio.create_subprocess_exec(
        *command, stdout=asyncio.subprocess.DEVNULL, stderr=asyncio.subprocess.DEVNULL
    )
    await process.communicate()
    return process.returncode == 0


async def worker(queue, output_folder, progress_bar, status):
    """Worker function for parallel downloads."""
    while not queue.empty():
        song_name = await queue.get()
        success = await download_song(song_name, output_folder)

        if success:
            status["downloaded"] += 1
        else:
            status["errors"] += 1

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


async def handle_download(platform):
    """Handles playlist input and ensures each playlist gets its own folder."""
    download_dir = console.input("\n📂 [bold cyan]Enter download folder: [/bold cyan]").strip()
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
        console.print("[3] ❌ Exit")

        action = console.input("\n[bold yellow]Enter choice: [/bold yellow]").strip()
        if action == "3":
            console.print("\n👋 [green]Exiting program. Have a great day![/green]")
            break
        elif action == "1":
            await handle_download("Spotify")
        elif action == "2":
            await handle_download("YouTube")

        console.input("\n🔄 [yellow]Press Enter to return to the menu...[/yellow]")


if __name__ == "__main__":
    asyncio.run(menu())
