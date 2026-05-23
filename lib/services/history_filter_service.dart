import 'api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HistoryFilterService {
  static Future<Map<String, dynamic>> filter({
    String? endpoint,
    String? actionType,
    String? method,
    String? keyword,
    double? startTime,
    double? endTime,
    DateTime? date,
    int limit = 50,
    int offset = 0,
  }) async {
    // Mặc định lọc theo ngày hôm nay nếu không truyền thời gian cụ thể hoặc chọn ngày cụ thể
    if (date != null) {
      startTime = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch / 1000;
      endTime = DateTime(date.year, date.month, date.day, 23, 59, 59, 999).millisecondsSinceEpoch / 1000;
    } else if (startTime == null && endTime == null) {
      final now = DateTime.now();
      startTime = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch / 1000;
      endTime = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).millisecondsSinceEpoch / 1000;
    }

    final query = {
      if (endpoint != null && endpoint != "Tất cả") "endpoint": endpoint,
      if (actionType != null && actionType != "Tất cả") "action_type": actionType,
      if (method != null) "method": method,
      if (keyword != null && keyword.isNotEmpty) "keyword": keyword,
      if (startTime != null) "start_time": startTime.toInt().toString(),
      if (endTime != null) "end_time": endTime.toInt().toString(),
      "limit": limit.toString(),
      "offset": offset.toString(),
    };

    final uri = Uri.parse("${ApiService.baseUrl}/history/filter").replace(queryParameters: query);

    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return json.decode(utf8.decode(res.bodyBytes));
    } else {
      throw Exception("Lỗi lọc lịch sử: ${res.statusCode}");
    }
  }
}
