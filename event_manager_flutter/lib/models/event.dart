import 'dart:convert';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;

  final String location; // display string (what user picked)
  final double? lat;     // NEW
  final double? lng;     // NEW

  final String category;
  final bool isPublic;

  final int? capacity;
  final double? price;

  final List<String> imageBase64;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    this.lat,
    this.lng,
    required this.category,
    required this.isPublic,
    this.capacity,
    this.price,
    this.imageBase64 = const [],
  });

  /// Use this when reading from Firestore:
  /// Event.fromFirestore(doc.id, doc.data())
  factory Event.fromFirestore(String docId, Map<String, dynamic> json) {
    return Event(
      id: (json['id'] as String?) ?? docId,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      date: _parseDate(json['date']),
      location: (json['location'] as String?) ?? '',
      lat: _parseDouble(json['lat']),
      lng: _parseDouble(json['lng']),
      category: (json['category'] as String?) ?? 'Party',
      isPublic: (json['isPublic'] as bool?) ?? true,
      capacity: _parseInt(json['capacity']),
      price: _parseDouble(json['price']),
      imageBase64: (json['imageBase64'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  /// Keep this for non-Firestore usage (expects id inside json)
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      date: _parseDate(json['date']),
      location: (json['location'] as String?) ?? '',
      lat: _parseDouble(json['lat']),
      lng: _parseDouble(json['lng']),
      category: (json['category'] as String?) ?? 'Party',
      isPublic: (json['isPublic'] as bool?) ?? true,
      capacity: _parseInt(json['capacity']),
      price: _parseDouble(json['price']),
      imageBase64: (json['imageBase64'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id, // optional but fine
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'location': location,
        'lat': lat,
        'lng': lng,
        'category': category,
        'isPublic': isPublic,
        'capacity': capacity,
        'price': price,
        'imageBase64': imageBase64,
      };

  static List<Event> listFromJson(String source) {
    final arr = json.decode(source) as List<dynamic>;
    return arr.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<Event> events) =>
      json.encode(events.map((e) => e.toJson()).toList());

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);

    if (v is Map && v.containsKey('_seconds')) {
      final seconds = (v['_seconds'] as num).toInt();
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }

    if (v is String) {
      return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }
}
