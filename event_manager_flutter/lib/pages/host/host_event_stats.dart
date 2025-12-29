import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventStatsScreen extends StatelessWidget {
  final String eventId;

  const EventStatsScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('events').doc(eventId);

    return Scaffold(
      appBar: AppBar(title: const Text('Event Stats')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error:\n${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data!;
          if (!doc.exists) {
            return const Center(child: Text('Event not found'));
          }

          final data = doc.data() ?? {};

          final title = (data['title'] ?? '').toString();
          final location = (data['location'] ?? '').toString();

          final date = _parseDate(data['date']);
          final ticketsSold = (data['ticketsSold'] as List?) ?? const [];
          final checkIns = (data['checkIns'] as List?) ?? const [];

          DateTime _tsOrZero(dynamic v) {
            final t = _parseTs(v);
            return t ?? DateTime.fromMillisecondsSinceEpoch(0);
          }

          // Tickets: newest first
          final sortedTickets = [...ticketsSold]..sort((a, b) {
              final ta = _tsOrZero((a as Map)['timestamp']);
              final tb = _tsOrZero((b as Map)['timestamp']);
              return tb.compareTo(ta); // desc
            });

          // Check-ins: newest first
          final sortedCheckins = [...checkIns]..sort((a, b) {
              final ta = _tsOrZero((a as Map)['timestamp']);
              final tb = _tsOrZero((b as Map)['timestamp']);
              return tb.compareTo(ta); // desc
            });

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                title.isEmpty ? 'Event' : title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              if (date != null)
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 8),
                    Text(DateFormat.yMMMd().add_jm().format(date)),
                  ],
                ),
              if (location.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(location)),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // KPI cards
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      title: 'Tickets Sold',
                      value: ticketsSold.length.toString(),
                      icon: Icons.confirmation_number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      title: 'Check-ins',
                      value: checkIns.length.toString(),
                      icon: Icons.verified,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(),

              // Tickets list
              const SizedBox(height: 10),
              const Text(
                'Tickets Sold',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (sortedTickets.isEmpty)
                const Text('No tickets sold yet.')
              else
                ...sortedTickets.map((t) {
                  final m = t as Map;
                  final ticketId = (m['ticketId'] ?? '').toString();
                  final name = (m['customerName'] ?? '').toString();
                  final ts = _parseTs(m['timestamp']);
                  return _LogRow(
                    icon: Icons.confirmation_number,
                    title: name.isEmpty ? 'Ticket' : name,
                    subtitle: ticketId.isEmpty ? null : 'Ticket: $ticketId',
                    trailing: ts == null ? null : DateFormat.Hm().format(ts),
                  );
                }),

              const SizedBox(height: 18),
              const Divider(),

              // Check-ins list
              const SizedBox(height: 10),
              const Text(
                'Check-ins',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (sortedCheckins.isEmpty)
                const Text('No check-ins yet.')
              else
                ...sortedCheckins.map((c) {
                  final m = c as Map;
                  final ticketId = (m['ticketId'] ?? '').toString();
                  final name = (m['customerName'] ?? '').toString();
                  final ts = _parseTs(m['timestamp']);
                  return _LogRow(
                    icon: Icons.verified,
                    title: name.isEmpty ? 'Checked-in' : name,
                    subtitle: ticketId.isEmpty ? null : 'Ticket: $ticketId',
                    trailing: ts == null ? null : DateFormat.Hm().format(ts),
                  );
                }),

              const SizedBox(height: 18),
            ],
          );
        },
      ),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static DateTime? _parseTs(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;

  const _LogRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: trailing == null ? null : Text(trailing!),
      ),
    );
  }
}
