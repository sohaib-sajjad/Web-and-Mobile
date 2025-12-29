import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class TicketRecord {
  final String ticketId;
  final String customerName;
  final DateTime timestamp;

  TicketRecord({
    required this.ticketId,
    required this.customerName,
    required this.timestamp,
  });

  factory TicketRecord.fromMap(Map<String, dynamic> json) {
    return TicketRecord(
      ticketId: (json['ticketId'] as String?) ?? '',
      customerName: (json['customerName'] as String?) ?? '',
      timestamp: _parseAnyDate(json['timestamp']),
    );
  }

  Map<String, dynamic> toMap() => {
        'ticketId': ticketId,
        'customerName': customerName,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  static DateTime _parseAnyDate(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);

    if (v is Timestamp) return v.toDate();

    // supports old “{_seconds: ...}” structure (if any)
    if (v is Map && v.containsKey('_seconds')) {
      final seconds = (v['_seconds'] as num).toInt();
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }

    if (v is String) {
      return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;

  final String location;
  final double? lat;
  final double? lng;

  final String category;
  final bool isPublic;

  final int? capacity;
  final double? price;

  final List<String> imageBase64;

  final List<TicketRecord> ticketsSold;
  final List<TicketRecord> checkIns;

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
    this.ticketsSold = const [],
    this.checkIns = const [],
  });

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
      ticketsSold: (json['ticketsSold'] as List<dynamic>?)
              ?.map((e) => TicketRecord.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
      checkIns: (json['checkIns'] as List<dynamic>?)
              ?.map((e) => TicketRecord.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

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
      ticketsSold: (json['ticketsSold'] as List<dynamic>?)
              ?.map((e) => TicketRecord.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
      checkIns: (json['checkIns'] as List<dynamic>?)
              ?.map((e) => TicketRecord.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(date), // store properly for queries
        'location': location,
        'lat': lat,
        'lng': lng,
        'category': category,
        'isPublic': isPublic,
        'capacity': capacity,
        'price': price,
        'imageBase64': imageBase64,
        'ticketsSold': ticketsSold.map((t) => t.toMap()).toList(),
        'checkIns': checkIns.map((c) => c.toMap()).toList(),
      };

  static List<Event> listFromJson(String source) {
    final arr = json.decode(source) as List<dynamic>;
    return arr.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<Event> events) =>
      json.encode(events.map((e) => e.toJson()).toList());

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);

    if (v is Timestamp) return v.toDate();

    if (v is Map && v.containsKey('_seconds')) {
      final seconds = (v['_seconds'] as num).toInt();
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }

    if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
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
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }
}
