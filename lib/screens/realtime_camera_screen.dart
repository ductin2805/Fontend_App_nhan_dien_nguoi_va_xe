import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:collection/collection.dart';


import '../models/frame_result.dart';
import '../models/recognition_response.dart';
import '../services/recognition_service.dart';

class RealtimeCameraScreen extends StatefulWidget {
  const RealtimeCameraScreen({super.key});

  @override
  State<RealtimeCameraScreen> createState() =>
      _RealtimeCameraScreenState();
}

class _RealtimeCameraScreenState extends State<RealtimeCameraScreen> {
  final RecognitionService _service = RecognitionService();
  final ImagePicker _picker = ImagePicker();

  VideoPlayerController? _controller;

  bool _isLoading = false;
  RecognitionResponse? _result;
  FrameResult? _currentFrame;

  /// 🎬 PICK VIDEO
  Future<void> _pickAndUploadVideo() async {
    final XFile? video =
    await _picker.pickVideo(source: ImageSource.gallery);

    if (video == null) return;

    _controller?.dispose();

    _controller = VideoPlayerController.file(File(video.path));
    await _controller!.initialize();
    await _controller!.play();

    setState(() {
      _isLoading = true;
      _result = null;
      _currentFrame = null;
    });

    final response = await _service.recognizeVideo(video.path);

    _controller!.addListener(_syncFrame);

    setState(() {
      _result = response;
      _isLoading = false;
    });
  }

  /// 🧠 SYNC FRAME
  void _syncFrame() {
    if (_result == null || _controller == null) return;

    final time =
        _controller!.value.position.inMilliseconds / 1000.0;

    final frame = _result!.results.firstWhereOrNull(
          (f) => (f.timestamp - time).abs() < 0.3,
    );

    if (frame?.frameIndex != _currentFrame?.frameIndex) {
      setState(() {
        _currentFrame = frame;
      });
    }
  }

  /// 🔄 RESET
  void _reset() {
    setState(() {
      _result = null;
      _currentFrame = null;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// 🎬 VIDEO
          if (_controller != null &&
              _controller!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),

          if (_controller == null)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_collection,
                      size: 80, color: Colors.white38),
                  SizedBox(height: 20),
                  Text(
                    "Chưa chọn video",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

          /// 🟩 BOUNDING BOX
          if (_currentFrame != null &&
              _result != null &&
              _controller != null)
            ..._currentFrame!.vehicles.map((v) {
              final videoWidth =
              _result!.videoInfo.width.toDouble();
              final videoHeight =
              _result!.videoInfo.height.toDouble();

              final screenWidth =
                  MediaQuery.of(context).size.width;
              final screenHeight =
                  MediaQuery.of(context).size.height;

              final scaleX = screenWidth / videoWidth;
              final scaleY = screenHeight / videoHeight;

              return Positioned(
                left: v.bbox[0] * scaleX,
                top: v.bbox[1] * scaleY,
                width: (v.bbox[2] - v.bbox[0]) * scaleX,
                height: (v.bbox[3] - v.bbox[1]) * scaleY,
                child: Container(
                  decoration: BoxDecoration(
                    border:
                    Border.all(color: Colors.green, width: 2),
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      color: Colors.green,
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        "${v.plate?.text ?? ''} ${(v.confidence * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              );
            }),

          /// 📊 PANEL BIỂN SỐ
          if (_currentFrame != null &&
              _currentFrame!.vehicles.isNotEmpty)
            Positioned(
              bottom: 110,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                        "🚗 Tổng xe: ${_currentFrame!.vehicles.length}"),
                    const SizedBox(height: 8),
                    ..._currentFrame!.vehicles.map((v) =>
                        Container(
                          margin:
                          const EdgeInsets.only(bottom: 6),
                          padding:
                          const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                            children: [
                              Text(
                                  v.plate?.text ??
                                      "Không có biển"),
                              Text(
                                "${(v.confidence * 100).toStringAsFixed(1)}%",
                                style: const TextStyle(
                                    color: Colors.green),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),

          /// 🔴 STATUS
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius:
                BorderRadius.circular(10),
              ),
              child: const Text(
                "DETECTING...",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),

          /// 🎮 CONTROL BAR
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// 📁 CHỌN VIDEO
                  GestureDetector(
                    onTap: _pickAndUploadVideo,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.image, color: Colors.black54),
                        SizedBox(height: 4),
                        Text("Chọn Video",
                            style: TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),

                  /// 🔵 NÚT CHÍNH
                  GestureDetector(
                    onTap: _pickAndUploadVideo,
                    child: Container(
                      width: 65,
                      height: 65,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                    ),
                  ),

                  /// 🔄 RESET
                  GestureDetector(
                    onTap: _reset,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.refresh, color: Colors.black54),
                        SizedBox(height: 4),
                        Text("Reset",
                            style: TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ⏳ LOADING
          if (_isLoading)
            const Center(
                child:
                CircularProgressIndicator()),
        ],
      ),
    );
  }
}