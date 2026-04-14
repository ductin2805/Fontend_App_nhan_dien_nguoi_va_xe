import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../services/api_service.dart';

import 'face_register_screen.dart';
import 'person_detail_screen.dart';
import 'dart:convert';
class PersonListScreen extends StatefulWidget {
  const PersonListScreen({super.key});

  @override
  State<PersonListScreen> createState() => _PersonListScreenState();
}

class _PersonListScreenState extends State<PersonListScreen> {
  List<Person> persons = [];
  bool loading = true;

  final baseUrl = "http://192.168.1.11:8000";

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    final data = await ApiService.getPersons();
    setState(() {
      persons = data;
      loading = false;
    });
  }

  String buildImage(String path) {
    if (path.isEmpty) return "";

    final baseUrl = "http://192.168.1.11:8000";

    if (path.startsWith("/")) {
      return "$baseUrl$path";
    }

    return "$baseUrl/$path";
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Danh sách người"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FaceRegisterScreen(),
                ),
              );

              if (result == true) {
                load();
              }
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xfff5f6fa),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: persons.length,
        itemBuilder: (_, i) {
          final p = persons[i];
          print(buildImage(p.imagePath));
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PersonDetailScreen(person: p),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 4)
                ],
              ),
              child: Row(
                children: [

                  /// AVATAR
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: p.imagePath.isNotEmpty
                        ? NetworkImage(buildImage(p.imagePath))
                        : null,
                    child: p.imagePath.isEmpty
                        ? Text(
                      p.name.isNotEmpty ? p.name[0] : "?",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                        : null,
                  ),

                  const SizedBox(width: 12),

                  /// TEXT
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        Text("CCCD: ${p.info.cccd}"),
                        Text(
                          p.info.department,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == "edit") {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PersonDetailScreen(person: p),
                          ),
                        );

                        if (result == true) {
                          load();
                        }
                      }

                      if (value == "delete") {
                        final confirm = await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Xác nhận"),
                            content: Text("Xóa ${p.name}?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Hủy"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Xóa"),
                              ),
                            ],
                          ),
                        );

                        if (confirm != true) return;

                        try {
                          await ApiService.deletePerson(p.personId);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Đã xóa")),
                          );

                          load(); // 🔥 reload list
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Lỗi: $e")),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "edit",
                        child: Text("Chỉnh sửa"),
                      ),
                      const PopupMenuItem(
                        value: "delete",
                        child: Text("Xóa"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}