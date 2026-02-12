# yt-dlp Flutter Android

An Android (11+) Flutter application that allows downloading audio and video from YouTube  
using **youtube_explode_dart** (no yt-dlp binary) and converting media formats with  
**FFmpeg Kit** (**ffmpeg_kit_flutter_new**, no ffmpeg binary) — uses Dart packages and  
FFmpeg Kit’s native libraries.

> ⚠️ This project is intended **for educational and personal use only**.

---

## Overview

This project uses **youtube_explode_dart** to resolve YouTube streams and metadata and  
**ffmpeg_kit_flutter_new** (FFmpeg Kit) for conversion and metadata embedding. No external  
server, cloud, or Termux is required.

The app provides a simple single-screen interface where a user can paste a YouTube link,  
choose an output format, and download or convert media files on the device.

---

## Features

### Audio
- Download audio in the following formats:
  - MP3
  - FLAC
  - WAV
- Embedded metadata:
  - title
  - artist
  - album
  - thumbnail (cover art)

### Video
- Download video in:
  - MP4
  - MKV

### General
- youtube_explode_dart for YouTube; FFmpeg Kit for conversion (no yt-dlp/ffmpeg binaries)
- Processing on device
- No backend server
- No Termux dependency
- Single-screen UI
- Android 11+ support (Scoped Storage compliant)
- Step-by-step GitHub commits for learning purposes

---

## Architecture

The Flutter application uses **youtube_explode_dart** to get stream URLs and metadata,  
downloads the stream(s) with Dart, then uses **FFmpeg Kit** (ffmpeg_kit_flutter_new) to  
convert and embed metadata. Progress and errors are shown in the UI.

---

## Requirements

### Development
- Windows 11
- Flutter (stable channel)
- Android Studio
- Android SDK
- Android device or emulator (Android 11+)

### Runtime
- Android 11 or newer
- Storage access permission

---

## Legal Notice and Disclaimer

This application must not be published on Google Play.  
Downloading content from YouTube may violate YouTube’s Terms of Service.  
The author of this project does not encourage or promote copyright infringement.  
The developer is not responsible for how this application is used.  
This project is provided strictly for educational and personal experimentation.

---

## Project Goals

This repository is designed as a learning project with:
- Clear project structure
- Small, logical commits
- Detailed explanations of each development step
- Focus on understanding how Flutter interacts with native binaries on Android

Created as an educational Flutter + Android project.  
The repository is developed step by step with frequent commits to clearly document the learning process and implementation details.

---

## How to Build the App

Make sure your Android device or emulator is running Android 11 or newer and has storage access permissions enabled.

### Generated APK location
build/app/outputs/flutter-apk/app-release.apk

### Build command

```bash
flutter build apk --release
