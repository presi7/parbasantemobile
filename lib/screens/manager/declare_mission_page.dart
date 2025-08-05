import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeclareMissionPage extends StatefulWidget {
  @override
  _DeclareMissionPageState createState() => _DeclareMissionPageState();
}

class _DeclareMissionPageState extends State<DeclareMissionPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _error;

  // contrôleurs de texte
  final TextEditingController _justifCtrl    = TextEditingController();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl  = TextEditingController();

  // dates / heures
  DateTime?  _startDate;
  DateTime?  _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // listes pour dropdowns
  List<dynamic> _types       = [];
  List<dynamic> _structures  = [];
  List<dynamic> _services    = [];
  List<dynamic> _profils     = [];
  List<dynamic> _motifs      = [];
  List<dynamic> _workers     = [];

  // valeurs sélectionnées
  int? _selectedType;
  int? _selectedStructure;
  int? _selectedService;
  int? _selectedProfil;
  int? _selectedMotif;
  int? _selectedWorker;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // on charge toutes les listes nécessaires
    final results = await Future.wait([
      http.get(Uri.parse('https://www.parbasante.com/api/missions-category-list/')),
      http.get(Uri.parse('https://www.parbasante.com/api/structures-list/')),
      http.get(Uri.parse('https://www.parbasante.com/api/services-list/')),
      http.get(Uri.parse('https://www.parbasante.com/api/metier-category-list/')),
      http.get(Uri.parse('https://www.parbasante.com/api/motifs-list/')),
      http.get(
        Uri.parse('https://www.parbasante.com/api/workers-list/'),
        headers: {'Authorization': 'Token $token'},
      ),
    ]);

    if (results.every((r) => r.statusCode == 200)) {
      setState(() {
        _types      = jsonDecode(results[0].body);
        _structures = jsonDecode(results[1].body);
        _services   = jsonDecode(results[2].body);
        _profils    = jsonDecode(results[3].body);
        _motifs     = jsonDecode(results[4].body);
        _workers    = jsonDecode(results[5].body);
      });
    } else {
      setState(() {
        _error = "Erreur de chargement des listes";
      });
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (d != null) {
      setState(() {
        if (isStart) _startDate = d;
        else         _endDate   = d;
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) {
      setState(() {
        if (isStart) _startTime = t;
        else         _endTime   = t;
      });
    }
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    return DateFormat('yyyy-MM-dd').format(d);
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return '';
    final now = DateTime.now();
    final dt  = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return DateFormat('HH:mm:ss').format(dt);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final prefs     = await SharedPreferences.getInstance();
    final token     = prefs.getString('token') ?? '';
    final managerId = prefs.getInt('userId');

    final body = {
      'type':              _selectedType,
      'structure':         _selectedStructure,
      'service':           _selectedService,
      'profil':            _selectedProfil,
      'startDate':         _fmtDate(_startDate),
      'finishDate':        _fmtDate(_endDate),
      'startTime':         _fmtTime(_startTime),
      'finishTime':        _fmtTime(_endTime),
      'motif':             _selectedMotif,
      'justification':     _justifCtrl.text.trim(),
      'replacedFirstName': _firstNameCtrl.text.trim(),
      'replacedLastName':  _lastNameCtrl.text.trim(),
      'worker':            _selectedWorker,
      'administrator':     managerId,
    };

    final res = await http.post(
      Uri.parse('https://www.parbasante.com/api/mission/declare/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type':  'application/json',
      },
      body: jsonEncode(body),
    );

    setState(() => _isSubmitting = false);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final newMission = jsonDecode(res.body);
      Navigator.of(context).pop(newMission); // ← on renvoie tout l’objet
    } else {
      setState(() {
        _error = 'Erreur API ${res.statusCode}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Déclarer une mission')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_error != null)
                Text(_error!, style: TextStyle(color: Colors.red)),

              // Type
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Type de mission'),
                isExpanded: true,
                value: _selectedType,
                items: _types.cast<Map<String,dynamic>>()
                    .map((t) => DropdownMenuItem<int>(
                  value: t['id'] as int?,
                  child: Text(t['name'] as String? ?? '–'),
                ))
                    .where((i) => i.value != null)
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v),
                validator: (v) => v == null ? 'Champ requis' : null,
              ),

              // Structure
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Structure'),
                isExpanded: true,
                value: _selectedStructure,
                items: _structures.cast<Map<String,dynamic>>()
                    .map((s) => DropdownMenuItem<int>(
                  value: s['id'] as int?,
                  child: Text(s['name'] as String? ?? '–'),
                ))
                    .where((i) => i.value != null)
                    .toList(),
                onChanged: (v) => setState(() => _selectedStructure = v),
                validator: (v) => v == null ? 'Champ requis' : null,
              ),

              // Service
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Service'),
                isExpanded: true,
                value: _selectedService,
                items: _services.cast<Map<String,dynamic>>()
                    .map((s) => DropdownMenuItem<int>(
                  value: s['id'] as int?,
                  child: Text(s['name'] as String? ?? '–'),
                ))
                    .where((i) => i.value != null)
                    .toList(),
                onChanged: (v) => setState(() => _selectedService = v),
                validator: (v) => v == null ? 'Champ requis' : null,
              ),

              // Profil
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Profil'),
                isExpanded: true,
                value: _selectedProfil,
                items: _profils.cast<Map<String,dynamic>>()
                    .map((p) {
                  final name = (p['name'] as String?) ?? (p['nom'] as String?) ?? '–';
                  return DropdownMenuItem<int>(
                    value: p['id'] as int?,
                    child: Text(name),
                  );
                })
                    .where((i) => i.value != null)
                    .toList(),
                onChanged: (v) => setState(() => _selectedProfil = v),
                validator: (v) => v == null ? 'Champ requis' : null,
              ),

              // Dates / heures
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(true),
                      child: Text(_startDate == null ? 'Date début' : _fmtDate(_startDate)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(false),
                      child: Text(_endDate == null ? 'Date fin'    : _fmtDate(_endDate)),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(true),
                      child: Text(_startTime == null ? 'Heure début' : _fmtTime(_startTime)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(false),
                      child: Text(_endTime == null ? 'Heure fin'    : _fmtTime(_endTime)),
                    ),
                  ),
                ],
              ),

              // Motif
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Motif'),
                isExpanded: true,
                value: _selectedMotif,
                items: _motifs.cast<Map<String,dynamic>>()
                    .map((m) => DropdownMenuItem<int>(
                  value: m['id'] as int?,
                  child: Text(m['name'] as String? ?? '–'),
                ))
                    .where((i) => i.value != null)
                    .toList(),
                onChanged: (v) => setState(() => _selectedMotif = v),
                validator: (v) => v == null ? 'Champ requis' : null,
              ),

              // Justification
              TextFormField(
                controller: _justifCtrl,
                decoration: InputDecoration(labelText: 'Justification'),
              ),

              // Remplaçant
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Remplaçant'),
                isExpanded: true,
                value: _selectedWorker,
                items: _workers.cast<Map<String,dynamic>>()
                    .map((w) {
                  final u = w['user'] as Map<String,dynamic>? ?? {};
                  final id = u['id'] as int?;
                  final username = u['username'] as String? ?? '';
                  final first    = u['first_name'] as String? ?? '';
                  final last     = u['last_name'] as String? ?? '';
                  final name     = username.isNotEmpty ? username : '$first $last'.trim();
                  return DropdownMenuItem<int>(
                    value: id,
                    child: Text(name.isNotEmpty ? name : '–'),
                  );
                })
                    .where((i) => i.value != null)
                    .toList(),
                onChanged: (v) => setState(() => _selectedWorker = v),
                validator: (v) => v == null ? 'Champ requis' : null,
              ),

              // Remplacé
              TextFormField(
                controller: _firstNameCtrl,
                decoration: InputDecoration(labelText: 'Prénom remplacé'),
              ),
              TextFormField(
                controller: _lastNameCtrl,
                decoration: InputDecoration(labelText: 'Nom remplacé'),
              ),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Déclarer la mission'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
