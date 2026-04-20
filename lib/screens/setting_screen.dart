import 'package:ai_traffic_app/screens/camera_settings_screen.dart';
import 'package:ai_traffic_app/screens/home_menu.dart';
import 'package:ai_traffic_app/screens/person_list_screen.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  bool detectObject = true;
  bool detectPlate = true;
  bool detectFace = true;
  bool soundAlert = true;

  final TextEditingController _serverController =
      TextEditingController(text: ApiService.baseUrl.replaceFirst("http://", "").split(":")[0]);

  void _updateServer() {
    String ip = _serverController.text.trim();
    if (ip.isNotEmpty) {
      setState(() {
        ApiService.baseUrl = "http://$ip:8000";
        // Cập nhật lại Dio nếu cần
        ApiService.dio.options.baseUrl = ApiService.baseUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã cập nhật Server: ${ApiService.baseUrl}")),
      );
    }
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget buildCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        title: const Text("CÀI ĐẶT HỆ THỐNG"),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// SERVER CONFIG
          buildSectionTitle("KẾT NỐI"),
          buildCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _serverController,
                        decoration: const InputDecoration(
                          labelText: "IP Server (ví dụ: 192.168.1.10)",
                          border: OutlineInputBorder(),
                          prefixText: "http://",
                          suffixText: ":8000",
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _updateServer,
                      icon: const Icon(Icons.save),
                    ),
                  ],
                ),
              ),
            ],
          ),

          /// CHUNG
          buildSectionTitle("CHUNG"),
          buildCard(
            children: [
              buildTile(
                icon: Icons.flag,
                title: "Ngôn ngữ",
                trailing: const Text("Tiếng Việt 🇻🇳", style: TextStyle(color: Colors.grey)),
              ),
              const Divider(height: 1),
              buildTile(
                icon: Icons.notifications_active,
                title: "Âm thanh thông báo",
                trailing: Switch(
                  value: soundAlert,
                  onChanged: (v) => setState(() => soundAlert = v),
                ),
              ),
              const Divider(height: 1),
              buildTile(
                icon: Icons.dark_mode,
                title: "Chế độ tối",
                trailing: Switch(
                  value: darkMode,
                  onChanged: (v) => setState(() => darkMode = v),
                ),
              ),
            ],
          ),

          /// AI
          buildSectionTitle("MÔ HÌNH AI & NHẬN DIỆN"),
          buildCard(
            children: [
              buildTile(
                icon: Icons.camera_alt,
                title: "Nhận diện đối tượng",
                trailing: Switch(
                  value: detectObject,
                  onChanged: (v) => setState(() => detectObject = v),
                ),
              ),
              const Divider(height: 1),
              buildTile(
                icon: Icons.directions_car,
                title: "Nhận diện biển số",
                trailing: Switch(
                  value: detectPlate,
                  onChanged: (v) => setState(() => detectPlate = v),
                ),
              ),
              const Divider(height: 1),
              buildTile(
                icon: Icons.face,
                title: "Nhận diện khuôn mặt",
                trailing: Switch(
                  value: detectFace,
                  onChanged: (v) => setState(() => detectFace = v),
                ),
              ),
              const Divider(height: 1),
              buildTile(
                icon: Icons.manage_accounts,
                title: "Quản lý thư viện khuôn mặt",
                subtitle: "Đăng ký, sửa, xóa người trong hệ thống",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PersonListScreen()),
                  );
                },
              ),
              const Divider(height: 1),
              buildTile(
                icon: Icons.tune,
                title: "Cấu hình Camera Live",
                subtitle: "Điều chỉnh FPS, độ phân giải, ngưỡng AI",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CameraSettingsScreen()),
                  );
                },
              ),
            ],
          ),

          /// DATA
          buildSectionTitle("DỮ LIỆU & LƯU TRỮ"),
          buildCard(
            children: [
              buildTile(
                icon: Icons.history,
                title: "Lịch sử nhận diện",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
              ),
              const Divider(height: 1),
              buildTile(
                icon: Icons.delete_forever,
                title: "Xóa sạch dữ liệu",
                onTap: () {
                  _showDeleteConfirmDialog();
                },
              ),
            ],
          ),

          /// ABOUT
          buildSectionTitle("VỀ ỨNG DỤNG"),
          buildCard(
            children: const [
              ListTile(
                title: Text("AI Traffic Monitor"),
                subtitle: Text("Phiên bản 3.11.0\nĐang phát triển bởi AI Assistant"),
                trailing: Icon(Icons.info_outline),
              )
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("⚠️ CẢNH BÁO"),
          content: const Text(
            "Hành động này sẽ xóa toàn bộ lịch sử vi phạm và nhận diện. Bạn có chắc chắn?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("HỦY"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ApiService.deleteAllHistory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã xóa toàn bộ dữ liệu")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Xóa thất bại")),
                  );
                }
              },
              child: const Text("XÁC NHẬN XÓA"),
            ),
          ],
        );
      },
    );
  }
}