import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class RealtimeLiveScreen extends StatefulWidget {
  const RealtimeLiveScreen({super.key});

  @override
  State<RealtimeLiveScreen> createState() => _RealtimeLiveScreenState();
}

class _RealtimeLiveScreenState extends State<RealtimeLiveScreen> {
  CameraController? _controller;
  bool _isProcessing = false;
  Map<String, dynamic>? _analysisResult;
  Uint8List? _annotatedFrame;
  Timer? _timer;

  // Cấu hình hiện tại
  Map<String, dynamic>? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndInit();
  }

  Future<void> _loadSettingsAndInit() async {
    _settings = StorageService.getMap("camera_settings");
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Lấy resolution từ settings hoặc mặc định high
    String resKey = _settings?['flutter']?['resolution'] ?? 'high';
    ResolutionPreset preset = _getResolutionPreset(resKey);

    _controller = CameraController(
      cameras.first,
      preset,
      enableAudio: false,
    );

    await _controller!.initialize();
    
    // Đảm bảo zoom level nằm trong khoảng cho phép của thiết bị
    double minZoom = await _controller!.getMinZoomLevel();
    double maxZoom = await _controller!.getMaxZoomLevel();

    if (_settings != null) {
      double zoom = (_settings!['flutter']['zoom'] ?? 1.0).toDouble();
      // Chốt giá trị zoom trong tầm thiết bị hỗ trợ
      double finalZoom = zoom.clamp(minZoom, maxZoom);
      await _controller!.setZoomLevel(finalZoom);
      
      double exposure = (_settings!['flutter']['exposure'] ?? 0.0).toDouble();
      await _controller!.setExposureOffset(exposure);
    } else {
      // Nếu không có settings, ép về mức 1.0 để tránh góc siêu rộng 0.5
      await _controller!.setZoomLevel(1.0.clamp(minZoom, maxZoom));
    }

    if (!mounted) return;
    setState(() {});

    double fps = (_settings?['flutter']?['fps'] ?? 15).toDouble();
    // Tính toán interval thực tế hơn
    int intervalMs = (1000 / (fps / 5)).toInt().clamp(800, 3000); 

    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      _captureAndAnalyze();
    });
  }

  ResolutionPreset _getResolutionPreset(String preset) {
    switch (preset) {
      case 'low': return ResolutionPreset.low;
      case 'medium': return ResolutionPreset.medium;
      case 'high': return ResolutionPreset.high;
      case 'veryHigh': return ResolutionPreset.veryHigh;
      default: return ResolutionPreset.high;
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    try {
      _isProcessing = true;
      if (mounted) setState(() {});

      final XFile file = await _controller!.takePicture();
      
      String query = "include_annotated=true&save_history=true";
      if (_settings != null && _settings!['backend'] != null) {
        final b = _settings!['backend'];
        query += "&detect_conf=${b['conf']}";
        query += "&detect_imgsz=${b['imgsz'].toInt()}";
        query += "&face_threshold=${b['face_threshold']}";
      }

      final result = await ApiService.sendImage(
        File(file.path), 
        endpoint: "recognize-live-frame?$query"
      );
      
      if (mounted) {
        setState(() {
          _analysisResult = result;
          // Kiểm tra kỹ dữ liệu base64 trước khi gán
          final String? frameBase64 = result['annotated_frame'];
          if (frameBase64 != null && frameBase64.length > 100) {
            try {
              _annotatedFrame = base64Decode(frameBase64);
            } catch (e) {
              _annotatedFrame = null;
            }
          }
          _isProcessing = false;
        });
      }
      
      await File(file.path).delete();
    } catch (e) {
      debugPrint("Lỗi phân tích live frame: $e");
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    final summary = _analysisResult?['summary'];
    final plates = summary?['plates_found'] as List? ?? [];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("AI LIVE TRAFFIC", style: TextStyle(letterSpacing: 2, fontSize: 14)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. FULL SCREEN CAMERA PREVIEW
          SizedBox(
            width: size.width,
            height: size.height,
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: size.width,
                  height: size.width / _controller!.value.aspectRatio,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),
          ),

          // 2. AI ANNOTATED FRAME OVERLAY
          if (_annotatedFrame != null)
            SizedBox(
              width: size.width,
              height: size.height,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: size.width,
                    height: size.width / _controller!.value.aspectRatio,
                    child: Image.memory(_annotatedFrame!, gaplessPlayback: true),
                  ),
                ),
              ),
            ),

          // 3. TOP SCANNING OVERLAY (Gradient)
          Positioned(
            top: 0, left: 0, right: 0,
            height: 150,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
            ),
          ),

          // 4. ANALYZING STATUS
          if (_isProcessing)
            Positioned(
              top: 100,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 10)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 10),
                      Text("HỆ THỐNG ĐANG PHÂN TÍCH...", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

          // 5. BOTTOM RESULT PANEL (Glassmorphism)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: size.height * 0.32,
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
              decoration: BoxDecoration(
                color: const Color(0xFF121212).withOpacity(0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("DỮ LIỆU THỜI GIAN THỰC", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      _buildModernStatCard("PHƯƠNG TIỆN", "${summary?['total_vehicles'] ?? 0}", Icons.directions_car_filled, Colors.blue),
                      const SizedBox(width: 12),
                      _buildModernStatCard("BIỂN SỐ", "${summary?['total_plates'] ?? 0}", Icons.qr_code_scanner, Colors.green),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.list_alt, color: Colors.white54, size: 14),
                      SizedBox(width: 5),
                      Text("DANH SÁCH BIỂN SỐ GẦN NHẤT", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  Expanded(
                    child: plates.isEmpty 
                      ? Center(child: Text("ĐANG QUÉT KHU VỰC...", style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12, letterSpacing: 2)))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: plates.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.check, color: Colors.green, size: 14),
                                  ),
                                  const SizedBox(width: 15),
                                  Text(
                                    plates[index].toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, fontFamily: 'monospace'),
                                  ),
                                  const Spacer(),
                                  const Text("DETECTED", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}