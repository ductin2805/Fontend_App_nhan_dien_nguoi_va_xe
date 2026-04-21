import 'package:ai_traffic_app/screens/face_recognition_screen.dart';
import 'package:ai_traffic_app/screens/setting_screen.dart';
import 'package:ai_traffic_app/screens/user_guide_screen.dart';
import 'package:flutter/material.dart';
import 'detection_screen.dart';
import 'history_screen.dart';
import 'plate_screen.dart';
import 'realtime_camera_screen.dart';
import 'realtime_live_screen.dart';
import 'chat_bot_sheet.dart';

class HomeMenu extends StatefulWidget {
  const HomeMenu({super.key});

  @override
  State<HomeMenu> createState() => _HomeMenuState();
}

class _HomeMenuState extends State<HomeMenu> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.background,
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Header Section
            Center(
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Icon(Icons.security, size: 50, color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "AI TRAFFIC VISION",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.colorScheme.primary,
              ),
            ),
            const Text(
              "Hệ thống giám sát thông minh",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 12),
            ),
            const SizedBox(height: 25),

            // Grid Menu
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.1,
                  children: [
                    _buildMenuCard(
                      context,
                      icon: Icons.video_collection_rounded,
                      title: "VIDEO FILE",
                      subtitle: "Phân tích từ file",
                      color: const Color(0xFF4facfe),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RealtimeCameraScreen())),
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.videocam_rounded,
                      title: "LIVE CAMERA",
                      subtitle: "Giám sát trực tiếp",
                      color: const Color(0xFFff0844),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RealtimeLiveScreen())),
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.commute_rounded,
                      title: "GIAO THÔNG",
                      subtitle: "Nhận diện phương tiện",
                      color: const Color(0xFF43e97b),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrafficScreen())),
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.vignette_rounded,
                      title: "BIỂN SỐ",
                      subtitle: "Truy xuất biển số",
                      color: const Color(0xFFfa709a),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlateScreen())),
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.face_rounded,
                      title: "KHUÔN MẶT",
                      subtitle: "Nhận diện danh tính",
                      color: const Color(0xFFf6d365),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaceRecognitionScreen())),
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.help_outline_rounded,
                      title: "HƯỚNG DẪN",
                      subtitle: "Cách dùng chi tiết",
                      color: Colors.blueGrey,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserGuideScreen())),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const ChatBotSheet(),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        elevation: 10,
        shape: const CircleBorder(),
        child: const Icon(Icons.psychology, color: Colors.white, size: 30),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: false,
          onTap: (i) {
            setState(() => currentIndex = i);
            if (i == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
            if (i == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Trang chủ"),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: "Lịch sử"),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: "Cài đặt"),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}