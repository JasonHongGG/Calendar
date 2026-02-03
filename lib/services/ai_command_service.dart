import 'dart:convert';
import 'package:http/http.dart' as http;

class AiCommandService {
  final String baseUrl;

  const AiCommandService({this.baseUrl = 'https://calendar.alberthongtunnel.dpdns.org/'});

  Future<AiCommandResponse> sendCommand(String input) async {
    final uri = Uri.parse('$baseUrl/command');
    final response = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'input': input}));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AiCommandResponse.fromJson(data);
    }

    throw Exception('AI command failed: ${response.statusCode}');
  }
}

class AiCommandResponse {
  final List<AiAction> actions;
  final String? message;

  AiCommandResponse({required this.actions, this.message});

  factory AiCommandResponse.fromJson(Map<String, dynamic> json) {
    final actionsJson = json['actions'] as List<dynamic>? ?? [];
    return AiCommandResponse(actions: actionsJson.map((item) => AiAction.fromJson(item as Map<String, dynamic>)).toList(), message: json['message'] as String?);
  }
}

class AiAction {
  final String type;
  final Map<String, dynamic> payload;

  AiAction({required this.type, required this.payload});

  factory AiAction.fromJson(Map<String, dynamic> json) {
    return AiAction(type: json['type'] as String? ?? '', payload: json['payload'] as Map<String, dynamic>? ?? {});
  }
}
