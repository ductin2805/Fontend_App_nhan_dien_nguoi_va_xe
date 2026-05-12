import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/history_item.dart';
import '../services/history_filter_service.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  static const Map<String, String> typeMap = {
    "face_recognition": "NHẬN DIỆN KHUÔN MẶT",
    "image_detection": "PHÂN TÍCH BIỂN SỐ",
    "object_detection": "PHÂN TÍCH HÌNH ẢNH",
    "video_processing": "NHẬN DIỆN VIDEO",
    "detect_plates": "NHẬN DIỆN BIỂN SỐ",
    "plate_recognition": "NHẬN DIỆN BIỂN SỐ",
    "face_registration": "NHẬP DỮ LIỆU",
    "live_camera": "CAMERA TRỰC TIẾP",
    "live_camera_frame": "FRAME CAMERA",
  };

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> history = [];
  List<HistoryItem> filtered = [];
  Set<String> selectedIds = {};
  bool isSelectMode = false;
  int limit = 20;
  int offset = 0;

  bool isLoadingMore = false;
  bool hasMore = true;

  List<String> actionTypes = [];
  String selectedType = "Tất cả";

  final ScrollController controller = ScrollController();

  @override
  void initState() {
    super.initState();
    loadHistory();
    loadFilterValues();

    controller.addListener(() {
      if (controller.position.pixels == controller.position.maxScrollExtent) {
        loadMore();
      }
    });
  }

  Future<void> applyFilter() async {
    final res = await HistoryFilterService.filter(
      actionType: selectedType == "Tất cả" ? null : selectedType,
    );
    final list = res["history"] as List;
    setState(() {
      filtered = list.map((e) => HistoryItem.fromJson(e)).toList();
    });
  }

  Future<void> loadHistory() async {
    try {
      final data = await ApiService.getHistory(limit: limit, offset: 0);
      setState(() {
        history = data;
        filtered = data.where((e) => e.type != null).toList();
        offset = limit;
        hasMore = data.length == limit;
      });
    } catch (e) {
      debugPrint("ERROR: $e");
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore) return;
    isLoadingMore = true;
    try {
      final newData = await ApiService.getHistory(limit: limit, offset: offset);
      setState(() {
        history.addAll(newData);
        filtered = history;
        offset += limit;
        hasMore = newData.length == limit;
      });
    } catch (e) {
      debugPrint("LOAD MORE ERROR: $e");
    }
    isLoadingMore = false;
  }

  Future<void> loadFilterValues() async {
    try {
      final res = await HistoryFilterService.filter();
      setState(() {
        actionTypes = List<String>.from(res["available_filter_values"]["action_types"] ?? []);
      });
    } catch (e) {
      debugPrint("Load filter error: $e");
    }
  }

  Future<void> deleteSelected() async {
    if (selectedIds.isEmpty) return;
    try {
      await ApiService.deleteHistory(selectedIds.toList());
      setState(() {
        filtered.removeWhere((e) => selectedIds.contains(e.id));
        history.removeWhere((e) => selectedIds.contains(e.id));
        selectedIds.clear();
        isSelectMode = false;
      });
    } catch (e) {
      debugPrint("DELETE ERROR: $e");
    }
  }

  String formatTime(double timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt());
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')} | ${date.day}/${date.month}/${date.year}";
  }

  String formatPlate(String plate) {
    if (plate.isEmpty || plate == "KHÔNG XÁC ĐỊNH") return plate;
    
    // LOG ĐÃ CẬP NHẬT - HÃY KIỂM TRA DÒNG NÀY TRONG CONSOLE
    debugPrint(">>> FINAL_UI_PLATE_DATA: '$plate' (Len: ${plate.length})");

    String clean = plate.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();

    // 🚗 Ô TÔ (8 ký tự): 61A66666 -> 61A-66666
    if (clean.length == 8) {
      return "${clean.substring(0, 3)}-${clean.substring(3)}";
    } 
    // 🏍 XE MÁY (9 ký tự): 67B284061 -> 67B2-84061
    else if (clean.length == 9) {
      return "${clean.substring(0, 4)}-${clean.substring(4)}";
    }

    return plate;
  }

  String buildImageUrl(String path) {
    return ApiService.buildUrl(path);
  }

  String getTitle(String? type) {
    if (type == null) return "KHÔNG XÁC ĐỊNH";
    final t = type.trim().toLowerCase();
    return HistoryScreen.typeMap[t] ?? type.toUpperCase();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        title: const Text("Lịch Sử"),
        actions: [
          if (isSelectMode) ...[
            IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { isSelectMode = false; selectedIds.clear(); })),
            IconButton(icon: const Icon(Icons.delete), onPressed: deleteSelected),
          ]
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: _buildFilterDropdown(
              label: "LOẠI DANH MỤC",
              value: selectedType,
              items: ["Tất cả", ...actionTypes],
              onChanged: (v) { if (v != null) { setState(() => selectedType = v); applyFilter(); } },
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: filtered.length + (hasMore ? 1 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemBuilder: (context, index) {
                if (index == filtered.length) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                
                final item = filtered[index];
                final plate = item.plates.isNotEmpty ? item.plates.first : "KHÔNG XÁC ĐỊNH";

                return GestureDetector(
                  onLongPress: () => setState(() { isSelectMode = true; selectedIds.add(item.id); }),
                  onTap: () async {
                    if (isSelectMode) {
                      setState(() { if (selectedIds.contains(item.id)) selectedIds.remove(item.id); else selectedIds.add(item.id); });
                    } else {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryDetailScreen(id: item.id)));
                      if (result == true) loadHistory();
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          if (isSelectMode) Checkbox(value: selectedIds.contains(item.id), onChanged: (v) => setState(() { if (v == true) selectedIds.add(item.id); else selectedIds.remove(item.id); })),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: (item.imagePath != null && item.imagePath!.isNotEmpty)
                                ? Image.network(buildImageUrl(item.imagePath!), width: 85, height: 85, fit: BoxFit.cover)
                                : Container(width: 85, height: 85, color: Colors.grey[200], child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(getTitle(item.type), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
                                const SizedBox(height: 5),
                                Text(formatPlate(plate), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF2C3E50), letterSpacing: 0.5)),
                                const SizedBox(height: 8),
                                Text(formatTime(item.timestamp), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({required String label, required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        DropdownButton<String>(
          isExpanded: true,
          value: items.contains(value) ? value : items.first,
          underline: Container(height: 1, color: Colors.blueAccent.withOpacity(0.3)),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e == "Tất cả" ? "Tất cả dữ liệu" : getTitle(e), style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
