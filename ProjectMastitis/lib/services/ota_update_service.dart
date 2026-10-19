import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReleaseInfo {
  final int versionCode;
  final String versionName;
  final String releaseNotes;
  final String apkDownloadUrl;
  final String? desktopDownloadUrl;
  final bool isMandatory;

  ReleaseInfo({
    required this.versionCode,
    required this.versionName,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    this.desktopDownloadUrl,
    required this.isMandatory,
  });

  factory ReleaseInfo.fromMap(Map<String, dynamic> map) {
    return ReleaseInfo(
      versionCode: map['version_code'] as int? ?? 1,
      versionName: map['version_name'] as String? ?? '1.0.0',
      releaseNotes: map['release_notes'] as String? ?? 'Performance improvements and bug fixes.',
      apkDownloadUrl: map['apk_download_url'] as String? ?? 'https://github.com/Mufti-IBAK/mastitis_research/raw/main/releases/mastitis_research.apk',
      desktopDownloadUrl: map['desktop_download_url'] as String?,
      isMandatory: map['is_mandatory'] as bool? ?? false,
    );
  }
}

class OtaUpdateService {
  static final OtaUpdateService _instance = OtaUpdateService._internal();
  factory OtaUpdateService() => _instance;
  OtaUpdateService._internal();

  static const String githubVersionUrl =
      'https://raw.githubusercontent.com/Mufti-IBAK/mastitis_research/main/version.json';

  Future<ReleaseInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      // 1. Primary check: Live GitHub repository version manifest
      try {
        final cacheBusterUrl = Uri.parse('$githubVersionUrl?t=${DateTime.now().millisecondsSinceEpoch}');
        final res = await http.get(cacheBusterUrl).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final latestRelease = ReleaseInfo.fromMap(data);
          if (latestRelease.versionCode > currentBuildNumber) {
            return latestRelease;
          }
          return null; // Current installation is up to date
        }
      } catch (e) {
        debugPrint('GitHub OTA check fallback notice: $e');
      }

      // 2. Secondary fallback: Supabase app_releases table
      try {
        final response = await Supabase.instance.client
            .from('app_releases')
            .select()
            .order('version_code', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response != null) {
          final latestRelease = ReleaseInfo.fromMap(response);
          if (latestRelease.versionCode > currentBuildNumber) {
            return latestRelease;
          }
        }
      } catch (e) {
        debugPrint('Supabase OTA check error: $e');
      }

      return null;
    } catch (e) {
      debugPrint('Error checking for OTA update: $e');
      return null;
    }
  }

  static void promptUpdateDialog(BuildContext context, ReleaseInfo release) {
    showDialog(
      context: context,
      barrierDismissible: !release.isMandatory,
      builder: (ctx) {
        return _UpdateDialog(release: release);
      },
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final ReleaseInfo release;
  const _UpdateDialog({required this.release});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _status = '';

  Future<void> _startDownloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _status = 'Connecting to server...';
      _progress = 0.0;
    });

    try {
      final client = http.Client();
      final isWindows = !kIsWeb && Platform.isWindows;
      
      String downloadUrl = isWindows && widget.release.desktopDownloadUrl != null
          ? widget.release.desktopDownloadUrl!
          : widget.release.apkDownloadUrl;

      var request = http.Request('GET', Uri.parse(downloadUrl));
      var response = await client.send(request);

      // Follow HTTP redirects explicitly if encountered (GitHub raw CDN redirect)
      int redirects = 0;
      while ((response.statusCode == 301 ||
              response.statusCode == 302 ||
              response.statusCode == 307 ||
              response.statusCode == 308) &&
          redirects < 5) {
        final location = response.headers['location'];
        if (location == null) break;
        downloadUrl = location.startsWith('http')
            ? location
            : Uri.parse(downloadUrl).resolve(location).toString();
        request = http.Request('GET', Uri.parse(downloadUrl));
        response = await client.send(request);
        redirects++;
      }

      if (response.statusCode != 200) {
        throw Exception('Server returned HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final tempDir = await getTemporaryDirectory();
      
      final fileName = isWindows
          ? 'Mastitis_Research_Desktop_Setup_v${widget.release.versionName}.exe'
          : 'mastitis_research_v${widget.release.versionName}.apk';
      final targetFile = File('${tempDir.path}/$fileName');

      int bytesReceived = 0;
      final sink = targetFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        bytesReceived += chunk.length;
        if (contentLength > 0 && mounted) {
          setState(() {
            _progress = bytesReceived / contentLength;
            _status =
                'Downloading: ${(bytesReceived / (1024 * 1024)).toStringAsFixed(1)} MB / ${(contentLength / (1024 * 1024)).toStringAsFixed(1)} MB (${(_progress * 100).toInt()}%)';
          });
        }
      }

      await sink.close();
      if (!mounted) return;

      setState(() {
        _status = 'Launching installer...';
      });

      // Launch APK or Desktop setup installer directly
      await OpenFilex.open(targetFile.path);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _status = 'Download failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.system_update_rounded, color: Colors.teal),
          ),
          const SizedBox(width: 12),
          const Text('New Update Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Version ${widget.release.versionName}',
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.teal, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(widget.release.releaseNotes,
              style: const TextStyle(fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 16),
          if (_isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  minHeight: 8,
                  color: Colors.teal),
            ),
            const SizedBox(height: 8),
            Text(_status, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ],
      ),
      actions: [
        if (!widget.release.isMandatory && !_isDownloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
        if (!_isDownloading)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Update Now'),
            onPressed: _startDownloadAndInstall,
          ),
      ],
    );
  }
}
