import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../services/chat_db.dart';

class ChatBotSheet extends StatefulWidget {
  const ChatBotSheet({super.key});

  @override
  State<ChatBotSheet> createState() => _ChatBotSheetState();
}

class _ChatBotSheetState extends State<ChatBotSheet> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];

  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final userMsg = ChatMessage(
      role: "user",
      text: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await ChatDB.insert(userMsg);

    setState(() {
      messages.add({
        "role": "user",
        "text": text,
      });
    });

    controller.clear();

    try {
      print("🚀 CALL API");

      final chat = await ApiService.chatGemini(text);

      print("✅ DONE");

      final botMsg = ChatMessage(
        role: "bot",
        text: chat.reply,
        source: chat.source,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await ChatDB.insert(botMsg);

      setState(() {
        messages.add({
          "role": "bot",
          "text": chat.reply,
          "source": chat.source,
        });
      });

      _scrollToBottom();

    } catch (e) {
      print("❌ ERROR: $e");

      setState(() {
        messages.add({
          "role": "bot",
          "text": "Lỗi kết nối AI",
          "source": "error",
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color getColor(String source) {
    switch (source) {
      case "rule":
        return Colors.green.shade200;
      case "cache":
        return Colors.blue.shade200;
      case "gemini":
        return Colors.purple.shade200;
      case "fallback":
        return Colors.red.shade200;
      default:
        return Colors.grey.shade300;
    }
  }
  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  Future<void> loadMessages() async {
    final data = await ChatDB.getAll();

    setState(() {
      messages = data.map<Map<String, dynamic>>((e) => {
        "role": e.role,
        "text": e.text,
        "source": e.source,
      }).toList();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      // 🔥 FIX BỊ KEYBOARD CHE
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [

            // 🔷 HEADER
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF0F4C75),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  const SizedBox(width: 40), // giữ cân layout

                  const Text(
                    "SMART TRAFFIC CHATBOT",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // 🔥 NÚT XOÁ
                  IconButton(
                    onPressed: () async {
                      final confirm = await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Xóa lịch sử"),
                          content: const Text("Bạn có chắc muốn xóa toàn bộ chat?"),
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

                      await ChatDB.clear();

                      setState(() {
                        messages.clear();
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.white),
                  ),
                ],
              ),
            ),

            // 💬 CHAT LIST
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(10),
                children: messages.map((m) {
                  final isUser = m["role"] == "user";

                  return Row(
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      if (!isUser)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.smart_toy,
                                size: 16, color: Colors.white),
                          ),
                        ),

                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(10),
                        constraints:
                        const BoxConstraints(maxWidth: 250),
                        decoration: BoxDecoration(
                          color: isUser
                              ? const Color(0xFF3282B8)
                              : getColor(m["source"] ?? ""),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          m["text"] ?? "",
                          style: TextStyle(
                            color:
                            isUser ? Colors.white : Colors.black,
                          ),
                        ),
                      ),

                      if (isUser)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person,
                                size: 16, color: Colors.white),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),

            // 🔽 INPUT
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: "Nhập tin nhắn...",
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => send(), // 🔥 enter để gửi
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF0F4C75),
                    child: IconButton(
                      onPressed: send,
                      icon:
                      const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}