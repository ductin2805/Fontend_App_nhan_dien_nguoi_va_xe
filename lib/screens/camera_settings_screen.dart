import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class CameraSettingsScreen extends StatefulWidget {
  const CameraSettingsScreen({super.key});

  @override
  State<CameraSettingsScreen> createState() => _CameraSettingsScreenState();
}

class _CameraSettingsScreenState extends State<CameraSettingsScreen> {
  Map<String, dynamic>? options;
  bool isLoading = true;

  // Selected values
  String selectedPreset = "high";
  double fps = 15;
  double jpegQuality = 85;
  double zoom = 1.4;
  double exposure = 0.0;
  
  double detectConf = 0.25;
  double detectImgsz = 640;
  double faceThreshold = 0.55;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final res = await ApiService.getLiveCameraOptions();
      final saved = StorageService.getMap("camera_settings");

      setState(() {
        options = res;
        final liveCam = res['live_camera'];
        final liveQuery = res['live_query'];
        
        if (saved != null) {
          final f = saved['flutter'];
          final b = saved['backend'];
          selectedPreset = f['resolution'] ?? liveCam['resolution_preset']['default'];
          fps = (f['fps'] ?? liveCam['fps']['default']).toDouble();
          jpegQuality = (f['quality'] ?? liveCam['jpeg_quality']['default']).toDouble();
          zoom = (f['zoom'] ?? liveCam['zoom']['default']).toDouble();
          exposure = (f['exposure'] ?? liveCam['exposure_offset']['default']).toDouble();
          
          detectConf = (b['conf'] ?? liveQuery['detect_conf']['default']).toDouble();
          detectImgsz = (b['imgsz'] ?? liveQuery['detect_imgsz']['default']).toDouble();
          faceThreshold = (b['face_threshold'] ?? liveQuery['face_threshold']['default']).toDouble();
        } else {
          selectedPreset = liveCam['resolution_preset']['default'];
          fps = liveCam['fps']['default'].toDouble();
          jpegQuality = liveCam['jpeg_quality']['default'].toDouble();
          zoom = liveCam['zoom']['default'].toDouble();
          exposure = liveCam['exposure_offset']['default'].toDouble();
          
          detectConf = liveQuery['detect_conf']['default'].toDouble();
          detectImgsz = liveQuery['detect_imgsz']['default'].toDouble();
          faceThreshold = liveQuery['face_threshold']['default'].toDouble();
        }
        
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final data = {
      'flutter': {
        'resolution': selectedPreset,
        'fps': fps,
        'quality': jpegQuality,
        'zoom': zoom,
        'exposure': exposure,
      },
      'backend': {
        'conf': detectConf,
        'imgsz': detectImgsz,
        'face_threshold': faceThreshold,
      }
    };
    await StorageService.setMap("camera_settings", data);
    if (mounted) {
      Navigator.pop(context, data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã lưu cấu hình thành công")),
      );
    }
  }

  String _translatePresetName(String name) {
    switch (name) {
      case 'balanced': return "CÂN BẰNG";
      case 'accuracy_first': return "ĐỘ CHÍNH XÁC";
      case 'performance_first': return "HIỆU NĂNG";
      case 'low_light': return "THIẾU SÁNG";
      default: return name.toUpperCase().replaceAll("_", " ");
    }
  }

  void _applyPreset(String name, Map<String, dynamic> preset) {
    setState(() {
      final f = preset['flutter'];
      final b = preset['backend'];
      
      selectedPreset = f['resolution_preset'];
      fps = f['fps'].toDouble();
      jpegQuality = f['jpeg_quality'].toDouble();
      zoom = f['zoom'].toDouble();
      exposure = f['exposure_offset'].toDouble();

      detectConf = b['detect_conf'].toDouble();
      detectImgsz = b['detect_imgsz'].toDouble();
      faceThreshold = b['face_threshold'].toDouble();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đã áp dụng: ${_translatePresetName(name)}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (options == null) return const Scaffold(body: Center(child: Text("Không có dữ liệu cấu hình")));

    final liveCam = options!['live_camera'];
    final liveQuery = options!['live_query'];
    final presets = options!['presets'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        title: const Text("CẤU HÌNH CAMERA LIVE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline, size: 28),
            onPressed: _saveSettings,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // QUICK PRESETS
          _buildSectionTitle("CẤU HÌNH NHANH (PRESETS)"),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: presets.keys.map((key) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(_translatePresetName(key)),
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
                    onPressed: () => _applyPreset(key, presets[key]),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionTitle("THÔNG SỐ CAMERA (THIẾT BỊ)"),
          _buildCard([
            _buildDropdown("Độ phân giải", selectedPreset, liveCam['resolution_preset']['options'].cast<String>(), (v) {
              setState(() => selectedPreset = v!);
            }, note: liveCam['resolution_preset']['notes']),
            
            _buildSlider("Tốc độ khung hình (FPS)", fps, liveCam['fps']['min'].toDouble(), liveCam['fps']['max'].toDouble(), (v) {
              setState(() => fps = v);
            }, note: liveCam['fps']['notes']),
            
            _buildSlider("Chất lượng ảnh (JPEG)", jpegQuality, liveCam['jpeg_quality']['min'].toDouble(), liveCam['jpeg_quality']['max'].toDouble(), (v) {
              setState(() => jpegQuality = v);
            }, note: liveCam['jpeg_quality']['notes']),
            
            _buildSlider("Độ thu phóng (Zoom)", zoom, liveCam['zoom']['min'].toDouble(), liveCam['zoom']['max'].toDouble(), (v) {
              setState(() => zoom = v);
            }, note: liveCam['zoom']['notes']),
            
            _buildSlider("Bù trừ phơi sáng", exposure, liveCam['exposure_offset']['min'].toDouble(), liveCam['exposure_offset']['max'].toDouble(), (v) {
              setState(() => exposure = v);
            }, note: liveCam['exposure_offset']['notes']),
          ]),

          const SizedBox(height: 20),
          _buildSectionTitle("THAM SỐ PHÂN TÍCH (SERVER AI)"),
          _buildCard([
            _buildSlider("Độ tin cậy nhận diện", detectConf, liveQuery['detect_conf']['min'].toDouble(), liveQuery['detect_conf']['max'].toDouble(), (v) {
              setState(() => detectConf = v);
            }),
            
            _buildSlider("Kích thước ảnh xử lý", detectImgsz, liveQuery['detect_imgsz']['min'].toDouble(), liveQuery['detect_imgsz']['max'].toDouble(), (v) {
              setState(() => detectImgsz = v);
            }, divisions: 10),
            
            _buildSlider("Ngưỡng nhận diện khuôn mặt", faceThreshold, liveQuery['face_threshold']['min'].toDouble(), liveQuery['face_threshold']['max'].toDouble(), (v) {
              setState(() => faceThreshold = v);
            }),
          ]),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey, letterSpacing: 1)),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      padding: const EdgeInsets.all(16),
      child: Column(children: children),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged, {int? divisions, String? note}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(value.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions ?? 20,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.blue.shade50,
            onChanged: onChanged,
          ),
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text("• $note", style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
          ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, {String? note}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            DropdownButton<String>(
              value: value,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)))).toList(),
              onChanged: onChanged,
            )
          ],
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text("• $note", style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
          ),
      ],
    );
  }
}
