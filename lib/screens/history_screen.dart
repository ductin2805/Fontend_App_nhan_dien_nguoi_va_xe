import 'package:ai_traffic_app/screens/setting_screen.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/history_item.dart';
import '../services/history_filter_service.dart';
import 'history_detail_screen.dart';
import 'home_menu.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  static const Map<String, String> typeMap = {
    "face_recognition": "NHẬN DIỆN KHUÔN MẶT",
    "image_detection": "PHÂN TÍCH BIỂN SỐ",
    "object_detection": "PHÂN TÍCH HÌNH ẢNH",
    "video_processing": "NHẬN DIỆN VIDEO",
    "detect_plates": "",
    "face_registration": "NHẬP DATA",
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

  final ScrollController controller = ScrollController();

  final String baseUrl = "http://192.168.1.11:8000";

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
      endpoint: selectedEndpoint,
      actionType: selectedType,
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
    final res = await HistoryFilterService.filter();

    setState(() {
      endpoints = List<String>.from(
        res["available_filter_values"]["endpoints"] ?? [],
      );

      actionTypes = List<String>.from(
        res["available_filter_values"]["action_types"] ?? [],
      );
    });
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
    path = path.trim();
    if (path.startsWith("/")) {
      path = path.substring(1);
    }
    return "$baseUrl/$path";
  }

  String getTitle(String? type) {
    if (type == null) return "UNKNOWN";

    final t = type.trim().toLowerCase();
    return HistoryScreen.typeMap[t] ?? type;
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
      appBar: AppBar(
        title: const Text("Lịch Sử"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
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
          ]
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// LIST
            Expanded(
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
                  final plate = item.plates.isNotEmpty
                      ? item.plates.first
                      : "KHÔNG XÁC ĐỊNH";

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
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                          )
                        ],
                      ),

                      child: Row(
                        children: [
                          // CHECKBOX (chỉ hiện khi select mode)
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
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [

                                Text(
                                  getTitle(item.type),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  plate,
                                  style: const TextStyle(fontSize: 14),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  formatTime(item.timestamp),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
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

            /// FOOTER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("TỔNG SỐ: ${filtered.length}"),
              ],
            )
          ],
        ),
      ),
    );
  }
}