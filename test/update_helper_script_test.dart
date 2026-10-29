import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:youspotdl/services/update_helper_script.dart';

HelperScriptParams _params({
  int pid = 4242,
  String stagedPath = r'C:\Users\me\AppData\Local\Temp\staged',
  String installPath = r'C:\Program Files\YouSpotDL',
  String backupPath = r'C:\Users\me\AppData\Local\Temp\backup',
  String logPath = r'C:\Users\me\AppData\Local\Temp\update.log',
  String relaunchPath = r'C:\Program Files\YouSpotDL\YouSpotDL.exe',
}) {
  return HelperScriptParams(
    pid: pid,
    stagedPath: stagedPath,
    installPath: installPath,
    backupPath: backupPath,
    logPath: logPath,
    relaunchPath: relaunchPath,
  );
}

String _decodeEncodedCommand(String encoded) {
  final bytes = base64Decode(encoded);
  final units = List<int>.generate(
    bytes.length ~/ 2,
    (i) => bytes[2 * i] | (bytes[2 * i + 1] << 8),
  );
  return String.fromCharCodes(units);
}

void main() {
  group('psQuote', () {
    test('wraps a plain value in single quotes', () {
      expect(UpdateHelperScript.psQuote(r'C:\App'), r"'C:\App'");
    });

    test('keeps spaces inside the quotes', () {
      expect(
        UpdateHelperScript.psQuote(r'C:\Program Files\App'),
        r"'C:\Program Files\App'",
      );
    });

    test('doubles embedded apostrophes', () {
      expect(UpdateHelperScript.psQuote("O'Neil"), "'O''Neil'");
    });
  });

  group('shQuote', () {
    test('wraps a plain value in single quotes', () {
      expect(UpdateHelperScript.shQuote('/opt/app'), "'/opt/app'");
    });

    test('keeps spaces inside the quotes', () {
      expect(
        UpdateHelperScript.shQuote('/home/me/My Apps'),
        "'/home/me/My Apps'",
      );
    });

    test('closes, escapes and reopens around embedded apostrophes', () {
      expect(
        UpdateHelperScript.shQuote("/home/o'neil/app"),
        r"'/home/o'\''neil/app'",
      );
    });
  });

  group('parseResult', () {
    test('returns the text after the marker', () {
      expect(
        UpdateHelperScript.parseResult(
          '2026-10-28T10:00:00Z Backup complete\n'
          '2026-10-28T10:00:02Z RESULT success\n',
        ),
        'success',
      );
    });

    test('takes the last result line when several are present', () {
      expect(
        UpdateHelperScript.parseResult(
          'RESULT failed: first\n'
          'some other line\n'
          'RESULT failed: second\n',
        ),
        'failed: second',
      );
    });

    test('returns null when the log has no result line', () {
      expect(
        UpdateHelperScript.parseResult(
          '2026-10-28T10:00:00Z Waiting for YouSpotDL to exit\n',
        ),
        isNull,
      );
    });

    test('returns null for an empty log', () {
      expect(UpdateHelperScript.parseResult(''), isNull);
    });
  });

  group('encodePowerShellCommand', () {
    test('encodes ASCII as base64 of UTF-16LE', () {
      expect(UpdateHelperScript.encodePowerShellCommand('A'), 'QQA=');
    });

    test('decodes back to the original script, including non-ASCII', () {
      const script = r'''Write-Output "café $x 日本 'quoted'"''';
      final encoded = UpdateHelperScript.encodePowerShellCommand(script);
      expect(_decodeEncodedCommand(encoded), script);
    });
  });

  group('windowsLauncher', () {
    test('requests elevation through RunAs', () {
      final launcher = UpdateHelperScript.windowsLauncher(
        r'C:\Users\me\AppData\Local\Temp\helper.ps1',
        elevated: true,
      );
      expect(launcher, contains('-Verb RunAs'));
    });

    test('starts without elevation when the install folder is writable', () {
      final launcher = UpdateHelperScript.windowsLauncher(
        r'C:\Users\me\AppData\Local\Temp\helper.ps1',
        elevated: false,
      );
      expect(launcher, isNot(contains('RunAs')));
      expect(launcher, contains('Start-Process'));
    });

    test('passes the script path in double quotes inside a PowerShell literal',
        () {
      final launcher = UpdateHelperScript.windowsLauncher(
        r'C:\Users\me\My Temp\helper.ps1',
        elevated: true,
      );
      const path = r'C:\Users\me\My Temp\helper.ps1';
      expect(launcher, contains("'\"$path\"'"));
    });
  });

  group('windows helper script', () {
    test('embeds quoted paths and the process id', () {
      final script = UpdateHelperScript.windows(_params());
      expect(script, contains(r"$AppPid = 4242"));
      expect(
        script,
        contains(r"$Staged = 'C:\Users\me\AppData\Local\Temp\staged'"),
      );
      expect(script, contains(r"$Install = 'C:\Program Files\YouSpotDL'"));
      expect(script, contains(r"$Exe = 'C:\Program Files\YouSpotDL\YouSpotDL.exe'"));
    });

    test('escapes apostrophes in paths', () {
      final script = UpdateHelperScript.windows(
        _params(installPath: r"C:\Users\O'Neil\App"),
      );
      expect(script, contains(r"$Install = 'C:\Users\O''Neil\App'"));
    });

    test('runs wait, backup, copy and relaunch in that order', () {
      final script = UpdateHelperScript.windows(_params());
      final wait = script.indexOf('Waiting for YouSpotDL to exit');
      final backup = script.indexOf('Backup complete');
      final copy = script.indexOf('robocopy.exe \$Staged');
      final relaunch = script.lastIndexOf('Start-App');
      expect(wait, greaterThanOrEqualTo(0));
      expect(backup, greaterThan(wait));
      expect(copy, greaterThan(backup));
      expect(relaunch, greaterThan(copy));
    });
  });

  group('linux helper script', () {
    test('embeds shell-quoted paths and the process id', () {
      final script = UpdateHelperScript.linux(_params(
        pid: 777,
        stagedPath: '/tmp/staged',
        installPath: '/opt/My App',
        backupPath: '/tmp/backup',
        logPath: '/tmp/update.log',
        relaunchPath: "/opt/My App/yous'pot",
      ));
      expect(script, contains('APP_PID=777'));
      expect(script, contains("STAGED='/tmp/staged'"));
      expect(script, contains("INSTALL='/opt/My App'"));
      expect(script, contains(r"EXE='/opt/My App/yous'\''pot'"));
    });

    test('runs wait, backup, copy and relaunch in that order', () {
      final script = UpdateHelperScript.linux(_params());
      final wait = script.indexOf('Waiting for YouSpotDL to exit');
      final backup = script.indexOf('Backup complete');
      final copy = script.indexOf('cp -a "\$STAGED/."');
      final relaunch = script.lastIndexOf('start_app\n');
      expect(wait, greaterThanOrEqualTo(0));
      expect(backup, greaterThan(wait));
      expect(copy, greaterThan(backup));
      expect(relaunch, greaterThan(copy));
    });
  });

  group('macos helper script', () {
    test('embeds shell-quoted app bundle paths and the process id', () {
      final script = UpdateHelperScript.macos(_params(
        pid: 99,
        stagedPath: '/tmp/YouSpotDL.app',
        installPath: '/Applications/YouSpotDL.app',
        backupPath: '/tmp/backup.app',
        logPath: '/tmp/update.log',
        relaunchPath: '/Applications/YouSpotDL.app',
      ));
      expect(script, contains('APP_PID=99'));
      expect(script, contains("STAGED='/tmp/YouSpotDL.app'"));
      expect(script, contains("INSTALL='/Applications/YouSpotDL.app'"));
      expect(script, contains("APP='/Applications/YouSpotDL.app'"));
    });

    test('runs wait, backup, swap and relaunch in that order', () {
      final script = UpdateHelperScript.macos(_params());
      final wait = script.indexOf('Waiting for YouSpotDL to exit');
      final backup = script.indexOf('Backup complete');
      final mkdir = script.indexOf('mkdir -p "\$(dirname "\$BACKUP")"');
      final moveAside = script.indexOf('mv "\$INSTALL" "\$BACKUP"');
      final swap = script.indexOf('ditto "\$STAGED"');
      final relaunch = script.lastIndexOf('open -n "\$APP"');
      expect(wait, greaterThanOrEqualTo(0));
      expect(mkdir, greaterThan(wait));
      expect(moveAside, greaterThan(mkdir));
      expect(backup, greaterThan(moveAside));
      expect(swap, greaterThan(backup));
      expect(relaunch, greaterThan(swap));
    });
  });
}
