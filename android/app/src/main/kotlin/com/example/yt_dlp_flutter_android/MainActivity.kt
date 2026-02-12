package com.example.yt_dlp_flutter_android

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    // Explicitly register plugins. Some setups (custom engines / certain builds)
    // can fail to auto-register, which breaks platform channels (e.g. path_provider).
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}
