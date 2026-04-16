import 'package:flutter/material.dart';
import '../models/plate_summary.dart';

class PlatesScreen extends StatelessWidget {
  final List<PlateSummary> plates;

  const PlatesScreen({super.key, required this.plates});
  String formatPlate(String plate) {
    if (plate.length >= 9) {
      return "${plate.substring(0, 4)}-${plate.substring(4)}";
    }
    return plate;
  }
  @override
  Widget build(BuildContext context) {
    final filteredPlates = plates;

    /// 🎨 ICON
    IconData getIcon(String className) {
      switch (className.toLowerCase()) {
        case "motorcycle":
          return Icons.motorcycle;
        case "car":
          return Icons.directions_car;
        default:
          return Icons.help_outline;
      }
    }

    Color getColor(String className) {
      switch (className.toLowerCase()) {
        case "motorcycle":
          return Colors.orange;
        case "car":
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }
    Widget _row(String title, dynamic value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(
              value == null || value.toString().isEmpty
                  ? "Không có"
                  : value.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh sách biển số"),
        centerTitle: true,
      ),
      body: filteredPlates.isEmpty
          ? const Center(child: Text("Không có dữ liệu"))
          : ListView.builder(
        itemCount: filteredPlates.length,
        itemBuilder: (context, index) {
          final p = filteredPlates[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              leading: Icon(
                getIcon(p.className),
                color: getColor(p.className),
              ),

              // 🔹 SECTION 1 (NGẮN GỌN)
              title: Text(
                formatPlate(p.plate),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${p.className} • ${p.count} lần"),

                  // 👤 OWNER
                  Text(
                    p.owner != null && p.owner!.found
                        ? "👤 ${p.owner!.name}"
                        : "👤 Không xác định",
                    style: TextStyle(
                      color: p.owner?.found == true
                          ? Colors.green
                          : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${p.firstSeenTime.toStringAsFixed(1)}s"),
                  Text("${p.lastSeenTime.toStringAsFixed(1)}s"),

                  const SizedBox(height: 4),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${(p.confidence * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  )
                ],
              ),

              // 🔥 SECTION 2 (CHI TIẾT)
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 🔹 SECTION 1: INFO BIỂN
                      _row("Biển chuẩn", p.owner?.plate),
                      _row("Số lần xuất hiện", p.count),

                      const Divider(),

                      // 🔹 SECTION 2: THÔNG TIN CHỦ
                      const Text(
                        "👤 Thông tin chủ sở hữu",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      if (p.owner != null && p.owner!.found) ...[
                        _row("Tên", p.owner!.name),
                        _row("SĐT", p.owner!.info["phone"]),
                        _row("Địa chỉ", p.owner!.info["address"]),
                        _row("Ngày sinh", p.owner!.info["date_of_birth"]),
                        _row("CCCD", p.owner!.info["cccd"]),
                        _row("Nơi làm việc", p.owner!.info["department"]),
                        _row("Chức vụ", p.owner!.info["role"]),
                        _row("Tuổi", p.owner!.info["age"]),
                      ] else
                        const Text(
                          "Không tìm thấy chủ sở hữu",
                          style: TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}