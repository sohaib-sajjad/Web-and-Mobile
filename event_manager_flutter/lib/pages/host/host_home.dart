import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../repository/event_repository.dart';
import '../../models/event.dart';
import 'create_event.dart';
import 'host_event_stats.dart';

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
            return Center(
              child: Text(
                'Error:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!;
          if (events.isEmpty) {
            return const Center(child: Text('No events yet. Create one.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            itemCount: events.length,
            itemBuilder: (context, i) {
              final e = events[i];

              return Card(
                elevation: 1.2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventStatsScreen(eventId: e.id),
                      ),
                    );
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HostEventThumb(event: e),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title + delete
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      e.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      await repo.remove(e.id);
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // Date row
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    size: 18,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      DateFormat.yMMMd().add_jm().format(e.date),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // Location row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      e.location,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // CTA hint
                              Row(
                                children: [
                                  Text(
                                    'View stats',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
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
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateEvent()),
          );
        },
      ),
    );
  }
}

class _HostEventThumb extends StatelessWidget {
  final Event event;

  const _HostEventThumb({required this.event});

  @override
  Widget build(BuildContext context) {
    final hasImg = event.imageBase64.isNotEmpty;

    return SizedBox(
      width: 110,
      height: 120,
      child: hasImg
          ? Image.memory(
              base64Decode(event.imageBase64.first),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 34,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}
