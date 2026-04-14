import 'api_service.dart';

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
      if (endpoint != null) "endpoint": endpoint,
      if (actionType != null) "action_type": actionType,
      if (method != null) "method": method,
      if (keyword != null) "keyword": keyword,
      if (startTime != null) "start_time": startTime.toString(),
      if (endTime != null) "end_time": endTime.toString(),
      "limit": limit.toString(),
      "offset": offset.toString(),
    };

    final uri = Uri.http(
      "192.168.1.11:8000",
      "/history/filter",
      query,
    );

    final response = await ApiService.getRaw(uri); // bạn cần có hàm này

    return response;
  }
}