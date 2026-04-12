import 'package:flutter/material.dart';
import '../models/plate_summary.dart';

class PlatesScreen extends StatelessWidget {
  final List<PlateSummary> plates;

  const PlatesScreen({super.key, required this.plates});

  @override
  Widget build(BuildContext context) {

    /// 🎯 REGEX CHUẨN
    final motoRegex = RegExp(r'^\d{2}[A-Z]\d-\d{5}$');
    final carRegex = RegExp(r'^\d{2}[A-Z]-\d{5}$');

    /// 🔍 LỌC KẾT HỢP BACKEND + FORMAT
    final filteredPlates = plates.where((p) {
      final plate = p.plate.trim().toUpperCase();
      final type = p.className.toLowerCase();
      if (type == "motorcycle" && motoRegex.hasMatch(plate)) {
        return true;
      }

      if (type == "car" && carRegex.hasMatch(plate)) {
        return true;
      }

      return false;
    }).toList();

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
            margin: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Icon(
                getIcon(p.className),
                color: getColor(p.className),
              ),
              title: Text(
                p.plate,
                style: const TextStyle(
                    fontWeight: FontWeight.bold),
              ),
              subtitle: Text("${p.className} • ${p.count} lần"),
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
            ),
          );
        },
      ),
    );
  }
}