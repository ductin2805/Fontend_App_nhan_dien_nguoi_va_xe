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
    "face_registration": "NHẬP DỮ LIỆU",
    "live_camera": "CAMERA TRỰC TIẾP",
    "live_camera_frame": "FRAME CAMERA",
  };

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}
List<String> endpoints = [];
List<String> actionTypes = [];
String? selectedEndpoint;
String? selectedType;
String? keyword;
class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> history = [];
  List<HistoryItem> filtered = [];
  Set<String> selectedIds = {};
  bool isSelectMode = false;
  int limit = 20;
  int offset = 0;

  bool isLoadingMore = false;
  bool hasMore = true;

  // Filter states
  List<String> actionTypes = [];
  String selectedType = "Tất cả";

  final ScrollController controller = ScrollController();


  @override
  void initState() {
    super.initState();
    loadHistory();
    loadFilterValues();

    controller.addListener(() {
      if (controller.position.pixels ==
          controller.position.maxScrollExtent) {
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
      final data = await ApiService.getHistory(
        limit: limit,
        offset: 0,
      );

      setState(() {
        history = data;
        filtered = data.where((e) => e.type != null).toList();
        offset = limit;
        hasMore = data.length == limit;
      });
    } catch (e) {
      print("ERROR: $e");
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore) return;

    isLoadingMore = true;

    try {
      final newData = await ApiService.getHistory(
        limit: limit,
        offset: offset,
      );

      setState(() {
        history.addAll(newData);
        filtered = history;
        offset += limit;
        hasMore = newData.length == limit;
      });
    } catch (e) {
      print("LOAD MORE ERROR: $e");
    }

    isLoadingMore = false;
  }
  Future<void> loadFilterValues() async {
    try {
      final res = await HistoryFilterService.filter();
      setState(() {
        actionTypes = List<String>.from(
          res["available_filter_values"]["action_types"] ?? [],
        );
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
      print("DELETE ERROR: $e");
    }
  }
  String formatTime(double timestamp) {
    final date =
    DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt());
    return "${date.hour}:${date.minute} | ${date.day}/${date.month}/${date.year}";
  }

  String buildImageUrl(String path) {
    return ApiService.buildUrl(path);
  }

  String getTitle(String? type) {
    if (type == null) return "KHÔNG XÁC ĐỊNH";

    final t = type.trim().toLowerCase();
    return HistoryScreen.typeMap[t] ?? type.toUpperCase();
  }

  Color getColor(String? type) {
    if (type == null) return Colors.black;
    return Colors.black;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isSelectMode) ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  isSelectMode = false;
                  selectedIds.clear();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: deleteSelected,
            ),
          ]
        ],
      ),
      body: Column(
        children: [
          // BỘ LỌC (FILTER BAR)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterDropdown(
                    label: "LOẠI DANH MỤC",
                    value: selectedType,
                    items: ["Tất cả", ...actionTypes],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => selectedType = v);
                        applyFilter();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          /// LIST
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.builder(
                controller: controller,
                itemCount: filtered.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  /// loading cuối
                  if (index == filtered.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final item = filtered[index];
                  final imagePath = item.imagePath;
                  final plate = item.plates.isNotEmpty ? item.plates.first : "KHÔNG XÁC ĐỊNH";

                  return GestureDetector(
                    onLongPress: () {
                      setState(() {
                        isSelectMode = true;
                        selectedIds.add(item.id);
                      });
                    },
                    onTap: () async {
                      if (isSelectMode) {
                        setState(() {
                          if (selectedIds.contains(item.id)) {
                            selectedIds.remove(item.id);
                          } else {
                            selectedIds.add(item.id);
                          }
                        });
                      } else {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HistoryDetailScreen(id: item.id),
                          ),
                        );
                        if (result == true) {
                          loadHistory();
                        }
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Row(
                        children: [
                          if (isSelectMode)
                            Checkbox(
                              value: selectedIds.contains(item.id),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedIds.add(item.id);
                                  } else {
                                    selectedIds.remove(item.id);
                                  }
                                });
                              },
                            ),

                          /// IMAGE
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: imagePath != null && imagePath.isNotEmpty
                                ? Image.network(
                                    buildImageUrl(imagePath),
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 90,
                                    height: 90,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image),
                                  ),
                          ),

                          const SizedBox(width: 12),

                          /// TEXT
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getTitle(item.type),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(plate, style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                                const SizedBox(height: 6),
                                Text(
                                  formatTime(item.timestamp),
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          /// FOOTER
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Dòng hiển thị: ${filtered.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
                letterSpacing: 1)),
        DropdownButton<String>(
          isExpanded: true,
          value: items.contains(value) ? value : items.first,
          underline: Container(height: 1, color: Colors.blueAccent.withOpacity(0.3)),
          icon: const Icon(Icons.filter_list, size: 18, color: Colors.blueAccent),
          items: items.map((e) {
            String display = e == "Tất cả" ? "Tất cả dữ liệu" : getTitle(e);
            return DropdownMenuItem(
              value: e,
              child: Text(display,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}