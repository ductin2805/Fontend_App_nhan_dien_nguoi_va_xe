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
  List<HistoryItem> filtered = [];
  Set<String> selectedIds = {};
  bool isSelectMode = false;
  int limit = 50;
  int offset = 0;

  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;

  List<String> actionTypes = [];
  String selectedType = "Tất cả";
  DateTimeRange? selectedDateRange;

  final ScrollController controller = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mặc định là ngày hôm nay
    final now = DateTime.now();
    selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day),
    );
    
    applyFilter(); 
    loadFilterValues();

    controller.addListener(() {
      if (controller.position.pixels >= controller.position.maxScrollExtent - 200) {
        loadMore();
      }
    });
  }

  Future<void> loadFilterValues() async {
    try {
      final res = await HistoryFilterService.filter();
      if (res["available_filter_values"] != null) {
        setState(() {
          actionTypes = List<String>.from(res["available_filter_values"]["action_types"] ?? []);
        });
      }
    } catch (e) {
      debugPrint("Load filter error: $e");
    }
  }

  Future<void> applyFilter({bool isLoadMore = false}) async {
    if (isLoading || (isLoadMore && !hasMore)) return;

    setState(() {
      if (!isLoadMore) {
        isLoading = true;
        offset = 0;
      } else {
        isLoadingMore = true;
      }
    });

    try {
      final res = await HistoryFilterService.filter(
        actionType: selectedType == "Tất cả" ? null : selectedType,
        startTime: selectedDateRange != null 
            ? selectedDateRange!.start.millisecondsSinceEpoch / 1000 
            : null,
        endTime: selectedDateRange != null 
            ? DateTime(selectedDateRange!.end.year, selectedDateRange!.end.month, selectedDateRange!.end.day, 23, 59, 59).millisecondsSinceEpoch / 1000 
            : null,
        limit: limit,
        offset: offset,
      );

      final List list = res["history"] ?? [];
      final newItems = list.map((e) => HistoryItem.fromJson(e)).toList();

      setState(() {
        if (isLoadMore) {
          filtered.addAll(newItems);
        } else {
          filtered = newItems;
        }
        offset += newItems.length;
        hasMore = newItems.length >= limit;
      });
    } catch (e) {
      debugPrint("FILTER ERROR: $e");
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  Future<void> loadMore() async {
    applyFilter(isLoadMore: true);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null && picked != selectedDateRange) {
      setState(() {
        selectedDateRange = picked;
      });
      applyFilter();
    }
  }

  void _resetFilters() {
    final now = DateTime.now();
    setState(() {
      selectedType = "Tất cả";
      selectedDateRange = DateTimeRange(
        start: DateTime(now.year, now.month, now.day),
        end: DateTime(now.year, now.month, now.day),
      );
    });
    applyFilter();
  }

  Future<void> deleteSelected() async {
    if (selectedIds.isEmpty) return;
    try {
      await ApiService.deleteHistory(selectedIds.toList());
      setState(() {
        filtered.removeWhere((e) => selectedIds.contains(e.id));
        selectedIds.clear();
        isSelectMode = false;
      });
    } catch (e) {
      debugPrint("DELETE ERROR: $e");
    }
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
          // Khu vực Bộ lọc
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildFilterDropdown(
                        label: "DANH MỤC",
                        value: selectedType,
                        items: ["Tất cả", ...actionTypes],
                        onChanged: (v) { if (v != null) { setState(() => selectedType = v); applyFilter(); } },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: () => _selectDateRange(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("KHOẢNG THỜI GIAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedDateRange == null 
                                      ? "Chọn ngày" 
                                      : "${selectedDateRange!.start.day}/${selectedDateRange!.start.month} - ${selectedDateRange!.end.day}/${selectedDateRange!.end.month}/${selectedDateRange!.end.year}", 
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.calendar_today, size: 14, color: Colors.blueAccent),
                              ],
                            ),
                            Container(height: 1, color: Colors.blueAccent.withOpacity(0.3), margin: const EdgeInsets.only(top: 8)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Danh sách kết quả
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => applyFilter(),
              child: isLoading && filtered.isEmpty 
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: controller,
                      itemCount: filtered.length + (hasMore ? 1 : 0),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemBuilder: (context, index) {
                        if (index == filtered.length) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                        return _buildHistoryCard(filtered[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("Không tìm thấy dữ liệu", style: TextStyle(color: Colors.grey, fontSize: 16)),
            TextButton(onPressed: _resetFilters, child: const Text("Đặt lại bộ lọc"))
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    final plate = item.plates.isNotEmpty ? item.plates.first : "KHÔNG XÁC ĐỊNH";
    return GestureDetector(
      onLongPress: () => setState(() { isSelectMode = true; selectedIds.add(item.id); }),
      onTap: () async {
        if (isSelectMode) {
          setState(() { if (selectedIds.contains(item.id)) selectedIds.remove(item.id); else selectedIds.add(item.id); });
        } else {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryDetailScreen(id: item.id)));
          if (result == true) applyFilter();
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
                    ? Image.network(ApiService.buildUrl(item.imagePath!), width: 85, height: 85, fit: BoxFit.cover)
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

  String formatTime(double timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt());
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')} | ${date.day}/${date.month}/${date.year}";
  }

  String formatPlate(String plate) {
    if (plate.isEmpty || plate == "KHÔNG XÁC ĐỊNH") return plate;
    String clean = plate.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
    if (clean.length == 8) return "${clean.substring(0, 3)}-${clean.substring(3)}";
    if (clean.length == 9) return "${clean.substring(0, 4)}-${clean.substring(4)}";
    return plate;
  }

  String getTitle(String? type) {
    if (type == null) return "KHÔNG XÁC ĐỊNH";
    return HistoryScreen.typeMap[type.trim().toLowerCase()] ?? type.toUpperCase();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
