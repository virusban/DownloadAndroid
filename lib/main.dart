import 'package:flutter/material.dart';

import 'services/download_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'yt-dlp Flutter Android',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DownloadScreen(),
    );
  }
}

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final _urlController = TextEditingController();
  final _logController = ScrollController();
  final _downloadService = DownloadService();

  OutputFormat _format = OutputFormat.mp3;
  bool _isLoading = false;
  double _progress = 0;
  final List<String> _logs = [];

  @override
  void dispose() {
    _urlController.dispose();
    _logController.dispose();
    _downloadService.dispose();
    super.dispose();
  }

  void _log(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} $message');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logController.hasClients) {
        _logController.animateTo(
          _logController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startDownload() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _log('Please paste a YouTube link.');
      return;
    }

    setState(() {
      _isLoading = true;
      _progress = 0;
      _logs.clear();
    });

    try {
      await _downloadService.download(
        urlOrId: url,
        format: _format,
        onLog: _log,
        onProgress: (p) => setState(() => _progress = p),
      );
    } catch (e, st) {
      _log('Error: $e');
      _log(st.toString().split('\n').take(3).join('\n'));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Download'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'YouTube URL',
                hintText: 'Paste link here',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              enabled: !_isLoading,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<OutputFormat>(
              // ignore: deprecated_member_use
              value: _format,
              decoration: const InputDecoration(
                labelText: 'Output format',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: OutputFormat.mp3, child: Text('Audio: MP3')),
                DropdownMenuItem(value: OutputFormat.flac, child: Text('Audio: FLAC')),
                DropdownMenuItem(value: OutputFormat.wav, child: Text('Audio: WAV')),
                DropdownMenuItem(value: OutputFormat.mp4, child: Text('Video: MP4')),
                DropdownMenuItem(value: OutputFormat.mkv, child: Text('Video: MKV')),
              ],
              onChanged: _isLoading ? null : (v) => setState(() => _format = v!),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isLoading ? null : _startDownload,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_isLoading ? 'Downloading...' : 'Download'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            const Text('Log', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                controller: _logController,
                padding: const EdgeInsets.all(8),
                itemCount: _logs.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: SelectableText(
                    _logs[i],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
