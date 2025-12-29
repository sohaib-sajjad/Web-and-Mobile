import 'package:flutter/material.dart';
import 'host/host_home.dart';
import 'attendee/attendee_home.dart';
import 'host/qr_code_scanner.dart'; 

class RoleSelection extends StatelessWidget {
  const RoleSelection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Role')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.event_available),
              label: const Text('Host'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HostHome()),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              icon: const Icon(Icons.person_outline),
              label: const Text('Attendee'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AttendeeHome()),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),

            const SizedBox(height: 16),

            // QR CHECK-IN BUTTON
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('QR Check-in'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QrCheckInScreen(),
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
