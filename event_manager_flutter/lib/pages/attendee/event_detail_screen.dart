import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/event.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _registered = false;

  @override
  void initState() {
    super.initState();
    _loadRegisterStatus();
  }

  Future<void> _loadRegisterStatus() async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList('registered') ?? [];
    setState(() => _registered = list.contains(widget.event.id));
  }

  Future<void> _toggleRegister() async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList('registered') ?? [];

    if (_registered) {
      list.remove(widget.event.id);
    } else {
      list.add(widget.event.id);
    }

    await sp.setStringList('registered', list);
    setState(() => _registered = !_registered);
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
            // IMAGE
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
                  // 🔹 TITLE
                  Text(
                    e.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),

                  const SizedBox(height: 8),

                  // DATE
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(e.date.toLocal().toString()),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // LOCATION
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.location)),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // CATEGORY
                  Row(
                    children: [
                      const Icon(Icons.category, size: 18),
                      const SizedBox(width: 8),
                      Text(e.category),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // OPTIONAL INFO
                  if (e.capacity != null)
                    Text('Capacity: ${e.capacity}'),

                  if (e.price != null)
                    Text('Price: €${e.price!.toStringAsFixed(2)}'),

                  const Divider(height: 24),

                  // DESCRIPTION
                  Text(
                    e.description,
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 24),

                  // REGISTER BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _toggleRegister,
                      child: Text(
                        _registered ? 'Registered' : 'Register',
                      ),
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
