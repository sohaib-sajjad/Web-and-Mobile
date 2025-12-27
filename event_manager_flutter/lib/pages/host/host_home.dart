import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../repository/event_repository.dart';
import '../../models/event.dart';
import 'create_event.dart';

class HostHome extends StatefulWidget {
  const HostHome({Key? key}) : super(key: key);

  @override
  State<HostHome> createState() => _HostHomeState();
}

class _HostHomeState extends State<HostHome> {
  final repo = EventRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host — Events')),
      body: StreamBuilder<List<Event>>(
        stream: repo.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!;
          if (events.isEmpty) {
            return const Center(child: Text('No events yet. Create one.'));
          }

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, i) {
              final e = events[i];
              return ListTile(
                title: Text(e.title),
                subtitle: Text(
                  '${DateFormat.yMMMd().add_jm().format(e.date)}\n${e.description}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () async {
                    await repo.remove(e.id);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateEvent()),
          );
          // No setState needed; StreamBuilder updates automatically.
        },
      ),
    );
  }
}
