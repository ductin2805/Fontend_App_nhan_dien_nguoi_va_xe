import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/history_item.dart';
import 'home_menu.dart';

class HistoryScreen extends StatefulWidget {
  static const Map<String, String> typeMap = {
    "face_recognition": "NHẬN DIỆN KHUÔN MẶT",
    "image_detection": "PHÂN TÍCH HÌNH ẢNH",
    "object_detection": "NHẬN DIỆN HÌNH ẢNH",
    "video_processing": "NHẬN DIỆN VIDEO",
    "detect_plates": "PHÂN TÍCH BIỂN SỐ",
    "face_registration": "NHẬP DATA",
  };

  ScrollController controller = ScrollController();
  String getTitle(String type) => typeMap[type] ?? type;
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> history = [];
  List<HistoryItem> filtered = [];
  int limit = 20;
  int offset = 0;

  bool isLoadingMore = false;
  bool hasMore = true;

  ScrollController controller = ScrollController();
  String keyword = "";
  bool vehicleOnly = false;

  final String baseUrl = "http://192.168.1.11:8000";

  @override
  @override
  void initState() {
    super.initState();
    loadHistory();

    controller.addListener(() {
      if (controller.position.pixels ==
          controller.position.maxScrollExtent) {
        loadMore();
      }
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
        filtered = data;
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

  String formatTime(double timestamp) {
    final date =
    DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt());
    return "${date.hour}:${date.minute} | ${date.day}/${date.month}/${date
        .year}";
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

    if (type.contains("pedestrian")) return Colors.green;
    if (type.contains("motor")) return Colors.blue;

    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lịch Sử"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HomeMenu()),
                  (route) => false,
            );
          },
        ),
      ),

      /// 🔥 FULL SCREEN BODY
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [


            SizedBox(height: 12),

            /// LIST
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: filtered.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {

                  // 🔥 loading item cuối
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

                  print("TYPE = ${item.type}");

                  return Container(
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

                        /// TEXT INFO
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              /// TYPE
                              Text(
                                getTitle(item.type),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: getColor(item.type),
                                ),
                              ),

                              const SizedBox(height: 6),

                              /// PLATE
                              Text(
                                plate,
                                style: const TextStyle(fontSize: 14),
                              ),

                              const SizedBox(height: 6),

                              /// TIME
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

                        /// ICON
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  );
                },
              ),
            ),

            /// FOOTER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("TỔNG SỐ LƯỢNG: ${filtered.length}"),
                ElevatedButton(
                  onPressed: () {},
                  child: Text("TẢI VỀ"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}