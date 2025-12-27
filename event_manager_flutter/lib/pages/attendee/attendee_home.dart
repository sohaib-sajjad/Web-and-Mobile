import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../models/event.dart';
import 'event_detail_screen.dart';

class AttendeeHome extends StatefulWidget {
  const AttendeeHome({Key? key}) : super(key: key);

  @override
  State<AttendeeHome> createState() => _AttendeeHomeState();
}

class _AttendeeHomeState extends State<AttendeeHome> {
  final _firestore = FirebaseFirestore.instance;

  Set<String> _registered = {};

  // Filter state
  bool _nearbyOnly = false;

  // Location state
  Position? _me;
  bool _locLoading = false;
  String? _locError;

  // Nearby settings
  final double _nearbyKm = 15;

  @override
  void initState() {
    super.initState();
    _loadRegistered();
  }

  Future<void> _loadRegistered() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList('registered') ?? [];
    setState(() => _registered = raw.toSet());
  }

  Future<void> _toggleRegister(String id) async {
    final sp = await SharedPreferences.getInstance();

    if (_registered.contains(id)) {
      _registered.remove(id);
    } else {
      _registered.add(id);
    }

    await sp.setStringList('registered', _registered.toList());
    setState(() {});
  }

  Future<void> _enableNearby() async {
    setState(() {
      _nearbyOnly = true;
      _locError = null;
    });

    if (_me != null) return;

    setState(() => _locLoading = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Turn on GPS.';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw 'Location permission denied.';
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permission permanently denied. Enable it in settings.';
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() => _me = pos);
    } catch (e) {
      setState(() => _locError = e.toString());
    } finally {
      setState(() => _locLoading = false);
    }
  }

  void _showAll() {
    setState(() {
      _nearbyOnly = false;
      _locError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendee — Browse Events')),
      body: Column(
        children: [
          // Top filters
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: _FilterButton(
                    label: 'All Events',
                    selected: !_nearbyOnly,
                    onTap: _showAll,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FilterButton(
                    label: 'Nearby',
                    selected: _nearbyOnly,
                    onTap: _enableNearby,
                  ),
                ),
              ],
            ),
          ),

          // nearby status line
          if (_nearbyOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  if (_locLoading) ...[
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    const Text('Getting your location...'),
                  ] else if (_locError != null) ...[
                    Expanded(
                      child: Text(
                        _locError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ] else if (_me != null) ...[
                    Text('Within ${_nearbyKm.toStringAsFixed(0)} km of you'),
                  ],
                ],
              ),
            ),

          // Events list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('events')
                  .where('isPublic', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading events:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No upcoming events'));
                }

                final allEvents = snapshot.data!.docs
                    .map((doc) => Event.fromFirestore(
                          doc.id,
                          doc.data() as Map<String, dynamic>,
                        ))
                    .toList();

                // Apply filter
                final events = _nearbyOnly ? _filterNearby(allEvents) : allEvents;

                if (events.isEmpty) {
                  return Center(
                    child: Text(
                      _nearbyOnly ? 'No nearby events found' : 'No upcoming events',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, i) {
                    final e = events[i];
                    final reg = _registered.contains(e.id);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EventDetailScreen(event: e),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            if (e.imageBase64.isNotEmpty)
                              SizedBox(
                                height: 180,
                                width: double.infinity,
                                child: Image.memory(
                                  base64Decode(e.imageBase64.first),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _imageFallback(),
                                ),
                              )
                            else
                              _imageFallback(),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 8),

                                        // Date row
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.calendar_today, size: 16),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                DateFormat.yMMMd().format(e.date.toLocal()),
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),

                                        // Time row
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.access_time, size: 16),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                DateFormat.jm().format(e.date.toLocal()),
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),

                                        // Location row (max 2 lines)
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.location_on, size: 16),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                e.location,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 10),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Nearby filtering based on event lat/lng
  List<Event> _filterNearby(List<Event> events) {
    if (_me == null) return [];

    final meLat = _me!.latitude;
    final meLng = _me!.longitude;

    final filtered = <Event>[];

    for (final e in events) {
      final lat = e.lat;
      final lng = e.lng;
      if (lat == null || lng == null) continue;

      final d = _distanceKm(meLat, meLng, lat, lng);
      if (d <= _nearbyKm) filtered.add(e);
    }

    filtered.sort((a, b) {
      final da = _distanceKm(meLat, meLng, a.lat!, a.lng!);
      final db = _distanceKm(meLat, meLng, b.lat!, b.lng!);
      return da.compareTo(db);
    });

    return filtered;
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  Widget _imageFallback() {
    return Container(
      height: 180,
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.image, size: 48, color: Colors.grey),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: selected ? Colors.black : null,
        foregroundColor: selected ? Colors.white : null,
        side: BorderSide(color: selected ? Colors.black : Colors.grey.shade400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}
