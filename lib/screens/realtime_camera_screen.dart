import 'dart:io';
import 'dart:convert';
import 'package:ai_traffic_app/screens/plates_screen.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../models/frame_result.dart';
import '../models/recognition_response.dart';
import '../services/recognition_service.dart';

class RealtimeCameraScreen extends StatefulWidget {
  const RealtimeCameraScreen({super.key});

  @override
  State<RealtimeCameraScreen> createState() =>
      _RealtimeCameraScreenState();
}
Widget _tabItem({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}
class _RealtimeCameraScreenState extends State<RealtimeCameraScreen> {
  final RecognitionService _service = RecognitionService();
  final ImagePicker _picker = ImagePicker();
  File? _selectedVideo;
  VideoPlayerController? _controller;
  bool _isLoading = false;
  RecognitionResponse? _result;
  FrameResult? _currentFrame;

  DateTime _lastUpdate = DateTime.now();

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

  /// 🧠 SYNC FRAME (có throttle)
  void _syncFrame() {
    if (_result == null || _controller == null) return;

    if (DateTime.now().difference(_lastUpdate).inMilliseconds < 200) {
      return;
    }

    _lastUpdate = DateTime.now();

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

  void _reset() {
    /// 🧠 GỠ listener để tránh leak + spam setState
    _controller?.removeListener(_syncFrame);

    /// ⏸ DỪNG video
    _controller?.pause();

    /// 💀 HUỶ player
    _controller?.dispose();

    /// 🧹 RESET TOÀN BỘ STATE
    setState(() {
      _selectedVideo = null;   // ❌ xoá video đã chọn
      _controller = null;      // ❌ xoá player
      _result = null;          // ❌ xoá kết quả AI
      _currentFrame = null;    // ❌ xoá frame hiện tại
      _isLoading = false;      // ❌ đảm bảo không còn loading
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
          /// 🔙 BACK
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          /// ⏯ PLAY / PAUSE
          Positioned(
            top: 40,
            right: 10,
            child: IconButton(
              icon: Icon(
                _controller?.value.isPlaying == true
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () {
                if (_controller == null) return;

                setState(() {
                  _controller!.value.isPlaying
                      ? _controller!.pause()
                      : _controller!.play();
                });
              },
            ),
          ),

          /// 🎬 VIDEO
          if (_controller != null && _controller!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: RepaintBoundary(
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),

          /// 💤 EMPTY UI
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
                    style: TextStyle(color: Colors.white54, fontSize: 18),
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
                    border: Border.all(color: Colors.green, width: 2),
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
              bottom: 170,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "🚗 ${_currentFrame!.vehicles.length} xe phát hiện"),
                    const SizedBox(height: 8),
                    ..._currentFrame!.vehicles.map((v) {
                      final confidence =
                          (v.plate?.confidence ?? v.confidence) * 100;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              v.plate?.text ?? "Không có biển",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "${confidence.toStringAsFixed(1)}%",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          /// 🎞 TIMELINE LIST (CÁI BẠN MUỐN)
          if (_result != null)
            Positioned(
              bottom: 70,
              left: 0,
              right: 0,
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _result!.results.length,
                itemBuilder: (context, index) {
                  final frame = _result!.results[index];

                  if (frame.vehicles.isEmpty) {
                    return const SizedBox();
                  }

                  return GestureDetector(
                    onTap: () {
                      _controller?.seekTo(
                        Duration(
                            milliseconds:
                            (frame.timestamp * 1000).toInt()),
                      );
                    },
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${frame.timestamp.toStringAsFixed(1)}s",
                            style:
                            const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${frame.vehicles.length} xe",
                            style:
                            const TextStyle(color: Colors.green),
                          ),
                          const SizedBox(height: 4),

                          /// 👇 nếu có ảnh base64 thì show thumbnail
                          if (frame.annotatedFrame != null)
                            Expanded(
                              child: Image.memory(
                                base64Decode(frame.annotatedFrame!),
                                fit: BoxFit.cover,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          /// 🎮 CONTROL BAR
          Positioned(
            bottom: 10,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric( vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [

                  // 📂 CHỌN VIDEO
                  _tabItem(
                    icon: Icons.video_library,
                    label: "Chọn video",
                    onTap: _pickAndUploadVideo,
                  ),

                  // 🎯 PHÂN TÍCH
                  GestureDetector(
                    onTap: () {
                      if (_result == null || _result!.plates.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Chưa có dữ liệu")),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlatesScreen(plates: _result!.plates),
                        ),
                      );
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.blue[900],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.analytics, color: Colors.white),
                    ),
                  ),

                  // 🔄 RESET
                  _tabItem(
                    icon: Icons.refresh,
                    label: "Reset",
                    onTap: _reset,
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}