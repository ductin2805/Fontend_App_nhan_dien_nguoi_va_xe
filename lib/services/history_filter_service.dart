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
    int limit = 50,
    int offset = 0,
  }) async {
    final query = {
      if (endpoint != null && endpoint != "Tất cả") "endpoint": endpoint,
      if (actionType != null && actionType != "Tất cả") "action_type": actionType,
      if (method != null) "method": method,
      if (keyword != null && keyword.isNotEmpty) "keyword": keyword,
      if (startTime != null) "start_time": startTime.toString(),
      if (endTime != null) "end_time": endTime.toString(),
      "limit": limit.toString(),
      "offset": offset.toString(),
    };

    final baseUrl = ApiService.baseUrl.replaceFirst("http://", "");
    final uri = Uri.http(
      baseUrl,
      "/history/filter",
      query,
    );

    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return json.decode(utf8.decode(res.bodyBytes));
    } else {
      throw Exception("Lỗi lọc lịch sử: ${res.statusCode}");
    }
  }
}