import 'package:ai_traffic_app/screens/face_recognition_screen.dart';
import 'package:ai_traffic_app/screens/setting_screen.dart';
import 'package:flutter/material.dart';
import 'detection_screen.dart';
import 'history_screen.dart';
import 'plate_screen.dart';
import 'realtime_camera_screen.dart';
class HomeMenu extends StatefulWidget {
  const HomeMenu({super.key});

  @override
  State<HomeMenu> createState() => _HomeMenuState();
}

class _HomeMenuState extends State<HomeMenu> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      body: Column(
        children: [
          const SizedBox(height: 60),

          // 🔷 Logo
          const Icon(Icons.camera_alt, size: 80, color: Colors.blue),

          const SizedBox(height: 10),

          const Text(
            "SMART TRAFFIC VISION",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 30),

          // 🔲 GRID MENU
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [

                  // 📹 REALTIME
                  menuCard(
                    icon: Icons.videocam,
                    title: "VIDEO",
                    subtitle: "Phân tích & nhận diện ",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RealtimeCameraScreen(),
                        ),
                      );
                    },
                  ),

                  // 🚗 OBJECT DETECTION
                  menuCard(
                    icon: Icons.directions_car_filled, // chuẩn hơn
                    title: "NHẬN DIỆN\n GIAO THÔNG",
                    subtitle: "Phân tích xe cộ",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TrafficScreen(),
                        ),
                      );
                    },
                  ),

                  // 🔢 PLATE
                  menuCard(
                    icon: Icons.badge, // giống biển số hơn
                    title: "NHẬN DIỆN\nBIỂN SỐ",
                    subtitle: "Phân tích biển số",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PlateScreen(),
                        ),
                      );
                    },
                  ),

                  // 😀 FACE RECOGNITION
                  menuCard(
                    icon: Icons.face, // icon chuẩn nhất rồi, đừng sáng tạo nữa
                    title: "NHẬN DIỆN\nKHUÔN MẶT",
                    subtitle: "truy xuất thông tin",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FaceRecognitionScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          )
        ],
      ),

      // 🔻 BOTTOM NAV
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) {
          if (i == 0) {
            // Home (đang ở đây rồi thì thôi)
            return;
          }

          if (i == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HistoryScreen()),
            );
          }

          if (i == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Trang Chủ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "Lịch Sử",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Cài đặt",
          ),
        ],
      ),
    );
  }

  // 🧩 CARD UI
  Widget menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F4C75), Color(0xFF3282B8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),

            const SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}