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

class _RealtimeCameraScreenState extends State<RealtimeCameraScreen> {
  final RecognitionService _service = RecognitionService();
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _controller;
  bool _isLoading = false;
  RecognitionResponse? _result;
  FrameResult? _currentFrame;

  int _frameSkip = 30;
  int _maxFrames = 50;
  bool _onlyValidPlates = false;

  DateTime _lastUpdate = DateTime.now();

  bool _isPlateFormatValid(String? plate) {
    if (plate == null || plate.isEmpty) return false;
    final cleanPlate = plate.replaceAll(RegExp(r'[\s\.\-]'), '').toUpperCase();
    final regExp = RegExp(r'^[0-9]{2}[A-Z][0-9A-Z]?[0-9]{4,6}$');
    return regExp.hasMatch(cleanPlate);
  }

  Future<void> _pickAndUploadVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
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

    try {
      final response = await _service.recognizeVideo(
        video.path,
        frameSkip: _frameSkip,
        maxFrames: _maxFrames,
      );
      _controller!.addListener(_syncFrame);
      setState(() {
        _result = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  void _syncFrame() {
    if (_result == null || _controller == null) return;
    if (DateTime.now().difference(_lastUpdate).inMilliseconds < 200) return;
    _lastUpdate = DateTime.now();

    final time = _controller!.value.position.inMilliseconds / 1000.0;
    final frame = _result!.results.firstWhereOrNull((f) => (f.timestamp - time).abs() < 0.3);
    if (frame?.frameIndex != _currentFrame?.frameIndex) {
      setState(() => _currentFrame = frame);
    }
  }

  void _reset() {
    _controller?.removeListener(_syncFrame);
    _controller?.dispose();
    setState(() {
      _controller = null;
      _result = null;
      _currentFrame = null;
      _isLoading = false;
    });
  }

  Widget _buildConfigItem(String label, int value, Function(int) onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove_circle_outline, color: Colors.white, size: 18),
              onPressed: () => onChanged(value > 5 ? value - 5 : 1),
            ),
            Text("$value", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
              onPressed: () => onChanged(value + 5),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildToggleItem(String label, bool value, Function(bool) onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blueAccent,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _tabItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 10))]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredFrames = _result?.results.where((frame) {
      if (frame.vehicles.isEmpty) return false;
      if (!_onlyValidPlates) return true;
      return frame.vehicles.any((v) => _isPlateFormatValid(v.plate?.text));
    }).toList() ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            Center(child: AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!))),
          
          if (_controller == null)
            const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_collection, size: 80, color: Colors.white38), Text("Chưa chọn video", style: TextStyle(color: Colors.white54))])),

          Positioned(
            top: 40, left: 10, right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                if (_controller != null)
                  IconButton(
                    icon: Icon(_controller!.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                    onPressed: () => setState(() => _controller!.value.isPlaying ? _controller!.pause() : _controller!.play()),
                  ),
              ],
            ),
          ),

          if (_currentFrame != null && _currentFrame!.vehicles.isNotEmpty)
            Positioned(
              bottom: 270, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _currentFrame!.vehicles.take(3).map((v) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(v.plate?.text ?? "NO PLATE", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("${((v.plate?.confidence ?? v.confidence) * 100).toStringAsFixed(0)}%", style: const TextStyle(color: Colors.green)),
                    ],
                  )).toList(),
                ),
              ),
            ),

          if (_result != null)
            Positioned(
              bottom: 175, left: 0, right: 0, height: 85,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: filteredFrames.length,
                itemBuilder: (context, index) {
                  final frame = filteredFrames[index];
                  return GestureDetector(
                    onTap: () => _controller?.seekTo(Duration(milliseconds: (frame.timestamp * 1000).toInt())),
                    child: Container(
                      width: 100, margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _currentFrame?.frameIndex == frame.frameIndex ? Colors.blue : Colors.white24, width: 2),
                        image: frame.annotatedFrame != null ? DecorationImage(image: MemoryImage(base64Decode(frame.annotatedFrame!)), fit: BoxFit.cover) : null,
                      ),
                      child: Container(
                        alignment: Alignment.bottomCenter, padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)])),
                        child: Text("${frame.timestamp.toStringAsFixed(1)}s", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                },
              ),
            ),

          Positioned(
            bottom: 10, left: 15, right: 15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(25)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildConfigItem("SKIP", _frameSkip, (v) => setState(() => _frameSkip = v)),
                      _buildConfigItem("MAX", _maxFrames, (v) => setState(() => _maxFrames = v)),
                      _buildToggleItem("BIỂN CHUẨN", _onlyValidPlates, (v) => setState(() => _onlyValidPlates = v)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(35)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _tabItem(icon: Icons.video_library, label: "Chọn video", onTap: _pickAndUploadVideo),
                      GestureDetector(
                        onTap: () {
                          if (_result == null) return;
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PlatesScreen(plates: _result!.plates)));
                        },
                        child: Container(width: 55, height: 55, decoration: const BoxDecoration(color: Color(0xFF0F4C75), shape: BoxShape.circle), child: const Icon(Icons.analytics, color: Colors.white)),
                      ),
                      _tabItem(icon: Icons.refresh, label: "Làm mới", onTap: _reset),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            Container(color: Colors.black54, child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: Colors.white), SizedBox(height: 16), Text("Đang phân tích...", style: TextStyle(color: Colors.white))]))),
        ],
      ),
    );
  }
}
