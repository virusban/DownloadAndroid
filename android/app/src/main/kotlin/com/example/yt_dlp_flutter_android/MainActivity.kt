package com.example.yt_dlp_flutter_android

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Let Flutter handle plugin registration (required for platform channels
        // like path_provider). If you override this, you must call super.
        super.configureFlutterEngine(flutterEngine)
    }
}
