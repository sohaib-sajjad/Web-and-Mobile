import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/event.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  static const String _customerName = 'Sohaib Sajjad';

  final _firestore = FirebaseFirestore.instance;

  bool _ticketLoading = false;

  Future<String> _createTicketAndSave() async {
    final ticketId = const Uuid().v4();

    final record = {
      'ticketId': ticketId,
      'customerName': _customerName,
      'timestamp': Timestamp.now(),
    };

    await _firestore.collection('events').doc(widget.event.id).update({
      'ticketsSold': FieldValue.arrayUnion([record]),
    });

    return ticketId;
  }

  void _showQrTicket({
    required String ticketId,
  }) {
    final qrPayload = jsonEncode({
      'eventId': widget.event.id,
      'title': widget.event.title,
      'date': widget.event.date.toIso8601String(),
      'user': _customerName,
      'ticketId': ticketId,
    });

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your Event Ticket',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                QrImageView(
                  data: qrPayload,
                  size: 220,
                  backgroundColor: Colors.white,
                ),

                const SizedBox(height: 16),

                Text(
                  widget.event.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 6),
                Text('Attendee: $_customerName'),

                const SizedBox(height: 6),
                Text(
                  'Ticket ID: $ticketId',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleGetTicket() async {
    if (_ticketLoading) return;

    setState(() => _ticketLoading = true);

    try {
      final ticketId = await _createTicketAndSave();
      if (!mounted) return;
      _showQrTicket(ticketId: ticketId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create ticket: $e')),
      );
    } finally {
      if (mounted) setState(() => _ticketLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;

    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // EVENT IMAGE
            if (e.imageBase64.isNotEmpty)
              SizedBox(
                height: 240,
                width: double.infinity,
                child: Image.memory(
                  base64Decode(e.imageBase64.first),
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 240,
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(Icons.image, size: 60, color: Colors.grey),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),

                  _InfoRow(
                    icon: Icons.calendar_today,
                    text: e.date.toLocal().toString(),
                  ),
                  _InfoRow(
                    icon: Icons.location_on,
                    text: e.location,
                  ),
                  _InfoRow(
                    icon: Icons.category,
                    text: e.category,
                  ),

                  const SizedBox(height: 12),
                  if (e.capacity != null)
                    _InfoRow(icon: Icons.people, text: 'Capacity: ${e.capacity}'),
                  if (e.price != null)
                    _InfoRow(icon: Icons.euro, text: '€${e.price!.toStringAsFixed(2)}'),

                  const Divider(height: 32),

                  Text(
                    e.description,
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _ticketLoading ? null : _handleGetTicket,
                      child: _ticketLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Get Ticket'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
