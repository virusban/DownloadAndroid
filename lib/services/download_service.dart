import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

enum OutputFormat { mp3, flac, wav, mp4, mkv }

class DownloadService {
  final YoutubeExplode _yt = YoutubeExplode();

  static String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[\\/*?:"<>|]'), '_')
        .replaceAll('\n', ' ')
        .trim();
  }

  Future<String> _getTempDir() async {
    final dir = await getTemporaryDirectory();
    return dir.path;
  }

  Future<String> _getOutputDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final downloads = Directory('${dir.path}/Downloads');
    if (!await downloads.exists()) await downloads.create(recursive: true);
    return downloads.path;
  }

  void dispose() {
    _yt.close();
  }

  Future<void> download({
    required String urlOrId,
    required OutputFormat format,
    void Function(String message)? onLog,
    void Function(double progress)? onProgress,
  }) async {
    onLog?.call('Resolving video...');
    final video = await _yt.videos.get(urlOrId);
    final videoId = video.id.value;
    final title = video.title;
    final author = video.author;

    onLog?.call('Getting stream manifest...');
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);

    final outDir = await _getOutputDir();
    final tempDir = await _getTempDir();

    if (format == OutputFormat.mp4 || format == OutputFormat.mkv) {
      await _downloadVideo(
        manifest: manifest,
        video: video,
        format: format,
        tempDir: tempDir,
        outDir: outDir,
        onLog: onLog,
        onProgress: onProgress,
      );
      return;
    }

    await _downloadAudio(
      manifest: manifest,
      video: video,
      format: format,
      tempDir: tempDir,
      outDir: outDir,
      title: title,
      author: author,
      onLog: onLog,
      onProgress: onProgress,
    );
  }

  Future<void> _downloadAudio({
    required StreamManifest manifest,
    required Video video,
    required OutputFormat format,
    required String tempDir,
    required String outDir,
    required String title,
    required String author,
    void Function(String message)? onLog,
    void Function(double progress)? onProgress,
  }) async {
    final audioStreams = manifest.audioOnly;
    if (audioStreams.isEmpty) {
      onLog?.call('No audio stream found.');
      return;
    }
    final audio = audioStreams.withHighestBitrate();
    final ext = audio.container.name;
    final tempAudio = '$tempDir/audio_${video.id}.$ext';

    onLog?.call('Downloading audio...');
    final stream = _yt.videos.streamsClient.get(audio);
    final file = File(tempAudio);
    final sink = file.openWrite();
    final total = audio.size.totalBytes;
    var received = 0;
    await for (final chunk in stream) {
      sink.add(chunk);
      received += chunk.length;
      onProgress?.call(total > 0 ? (received / total).clamp(0.0, 1.0) : 0);
    }
    await sink.close();

    File? thumbFile;
    try {
      final thumbUrl = video.thumbnails.highResUrl;
      if (thumbUrl.isNotEmpty) {
        onLog?.call('Downloading thumbnail...');
        final r = await http.get(Uri.parse(thumbUrl));
        if (r.statusCode == 200) {
          thumbFile = File('$tempDir/thumb_${video.id}.jpg');
          await thumbFile.writeAsBytes(r.bodyBytes);
        }
      }
    } catch (_) {}

    final outExt = format.name;
    final safeTitle = _sanitizeFileName(title);
    final outPath = '$outDir/$safeTitle.$outExt';

    final metaTitle = title.replaceAll('"', '\\"');
    final metaArtist = author.replaceAll('"', '\\"');

    String ffmpegCmd;
    if (format == OutputFormat.mp3) {
      if (thumbFile != null && thumbFile.existsSync()) {
        ffmpegCmd = '-y -i "$tempAudio" -i "${thumbFile.path}" -map 0:a -map 1 -c:a libmp3lame -q:a 2 -c:v mjpeg -metadata title="$metaTitle" -metadata artist="$metaArtist" -metadata album="$metaTitle" -id3v2_version 3 -metadata:s:v comment="Cover (front)" "$outPath"';
      } else {
        ffmpegCmd = '-y -i "$tempAudio" -vn -c:a libmp3lame -q:a 2 -metadata title="$metaTitle" -metadata artist="$metaArtist" -metadata album="$metaTitle" -id3v2_version 3 "$outPath"';
      }
    } else if (format == OutputFormat.flac) {
      if (thumbFile != null && thumbFile.existsSync()) {
        ffmpegCmd = '-y -i "$tempAudio" -i "${thumbFile.path}" -map 0:a -map 1 -c:a flac -c:v copy -metadata title="$metaTitle" -metadata artist="$metaArtist" -metadata album="$metaTitle" "$outPath"';
      } else {
        ffmpegCmd = '-y -i "$tempAudio" -vn -c:a flac -metadata title="$metaTitle" -metadata artist="$metaArtist" -metadata album="$metaTitle" "$outPath"';
      }
    } else {
      ffmpegCmd = '-y -i "$tempAudio" -vn -c:a pcm_s16le -metadata title="$metaTitle" -metadata artist="$metaArtist" "$outPath"';
    }

    onLog?.call('Converting with FFmpeg...');
    onProgress?.call(0.5);
    final session = await FFmpegKit.execute(ffmpegCmd);
    final code = await session.getReturnCode();
    try { await File(tempAudio).delete(); } catch (_) {}
    if (thumbFile != null) try { await thumbFile.delete(); } catch (_) {}

    if (ReturnCode.isSuccess(code)) {
      onLog?.call('Saved: $outPath');
      onProgress?.call(1.0);
    } else {
      final output = await session.getOutput();
      onLog?.call('FFmpeg error: $output');
    }
  }

  Future<void> _downloadVideo({
    required StreamManifest manifest,
    required Video video,
    required OutputFormat format,
    required String tempDir,
    required String outDir,
    void Function(String message)? onLog,
    void Function(double progress)? onProgress,
  }) async {
    final videoOnly = manifest.videoOnly;
    final audioOnly = manifest.audioOnly;
    if (videoOnly.isEmpty || audioOnly.isEmpty) {
      onLog?.call('Video or audio stream not available.');
      return;
    }
    final videoStream = videoOnly.last;
    final audioStream = audioOnly.withHighestBitrate();

    final tempVideo = '$tempDir/video_${video.id}.${videoStream.container.name}';
    final tempAudio = '$tempDir/audio_${video.id}.${audioStream.container.name}';

    onLog?.call('Downloading video stream...');
    var received = 0;
    final totalV = videoStream.size.totalBytes;
    final fileV = File(tempVideo);
    final sinkV = fileV.openWrite();
    await for (final chunk in _yt.videos.streamsClient.get(videoStream)) {
      sinkV.add(chunk);
      received += chunk.length;
      onProgress?.call(0.5 * (totalV > 0 ? (received / totalV) : 0));
    }
    await sinkV.close();

    onLog?.call('Downloading audio stream...');
    received = 0;
    final totalA = audioStream.size.totalBytes;
    final fileA = File(tempAudio);
    final sinkA = fileA.openWrite();
    await for (final chunk in _yt.videos.streamsClient.get(audioStream)) {
      sinkA.add(chunk);
      received += chunk.length;
      onProgress?.call(0.5 + 0.3 * (totalA > 0 ? (received / totalA) : 0));
    }
    await sinkA.close();

    final outExt = format.name;
    final safeTitle = _sanitizeFileName(video.title);
    final outPath = '$outDir/$safeTitle.$outExt';

    onLog?.call('Muxing with FFmpeg...');
    final ffmpegCmd = '-y -i "$tempVideo" -i "$tempAudio" -c copy "$outPath"';
    final session = await FFmpegKit.execute(ffmpegCmd);
    final code = await session.getReturnCode();
    try { await File(tempVideo).delete(); } catch (_) {}
    try { await File(tempAudio).delete(); } catch (_) {}

    if (ReturnCode.isSuccess(code)) {
      onLog?.call('Saved: $outPath');
      onProgress?.call(1.0);
    } else {
      final output = await session.getOutput();
      onLog?.call('FFmpeg error: $output');
    }
  }
}
