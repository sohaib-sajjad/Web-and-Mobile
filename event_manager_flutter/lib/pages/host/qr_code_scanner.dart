import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrCheckInScreen extends StatefulWidget {
  const QrCheckInScreen({Key? key}) : super(key: key);

  @override
  State<QrCheckInScreen> createState() => _QrCheckInScreenState();
}

class _QrCheckInScreenState extends State<QrCheckInScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _processing = false;
  Map<String, dynamic>? _payload;
  String? _error;
  bool _didScanOnce = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    setState(() {
      _processing = false;
      _payload = null;
      _error = null;
      _didScanOnce = false;
    });
    await _controller.start();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_didScanOnce) return;

    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() {
      _didScanOnce = true;
      _processing = true;
      _error = null;
    });

    await _controller.stop();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw 'Invalid QR content (not a JSON object).';
      }

      // Expect these keys in QR
      final eventId = (decoded['eventId'] ?? '').toString().trim();
      final ticketId = (decoded['ticketId'] ?? '').toString().trim();
      final customerName = (decoded['user'] ?? '').toString().trim(); // your QR uses "user"

      if (eventId.isEmpty) throw 'QR missing eventId';
      if (ticketId.isEmpty) throw 'QR missing ticketId';

      // Save to Firestore
      await _appendCheckIn(
        eventId: eventId,
        ticketId: ticketId,
        customerName: customerName.isEmpty ? 'Unknown' : customerName,
      );

      setState(() {
        _payload = decoded;
        _processing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _processing = false;
        _payload = null;
      });
    }
  }

  Future<void> _appendCheckIn({
    required String eventId,
    required String ticketId,
    required String customerName,
  }) async {
    final eventRef = _db.collection('events').doc(eventId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(eventRef);
      if (!snap.exists) {
        throw 'Event not found in Firestore.';
      }

      final data = snap.data() as Map<String, dynamic>;
      final List<dynamic> existing = (data['checkIns'] as List<dynamic>?) ?? [];

      final alreadyCheckedIn = existing.any((item) {
        if (item is Map<String, dynamic>) {
          return (item['ticketId'] ?? '').toString() == ticketId;
        }
        if (item is Map) {
          return (item['ticketId'] ?? '').toString() == ticketId;
        }
        return false;
      });

      if (alreadyCheckedIn) {
        throw 'Ticket already checked in';
      }

      final newItem = {
        'ticketId': ticketId,
        'customerName': customerName,
        'timestamp': Timestamp.now(),
      };

      // Append by setting the full new list
      tx.update(eventRef, {
        'checkIns': [...existing, newItem],
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scannedOk = _payload != null && _error == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Check-in'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                  ),
                  Center(
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(width: 3, color: Colors.white70),
                      ),
                    ),
                  ),
                  if (_processing)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: const [
                            SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Processing...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan Again'),
                        ),
                      ),
                    ] else if (_payload == null) ...[
                      const Text(
                        'Scan a ticket QR code to check in.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ] else ...[
                      const Text(
                        'Scanned Successfully',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Event ID: ${_payload!['eventId']}'),
                      Text('Ticket ID: ${_payload!['ticketId']}'),
                      Text('User: ${_payload!['user']}'),
                      Text('Date: ${_payload!['date']}'),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: scannedOk
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _reset,
                    child: const Text('Scan Next Ticket'),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
