import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class DeclareMissionPage extends StatefulWidget {
  @override
  _DeclareMissionPageState createState() => _DeclareMissionPageState();
}

class _DeclareMissionPageState extends State<DeclareMissionPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _error;

  // Contrôleurs texte
  TextEditingController justificationController = TextEditingController();
  TextEditingController replacedFirstNameController = TextEditingController();
  TextEditingController replacedLastNameController = TextEditingController();

  // Dates/Heures
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;

  // Dropdown data
  List<dynamic> structures = [];
  List<dynamic> services = [];
  List<dynamic> profils = [];
  List<dynamic> motifs = [];
  List<dynamic> workers = [];

  // Sélections
  String? selectedType;
  int? selectedStructure;
  int? selectedService;
  int? selectedProfil;
  int? selectedMotif;
  int? selectedWorker;

  final List<String> typeOptions = ['Vacation', 'Heures supplémentaires'];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final urls = {
        'structures': 'https://www.parbasante.com/api/structures-list/',
        'services': 'https://www.parbasante.com/api/services-list/',
        'profils': 'https://www.parbasante.com/api/metier-category-list/',
        'motifs': 'https://www.parbasante.com/api/motifs-list/',
        'workers': 'https://www.parbasante.com/api/workers-list/',
      };

      final responses = await Future.wait([
        http.get(Uri.parse(urls['structures']!)),
        http.get(Uri.parse(urls['services']!)),
        http.get(Uri.parse(urls['profils']!)),
        http.get(Uri.parse(urls['motifs']!)),
        http.get(Uri.parse(urls['workers']!)),
      ]);

      if (responses.every((res) => res.statusCode == 200)) {
        setState(() {
          structures = jsonDecode(responses[0].body);
          services = jsonDecode(responses[1].body);
          profils = jsonDecode(responses[2].body);
          motifs = jsonDecode(responses[3].body);
          workers = jsonDecode(responses[4].body);
        });
      } else {
        setState(() {
          _error = 'Erreur chargement données';
        });
      }
    } catch (e) {
      setState(() {
        _error = "Erreur chargement données : $e";
      });
    }
  }

  Future<void> pickDate(BuildContext context, bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          selectedStartDate = date;
        } else {
          selectedEndDate = date;
        }
      });
    }
  }

  Future<void> pickTime(BuildContext context, bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        if (isStart) {
          selectedStartTime = time;
        } else {
          selectedEndTime = time;
        }
      });
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Future<void> submitMission() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://www.parbasante.com/api/mission/declare/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'structure': selectedStructure,
          'service': selectedService,
          'profil': selectedProfil,
          'type': selectedType,
          'startDate': formatDate(selectedStartDate),
          'finishDate': formatDate(selectedEndDate),
          'startTime': formatTime(selectedStartTime),
          'finishTime': formatTime(selectedEndTime),
          'motif': selectedMotif,
          'justification': justificationController.text,
          'replacedFirstName': replacedFirstNameController.text,
          'replacedLastName': replacedLastNameController.text,
          'worker': selectedWorker,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Mission déclarée avec succès.')),
        );
        _formKey.currentState!.reset();
      } else {
        setState(() {
          _error = 'Erreur API : ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur envoi : $e';
      });
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Déclarer une mission')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_error != null) Text(_error!, style: TextStyle(color: Colors.red)),
              DropdownButtonFormField<String>(
                value: selectedType,
                items: typeOptions
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => selectedType = val),
                decoration: InputDecoration(labelText: 'Type de mission'),
                validator: (val) => val == null ? 'Champ requis' : null,
              ),
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: selectedStructure,
                items: structures
                    .where((s) => s['id'] != null && s['name'] != null)
                    .map<DropdownMenuItem<int>>((s) => DropdownMenuItem<int>(
                          value: s['id'],
                          child: Text(s['name']),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => selectedStructure = val),
                decoration: InputDecoration(labelText: 'Structure'),
                validator: (val) => val == null ? 'Champ requis' : null,
              ),
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: selectedService,
                items: services
                    .where((s) => s['id'] != null && s['name'] != null)
                    .map<DropdownMenuItem<int>>((s) => DropdownMenuItem<int>(
                          value: s['id'],
                          child: Text(s['name']),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => selectedService = val),
                decoration: InputDecoration(labelText: 'Service'),
                validator: (val) => val == null ? 'Champ requis' : null,
              ),
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: selectedProfil,
                items: profils
                    .where((p) => p['id'] != null && (p['name'] != null || p['nom'] != null))
                    .map<DropdownMenuItem<int>>((p) => DropdownMenuItem<int>(
                          value: p['id'],
                          child: Text(p['name'] ?? p['nom']),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => selectedProfil = val),
                decoration: InputDecoration(labelText: 'Profil'),
                validator: (val) => val == null ? 'Champ requis' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => pickDate(context, true),
                      child: Text("Date début"),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => pickDate(context, false),
                      child: Text("Date fin"),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => pickTime(context, true),
                      child: Text("Heure début"),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => pickTime(context, false),
                      child: Text("Heure fin"),
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: selectedMotif,
                items: motifs
                    .where((m) => m['id'] != null && m['name'] != null)
                    .map<DropdownMenuItem<int>>((m) => DropdownMenuItem<int>(
                          value: m['id'],
                          child: Text(m['name']),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => selectedMotif = val),
                decoration: InputDecoration(labelText: 'Motif'),
                validator: (val) => val == null ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: justificationController,
                decoration: InputDecoration(labelText: 'Justification'),
              ),
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: selectedWorker,
                items: workers
                    .where((w) => w['user'] != null && w['user']['id'] != null)
                    .map<DropdownMenuItem<int>>((w) {
                      final user = w['user'];
                      final fullName = user['username'] ??
                          '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
                      return DropdownMenuItem<int>(
                        value: user['id'],
                        child: Text(fullName.isNotEmpty ? fullName : 'Remplaçant'),
                      );
                    }).toList(),
                onChanged: (val) => setState(() => selectedWorker = val),
                decoration: InputDecoration(labelText: 'Remplaçant'),
                validator: (val) => val == null ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: replacedFirstNameController,
                decoration: InputDecoration(labelText: 'Prénom remplacé'),
              ),
              TextFormField(
                controller: replacedLastNameController,
                decoration: InputDecoration(labelText: 'Nom remplacé'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : submitMission,
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Déclarer la mission"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
