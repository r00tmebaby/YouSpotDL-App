import os
import asyncio
import subprocess
from queue import Queue

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


def get_optimal_threads() -> int:
    """Returns the best thread count for parallel downloads."""
    cpu_threads = os.cpu_count()
    return max(5, min(cpu_threads, 24))


MAX_CONCURRENT_DOWNLOADS = get_optimal_threads()


def get_spotify_client() -> spotipy.Spotify:
    """Authenticate with Spotify using automatic token handling."""
    auth_manager = SpotifyOAuth(
        client_id=SPOTIFY_CLIENT_ID,
        client_secret=SPOTIFY_CLIENT_SECRET,
        redirect_uri="http://127.0.0.1:8888/callback",
        scope="playlist-read-private playlist-read-collaborative",
        cache_path=".cache-spotify",  # ✅ Token stored here
    )

    # ✅ Ensure the token is retrieved correctly
    token_info = auth_manager.get_cached_token()

    if not token_info:
        console.print(
            "\n🔐 [yellow]No valid token found. Requesting new token...[/yellow]"
        )
        token_info = auth_manager.get_access_token(as_dict=True)  # ✅ Auto-handles auth

    # ✅ If token is expired, refresh automatically
    if auth_manager.is_token_expired(token_info):
        console.print("\n🔄 [cyan]Refreshing expired token...[/cyan]")
        token_info = auth_manager.refresh_access_token(token_info["refresh_token"])

    return spotipy.Spotify(auth=token_info["access_token"])


async def get_playlist_songs(playlist_url: str) -> tuple:
    """Fetch all song names from a Spotify playlist using Spotipy OAuth."""
    spotify = get_spotify_client()  # ✅ Use authenticated Spotify client

    playlist_id = playlist_url.split("/")[-1].split("?")[0]

    # ✅ Fetch playlist details
    try:
        playlist_data = spotify.playlist(playlist_id)
    except spotipy.SpotifyException as e:
        console.print(f"\n❌ [red]Error accessing playlist: {e}[/red]")
        return None, []

    playlist_name = playlist_data.get("name", "Unknown Playlist")

    # ✅ Display Playlist Name for User
    console.print(f"\n🎵 [bold green]Playlist Found: {playlist_name}[/bold green]")

    # ✅ Fetch all songs using pagination
    songs = []
    offset = 0
    limit = 100

    while True:
        tracks = spotify.playlist_tracks(playlist_id, limit=limit, offset=offset).get(
            "items", []
        )

        if not tracks:
            break  # ✅ No more tracks to fetch

        songs.extend(
            [
                f"{track['track']['name']} - {track['track']['artists'][0]['name']}"
                for track in tracks
                if track.get("track")
            ]
        )
        offset += limit  # ✅ Move to next batch
    return playlist_name, songs  # ✅ Returning playlist name & song list


def get_youtube_playlist_videos(url: str) -> tuple:
    """Extracts video titles and URLs from a YouTube playlist."""
    command = ["dlp.exe", "--flat-playlist", "--print", "%(title)s|%(url)s", url]
    result = subprocess.run(
        command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )

    video_titles = []
    video_urls = []

    for line in result.stdout.splitlines():
        parts = line.split("|", 1)
        if len(parts) == 2:
            title, video_url = parts
            video_titles.append(title)  # ✅ Store title for user display
            video_urls.append(video_url)  # ✅ Store URL for downloading
    return video_urls, video_titles  # ✅ Return both separately


async def download_song(song_name: str, output_folder: str) -> bool:
    """Downloads a single song using yt-dlp (for Spotify & YouTube)."""
    command = [
        "dlp.exe",
        "-x",
        "--audio-format",
        "mp3",
        "--ffmpeg-location",
        FFMPEG_PATH,
        "--output",
        f"{output_folder}/%(title)s.%(ext)s",
        "--concurrent-fragments",
        str(get_optimal_threads()),
        "--limit-rate",
        "5M",
        "--audio-quality",
        "0",
        f"ytsearch:{song_name}",
    ]

    process = await asyncio.create_subprocess_exec(
        *command, stdout=asyncio.subprocess.DEVNULL, stderr=asyncio.subprocess.DEVNULL
    )
    await process.communicate()
    return process.returncode == 0


async def worker(queue: Queue, output_folder: str, progress_bar:tqdm, status: dict) -> None:
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


async def download_concurrent(playlist_name: str, songs: list, download_dir: str) -> dict:
    """Downloads Spotify or YouTube songs in parallel using workers with tqdm."""
    output_folder = os.path.join(download_dir, playlist_name)
    os.makedirs(output_folder, exist_ok=True)
    queue = asyncio.Queue()

    for song in songs:
        await queue.put(song)

    status = {"total": len(songs), "downloaded": 0, "errors": 0}

    with tqdm(
        total=len(songs), desc=f"🎵 Downloading {playlist_name}", ncols=80
    ) as progress_bar:
        tasks = [
            asyncio.create_task(worker(queue, output_folder, progress_bar, status))
            for _ in range(MAX_CONCURRENT_DOWNLOADS)
        ]
        await queue.join()

        for task in tasks:
            task.cancel()

    return status


async def menu() -> None:
    """Main interactive menu with navigation."""
    while True:
        console.clear()
        console.print(Panel(BANNER, style="bold blue"))
        console.print(
            "\n[bold orange]Worker thread count: "
            + str(get_optimal_threads())
            + "[/bold orange]"
        )
        console.print("[1] 🎶 Download Spotify Playlist")
        console.print("[2] 📺 Download YouTube Playlist")
        console.print("[3] ❌ Exit")

        action = console.input("\n[bold yellow]Enter choice: [/bold yellow]").strip()

        if action == "3":
            console.print("\n👋 [green]Exiting program. Have a great day![/green]")
            break

        elif action in ["1", "2"]:
            download_dir = console.input(
                "\n📂 [bold cyan]Enter download folder: [/bold cyan]"
            ).strip()
            platform = None
            playlist_name = None
            songs = []

            if action == "1":
                platform = "Spotify"
                url = console.input(
                    "\n🎵 [bold cyan]Enter Spotify Playlist URL: [/bold cyan]"
                ).strip()
                console.print("\n⏳ [yellow]Fetching Spotify playlist...[/yellow]")
                playlist_name, songs = await get_playlist_songs(url)  # ✅ Fixed!

            elif action == "2":
                platform = "YouTube"
                url = console.input(
                    "\n📺 [bold cyan]Enter YouTube Playlist URL: [/bold cyan]"
                ).strip()
                console.print(
                    "\n⏳ [yellow]Fetching YouTube playlist videos...[/yellow]"
                )
                playlist_name = (
                    "YouTube_Playlist"  # ✅ Default name for YouTube playlist
                )
                songs_titles, songs = get_youtube_playlist_videos(url)  # ✅ Fixed!

            # ❌ If no items found, return to menu
            if not songs:
                console.print(
                    f"❌ [red]No songs found on {platform}! Returning to menu.[/red]"
                )
                await asyncio.sleep(2)
                continue

            # ✅ Print Song List Nicely for User
            console.print(f"\n✅ [bold cyan]Total Songs: {len(songs)}[/bold cyan]")
            for i, song in enumerate(songs, start=1):
                console.print(f"[cyan]{i}.[/cyan] [bold yellow]{song}[/bold yellow]")

            console.print("\n🚀 [bold blue]Downloading... Please wait.[/bold blue]")

            # 🛠️ Call common download function
            status = await download_concurrent(playlist_name, songs, download_dir)

            # 🏆 Generalized Summary Report
            console.print("\n🎉 [bold green]Download Complete![/bold green]")
            console.print(
                f"✅ [bold cyan]Total {platform} Songs: {status['total']}[/bold cyan]"
            )
            console.print(
                f"⬇ [bold green]Successfully Downloaded: {status['downloaded']}[/bold green]"
            )
            console.print(f"❌ [bold red]Errors: {status['errors']}[/bold red]")

        console.input("\n🔄 [yellow]Press Enter to return to the menu...[/yellow]")


if __name__ == "__main__":
    asyncio.run(menu())
