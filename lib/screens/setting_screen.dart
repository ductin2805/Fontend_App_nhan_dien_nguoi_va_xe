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

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget buildTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        title: const Text("CÀI ĐẶT"),
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomeMenu()),
            );
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [

          /// CHUNG
          buildSectionTitle("CHUNG"),
          buildCard(
            children: [
              buildTile(
                icon: Icons.flag,
                title: "Ngôn ngữ",
                trailing: const Text("Tiếng Việt 🇻🇳"),
              ),
              buildTile(
                icon: Icons.dark_mode,
                title: "Chế độ tối",
                trailing: Switch(
                  value: darkMode,
                  onChanged: (v) {
                    setState(() => darkMode = v);
                  },
                ),
              ),
            ],
          ),

          /// AI
          buildSectionTitle("MÔ HÌNH AI"),
          buildCard(
            children: [
              buildTile(
                icon: Icons.camera_alt,
                title: "Nhận diện đối tượng",
                trailing: Switch(
                  value: detectObject,
                  onChanged: (v) {
                    setState(() => detectObject = v);
                  },
                ),
              ),
              buildTile(
                icon: Icons.directions_car,
                title: "Nhận diện biển số",
                trailing: Switch(
                  value: detectPlate,
                  onChanged: (v) {
                    setState(() => detectPlate = v);
                  },
                ),
              ),
              buildTile(
                icon: Icons.face,
                title: "Nhận diện khuôn mặt",
                trailing: Switch(
                  value: detectFace,
                  onChanged: (v) {
                    setState(() => detectFace = v);
                  },
                ),
              ),
              buildTile(
                icon: Icons.settings,
                title: "Quản lý thư viện khuôn mặt",
                onTap: () {
                  // TODO: navigate
                },
              ),
            ],
          ),

          /// DATA
          buildSectionTitle("DỮ LIỆU & LƯU TRỮ"),
          buildCard(
            children: [
              buildTile(
                icon: Icons.storage,
                title: "Cơ sở dữ liệu SQLite",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PersonListScreen(),
                    ),
                  );
                },
              ),
              buildTile(
                icon: Icons.upload,
                title: "Xuất lịch sử (CSV)",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HistoryScreen(),
                    ),
                  );
                },
              ),
              buildTile(
                icon: Icons.delete,
                title: "Xóa tất cả bản ghi",
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("⚠️ CẢNH BÁO NGHIÊM TRỌNG"),
                        content: const Text(
                          "Bạn sắp XÓA TOÀN BỘ lịch sử.\n\n"
                              "Hành động này KHÔNG THỂ HOÀN TÁC.\n"
                              "Dữ liệu sẽ biến mất vĩnh viễn.\n\n"
                              "Nếu bạn bấm XÓA, đừng quay lại hỏi tôi vì sao mất dữ liệu.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("HỦY"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () async {
                              Navigator.pop(context);

                              try {
                                await ApiService.deleteAllHistory();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Đã xóa toàn bộ lịch sử"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Xóa thất bại"),
                                  ),
                                );
                              }
                            },
                            child: const Text("XÓA TẤT CẢ"),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),

          /// ABOUT
          buildSectionTitle("VỀ ỨNG DỤNG"),
          buildCard(
            children: const [
              ListTile(
                title: Text("Phiên bản 3.1100.3.2"),
              )
            ],
          ),
        ],
      ),
    );
  }
}