import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';

class MedikaApi {
  final http.Client client;
  MedikaApi({http.Client? client}) : client = client ?? http.Client();

  Future<Map<String, dynamic>> createQuote({
    required String product,
    required String clinic,
    required String contact,
    required String phone,
    String city = '',
    String configuration = '',
    String note = '',
  }) async {
    final response = await client.post(
      AppConfig.endpoint('/api/quotes'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'product': product,
        'configuration': configuration,
        'clinic': clinic,
        'contact': contact,
        'phone': phone,
        'city': city,
        'note': note,
      }),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> createService({
    required String equipment,
    required String clinic,
    required String contact,
    required String phone,
    required String issue,
    String model = '',
    String serial = '',
  }) async {
    final response = await client.post(
      AppConfig.endpoint('/api/service'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'equipment': equipment,
        'model': model,
        'serial': serial,
        'clinic': clinic,
        'contact': contact,
        'phone': phone,
        'issue': issue,
      }),
    );
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('${data['error'] ?? 'Request failed'} (${response.statusCode})');
    }
    return data;
  }
}
