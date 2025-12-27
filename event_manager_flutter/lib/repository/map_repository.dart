import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> searchLocation(String query) async {
  final url = Uri.parse(
    'https://nominatim.openstreetmap.org/search'
    '?q=$query&format=json&addressdetails=1&limit=5',
  );

  final res = await http.get(
    url,
    headers: {
      'User-Agent': 'event-manager-flutter-app', // REQUIRED
    },
  );

  final data = json.decode(res.body) as List;
  return data.cast<Map<String, dynamic>>();
}
