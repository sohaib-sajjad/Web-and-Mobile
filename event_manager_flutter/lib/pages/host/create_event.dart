
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/event.dart';
import '../../repository/event_repository.dart';

class CreateEvent extends StatefulWidget {
  const CreateEvent({Key? key}) : super(key: key);

  @override
  State<CreateEvent> createState() => _CreateEventState();
}

class _CreateEventState extends State<CreateEvent> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _location = TextEditingController();
  final _capacity = TextEditingController();
  final _price = TextEditingController();

  DateTime? _date;
  String _category = 'Party';
  bool _isPublic = true;

  final repo = EventRepository();
  final _picker = ImagePicker();

  // keep picked images
  final List<XFile> _images = [];

  // ===== Nominatim (OSM) state =====
  List<Map<String, dynamic>> _locationResults = [];
  bool _locLoading = false;
  Timer? _debounce;
  String? _selectedLocationName;
  double? _selectedLat;
  double? _selectedLng;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _location.dispose();
    _capacity.dispose();
    _price.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ===== Nominatim search (FREE) =====
  Future<List<Map<String, dynamic>>> searchLocation(String query) async {
    final q = query.trim();
    if (q.length < 3) return [];

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': q,
        'format': 'json',
        'addressdetails': '1',
        'limit': '6',
      },
    );

    final res = await http.get(
      uri,
      headers: {
        // Required by Nominatim usage policy
        'User-Agent': 'event-manager-flutter-app (uni-assignment)',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) return [];
    final data = json.decode(res.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  void _onLocationChanged(String v) {
    // If user edits the field after picking, clear the previously chosen lat/lng
    _selectedLat = null;
    _selectedLng = null;
    _selectedLocationName = null;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final query = v.trim();
      if (!mounted) return;

      if (query.length < 3) {
        setState(() => _locationResults = []);
        return;
      }

      setState(() => _locLoading = true);
      try {
        final results = await searchLocation(query);
        if (!mounted) return;
        setState(() {
          _locationResults = results;
          _locLoading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _locationResults = [];
          _locLoading = false;
        });
      }
    });
  }

  void _selectLocation(Map<String, dynamic> place) {
    final name = (place['display_name'] as String?) ?? '';
    final latStr = (place['lat'] as String?) ?? '';
    final lonStr = (place['lon'] as String?) ?? '';

    final lat = double.tryParse(latStr);
    final lng = double.tryParse(lonStr);

    setState(() {
      _selectedLocationName = name;
      _selectedLat = lat;
      _selectedLng = lng;
      _location.text = name;
      _locationResults = [];
    });

    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 10),

              //Location (OSM + Nominatim)
              TextFormField(
                controller: _location,
                decoration: InputDecoration(
                  labelText: 'Search location (OpenStreetMap)',
                  suffixIcon: _locLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : (_location.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _location.clear();
                                  _locationResults = [];
                                  _selectedLat = null;
                                  _selectedLng = null;
                                  _selectedLocationName = null;
                                });
                              },
                            )
                          : null),
                ),
                onChanged: _onLocationChanged,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),

              if (_locationResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _locationResults.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, thickness: 1),
                    itemBuilder: (context, i) {
                      final place = _locationResults[i];
                      final title = (place['display_name'] as String?) ?? '';
                      return ListTile(
                        dense: true,
                        title: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectLocation(place),
                      );
                    },
                  ),
                ),
              ],

              if (_selectedLat != null && _selectedLng != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Selected: ${_selectedLat!.toStringAsFixed(5)}, ${_selectedLng!.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _capacity,
                      decoration: const InputDecoration(
                          labelText: 'Capacity (optional)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 1) return 'Enter a valid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      decoration:
                          const InputDecoration(labelText: 'Price (optional)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v.trim());
                        if (n == null || n < 0) return 'Enter a valid price';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'Party', child: Text('Party')),
                  DropdownMenuItem(value: 'Sports', child: Text('Sports')),
                  DropdownMenuItem(value: 'Meetup', child: Text('Meetup')),
                  DropdownMenuItem(value: 'Workshop', child: Text('Workshop')),
                ],
                onChanged: (v) => setState(() => _category = v ?? 'Party'),
              ),

              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Public event'),
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
              ),

              const SizedBox(height: 10),
              _dateRow(),

              const SizedBox(height: 16),
              _imagesSection(),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateRow() {
    final label = _date == null
        ? 'No date chosen'
        : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')} '
            '${_date!.hour.toString().padLeft(2, '0')}:${_date!.minute.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Expanded(child: Text(label)),
        TextButton(onPressed: _pickDate, child: const Text('Pick Date')),
      ],
    );
  }

  Widget _imagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Images', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Camera'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_images.isEmpty)
          const Text('No images added')
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_images.length, (i) {
              final x = _images[i];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(x.path),
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => setState(() => _images.removeAt(i)),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black54,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final pickedDay = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (pickedDay == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    final dt = DateTime(
      pickedDay.year,
      pickedDay.month,
      pickedDay.day,
      pickedTime?.hour ?? 12,
      pickedTime?.minute ?? 0,
    );

    setState(() => _date = dt);
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 60,
      maxWidth: 1280,
    );
    if (picked.isEmpty) return;
    setState(() => _images.addAll(picked));
  }

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 1280,
    );
    if (picked == null) return;
    setState(() => _images.add(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a date')),
      );
      return;
    }

    // require user to pick from suggestions (lat/lng must exist)
    if (_selectedLat == null || _selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location from the list')),
      );
      return;
    }

    final capacity = _capacity.text.trim().isEmpty
        ? null
        : int.tryParse(_capacity.text.trim());
    final price = _price.text.trim().isEmpty
        ? null
        : double.tryParse(_price.text.trim());

    // Convert selected images -> base64
    final imageBase64 = <String>[];
    for (final x in _images) {
      final bytes = await File(x.path).readAsBytes();
      imageBase64.add(base64Encode(bytes));
    }

    final id = const Uuid().v4();


    final e = Event(
      id: id,
      title: _title.text.trim(),
      description: _desc.text.trim(),
      date: _date!,
      location: _location.text.trim(),
      category: _category,
      isPublic: _isPublic,
      capacity: capacity,
      price: price,
      imageBase64: imageBase64,
      lat: _selectedLat,
      lng: _selectedLng,
    );

    await repo.add(e);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }
}
