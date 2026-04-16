import 'package:ai_traffic_app/screens/person_edit_screen.dart';
import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../services/api_service.dart';

class PersonDetailScreen extends StatelessWidget {
  final Person person;

  const PersonDetailScreen({super.key, required this.person});

  Widget item(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              flex: 4,
              child: Text(k,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500))),
          Expanded(flex: 6, child: Text(v)),
        ],
      ),
    );
  }
  String buildImage(String path) {
    const baseUrl = "http://192.168.1.11:8000";

    if (path.isEmpty) return "";

    if (path.startsWith("/")) {
      return "$baseUrl$path";
    }

    return "$baseUrl/$path";
  }
  @override
  Widget build(BuildContext context) {
    final info = person.info;

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết người")),
      backgroundColor: const Color(0xfff5f6fa),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: person.imagePath.isNotEmpty
                    ? NetworkImage(buildImage(person.imagePath))
                    : null,
                child: person.imagePath.isEmpty
                    ? Text(
                  person.name.isNotEmpty ? person.name[0] : "?",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
            ),

            Text(
              person.name,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            /// CARD INFO
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  item("Nơi làm việc", info.department),
                  item("Vai trò", info.role),
                  item("SĐT", info.phone),
                  item("Địa chỉ", info.address),
                  item("Tuổi", info.age),
                  item("Ngày sinh", info.dob),
                  item("CCCD", info.cccd),
                  item("Biển số xe", info.plateNumber),
                  item("Biển số máy", info.vehiclePlates),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [

                /// 🟠 SỬA
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PersonEditScreen(person: person),
                        ),
                      );

                      if (result == true) {
                        Navigator.pop(context, true);
                      }
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("SỬA"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),

                const SizedBox(width: 12), // 👈 đúng phải là width

                /// 🔴 XÓA
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("⚠️ Xác nhận"),
                          content: Text("Bạn chắc chắn muốn xóa ${person.name}?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("HỦY"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("XÓA"),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      try {
                        await ApiService.deletePerson(person.personId);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Đã xóa")),
                        );

                        Navigator.pop(context, true);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Lỗi: $e")),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text("XÓA"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}