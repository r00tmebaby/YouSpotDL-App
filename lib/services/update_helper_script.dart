import 'dart:convert';

/// Paths and process id handed to the helper that applies a staged update.
///
/// [stagedPath] and [installPath] are directories on Windows and Linux. On
/// macOS they are the staged and the installed `.app` bundles.
class HelperScriptParams {
  final int pid;
  final String stagedPath;
  final String installPath;
  final String backupPath;
  final String logPath;
  final String relaunchPath;

  const HelperScriptParams({
    required this.pid,
    required this.stagedPath,
    required this.installPath,
    required this.backupPath,
    required this.logPath,
    required this.relaunchPath,
  });
}

/// Generates the scripts that replace the app files after the app has exited.
///
/// The helper never deletes files that are not part of the release, so user
/// tools placed next to the executable (dlp.exe, ffmpeg/) and the history file
/// survive an update. Every outcome ends with one log line starting with
/// [resultPrefix], which the app reads on its next start.
class UpdateHelperScript {
  UpdateHelperScript._();

  static const resultPrefix = 'RESULT ';
  static const resultSuccess = 'success';

  /// How long the helper waits for the app process to exit before giving up.
  static const exitTimeoutSeconds = 60;

  /// Quotes [value] as a PowerShell single-quoted literal.
  static String psQuote(String value) => "'${value.replaceAll("'", "''")}'";

  /// Quotes [value] as a POSIX shell single-quoted word.
  static String shQuote(String value) =>
      "'${value.replaceAll("'", r"'\''")}'";

  /// Returns the text after the last result marker in [log], or null when the
  /// helper never reached a result (for example it was killed).
  static String? parseResult(String log) {
    String? result;
    for (final line in const LineSplitter().convert(log)) {
      final index = line.indexOf(resultPrefix);
      if (index >= 0) {
        result = line.substring(index + resultPrefix.length).trim();
      }
    }
    return result;
  }

  /// Encodes [script] for `powershell.exe -EncodedCommand`, which expects
  /// base64 of UTF-16LE and sidesteps every layer of command-line quoting.
  static String encodePowerShellCommand(String script) {
    final bytes = <int>[];
    for (final unit in script.codeUnits) {
      bytes
        ..add(unit & 0xff)
        ..add(unit >> 8);
    }
    return base64.encode(bytes);
  }

  /// PowerShell command that starts [scriptPath] hidden in a process that
  /// outlives the app, through UAC when [elevated]. It exits 0 when the helper
  /// started and 1 when it did not, for example because UAC was declined.
  ///
  /// The helper is not started directly from Dart: a PowerShell launched with
  /// ProcessStartMode.detached gets no console and never runs the script.
  static String windowsLauncher(String scriptPath, {required bool elevated}) {
    // Start-Process joins -ArgumentList with spaces, so the path needs its own
    // double quotes to survive a space in the profile directory name.
    final fileArg = psQuote('"${scriptPath.replaceAll('"', '')}"');
    final verb = elevated ? '-Verb RunAs ' : '';
    return 'try { '
        "Start-Process -FilePath 'powershell.exe' $verb-WindowStyle Hidden "
        "-ArgumentList '-NoProfile','-ExecutionPolicy','Bypass',"
        "'-WindowStyle','Hidden','-File',$fileArg "
        '-ErrorAction Stop; exit 0 } catch { exit 1 }';
  }

  /// PowerShell helper for Windows. Copies the staged bundle over the install
  /// directory with robocopy and restores the backup when the copy fails.
  static String windows(HelperScriptParams params) {
    const timeoutMs = exitTimeoutSeconds * 1000;
    const r = resultPrefix;
    return '''
\$ErrorActionPreference = 'Stop'
\$AppPid = ${params.pid}
\$Staged = ${psQuote(params.stagedPath)}
\$Install = ${psQuote(params.installPath)}
\$Backup = ${psQuote(params.backupPath)}
\$Log = ${psQuote(params.logPath)}
\$Exe = ${psQuote(params.relaunchPath)}

function Write-Log([string]\$Message) {
  Add-Content -LiteralPath \$Log -Value ('{0:o} {1}' -f (Get-Date), \$Message)
}

function Start-App {
  # explorer.exe starts the app as the desktop user even when this script runs elevated.
  Start-Process -FilePath (Join-Path \$env:WINDIR 'explorer.exe') -ArgumentList ('"' + \$Exe + '"')
}

Write-Log 'Waiting for YouSpotDL to exit'
# Polling avoids Process.WaitForExit, which throws when the id has been reused
# by a process this user may not open.
\$deadline = (Get-Date).AddMilliseconds($timeoutMs)
while (Get-Process -Id \$AppPid -ErrorAction SilentlyContinue) {
  if ((Get-Date) -gt \$deadline) {
    Write-Log '${r}failed: the app did not exit within $exitTimeoutSeconds s, nothing was changed'
    exit 1
  }
  Start-Sleep -Milliseconds 250
}
Start-Sleep -Milliseconds 500

try {
  New-Item -ItemType Directory -Force -Path \$Backup | Out-Null
  foreach (\$file in Get-ChildItem -LiteralPath \$Staged -Recurse -File) {
    \$relative = \$file.FullName.Substring(\$Staged.Length).TrimStart('\\')
    \$target = Join-Path \$Install \$relative
    if (Test-Path -LiteralPath \$target -PathType Leaf) {
      \$saved = Join-Path \$Backup \$relative
      New-Item -ItemType Directory -Force -Path (Split-Path -Parent \$saved) | Out-Null
      Copy-Item -LiteralPath \$target -Destination \$saved -Force
    }
  }
  Write-Log 'Backup complete'
} catch {
  Write-Log ('${r}failed: backup failed, nothing was replaced: ' + \$_.Exception.Message)
  Start-App
  exit 1
}

& robocopy.exe \$Staged \$Install /E /IS /IT /R:5 /W:1 /NP /NJH /NJS | Out-Null
\$copyCode = \$LASTEXITCODE
if (\$copyCode -lt 8) {
  Write-Log '$r$resultSuccess'
} else {
  Write-Log "Copy failed with robocopy exit code \$copyCode, restoring the backup"
  & robocopy.exe \$Backup \$Install /E /IS /IT /R:5 /W:1 /NP /NJH /NJS | Out-Null
  if (\$LASTEXITCODE -lt 8) {
    Write-Log "${r}failed: copy error \$copyCode, previous version restored"
  } else {
    Write-Log "${r}failed: copy error \$copyCode and restore error \$LASTEXITCODE, backup kept in \$Backup"
  }
}
Start-App
''';
  }

  /// POSIX shell helper for Linux. Copies the staged bundle over the install
  /// directory with `cp -a` and restores the backup when the copy fails.
  static String linux(HelperScriptParams params) {
    const r = resultPrefix;
    return '''
#!/bin/sh
APP_PID=${params.pid}
STAGED=${shQuote(params.stagedPath)}
INSTALL=${shQuote(params.installPath)}
BACKUP=${shQuote(params.backupPath)}
LOG=${shQuote(params.logPath)}
EXE=${shQuote(params.relaunchPath)}

log() { printf '%s %s\\n' "\$(date -u +%Y-%m-%dT%H:%M:%SZ)" "\$1" >> "\$LOG"; }
start_app() { nohup "\$EXE" >/dev/null 2>&1 & }

${_posixWaitForExit()}

mkdir -p "\$BACKUP" || { log '${r}failed: cannot create the backup directory, nothing was replaced'; start_app; exit 1; }
if ! (cd "\$STAGED" && find . \\( -type f -o -type l \\) -print) | while IFS= read -r rel; do
  if [ -e "\$INSTALL/\$rel" ] || [ -L "\$INSTALL/\$rel" ]; then
    mkdir -p "\$BACKUP/\$(dirname "\$rel")" && cp -a "\$INSTALL/\$rel" "\$BACKUP/\$rel" || exit 1
  fi
done; then
  log '${r}failed: backup failed, nothing was replaced'
  start_app
  exit 1
fi
log 'Backup complete'

if cp -a "\$STAGED/." "\$INSTALL/"; then
  log '$r$resultSuccess'
elif cp -a "\$BACKUP/." "\$INSTALL/"; then
  log '${r}failed: copy error, previous version restored'
else
  log "${r}failed: copy and restore errors, backup kept in \$BACKUP"
fi
start_app
''';
  }

  /// POSIX shell helper for macOS. Swaps the whole `.app` bundle so no stale
  /// files from the old version remain inside it.
  static String macos(HelperScriptParams params) {
    const r = resultPrefix;
    return '''
#!/bin/sh
APP_PID=${params.pid}
STAGED=${shQuote(params.stagedPath)}
INSTALL=${shQuote(params.installPath)}
BACKUP=${shQuote(params.backupPath)}
LOG=${shQuote(params.logPath)}
APP=${shQuote(params.relaunchPath)}

log() { printf '%s %s\\n' "\$(date -u +%Y-%m-%dT%H:%M:%SZ)" "\$1" >> "\$LOG"; }

${_posixWaitForExit()}

rm -rf "\$BACKUP"
if ! mkdir -p "\$(dirname "\$BACKUP")" || ! mv "\$INSTALL" "\$BACKUP"; then
  log '${r}failed: cannot move the current app aside, nothing was replaced'
  open -n "\$APP"
  exit 1
fi
log 'Backup complete'

if ditto "\$STAGED" "\$INSTALL"; then
  xattr -dr com.apple.quarantine "\$INSTALL" 2>/dev/null || true
  rm -rf "\$BACKUP"
  log '$r$resultSuccess'
else
  rm -rf "\$INSTALL"
  if mv "\$BACKUP" "\$INSTALL"; then
    log '${r}failed: copy error, previous version restored'
  else
    log "${r}failed: copy and restore errors, backup kept in \$BACKUP"
  fi
fi
open -n "\$APP"
''';
  }

  static String _posixWaitForExit() {
    const ticks = exitTimeoutSeconds * 2;
    const r = resultPrefix;
    return '''
log 'Waiting for YouSpotDL to exit'
ticks=0
while kill -0 "\$APP_PID" 2>/dev/null; do
  if [ "\$ticks" -ge $ticks ]; then
    log '${r}failed: the app did not exit within $exitTimeoutSeconds s, nothing was changed'
    exit 1
  fi
  sleep 0.5
  ticks=\$((ticks + 1))
done''';
  }
}
