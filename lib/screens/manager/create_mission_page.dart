// lib/screens/manager/create_mission_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreateMissionPage extends StatefulWidget {
  @override
  _CreateMissionPageState createState() => _CreateMissionPageState();
}

class _CreateMissionPageState extends State<CreateMissionPage> {
  final _formKey = GlobalKey<FormState>();
  final _replacedFirstNameController = TextEditingController();
  final _replacedLastNameController = TextEditingController();
  final _justificationController = TextEditingController();

  List<dynamic> structures = [];
  List<dynamic> services = [];
  List<dynamic> profils = [];
  List<dynamic> motifs = [];
  List<dynamic> types = [
    {"id": "1", "label": "Vacation"},
    {"id": "2", "label": "Heures supplémentaires"}
  ];
  List<dynamic> expressTypes = [
    {"id": "false", "label": "Standard"},
    {"id": "true", "label": "Express"}
  ];

  String? _selectedStructure;
  String? _selectedService;
  String? _selectedProfil;
  String? _selectedMotif;
  String? _selectedType;
  String? _isExpress;

  DateTime? _startDate;
  DateTime? _finishDate;
  TimeOfDay? _startTime;
  TimeOfDay? _finishTime;

  bool _isLoading = false;
  String? _message;
  String? _referenceNumber;

  @override
  void initState() {
    super.initState();
    fetchDropdownData();
    generateReferenceNumber();
  }

  Future<void> fetchDropdownData() async {
    final res1 = await http.get(Uri.parse('https://www.parbasante.com/api/structures-list/'));
    final res2 = await http.get(Uri.parse('https://www.parbasante.com/api/services-list/'));
    final res3 = await http.get(Uri.parse('https://www.parbasante.com/api/metier-category-list/'));
    final res4 = await http.get(Uri.parse('https://www.parbasante.com/api/motifs-list/'));

    if (res1.statusCode == 200 && res2.statusCode == 200 && res3.statusCode == 200 && res4.statusCode == 200) {
      setState(() {
        structures = jsonDecode(res1.body);
        services = jsonDecode(res2.body);
        profils = jsonDecode(res3.body);
        motifs = jsonDecode(res4.body);
      });
    }
  }

  Future<void> generateReferenceNumber() async {
    final now = DateTime.now();
    final dateStr = "${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}";
    final prefs = await SharedPreferences.getInstance();
    final managerId = prefs.getInt('userId') ?? 100;
    final token = prefs.getString('token');

    final res = await http.get(
      Uri.parse('https://www.parbasante.com/api/manager/$managerId/missions-created/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      int countToday = data.where((m) => (m['referenceNumber'] ?? "").toString().contains("REF$dateStr")).length;
      setState(() {
        _referenceNumber = "REF${dateStr}_${(countToday + 1).toString().padLeft(3, '0')}";
      });
    } else {
      setState(() {
        _referenceNumber = "REF${dateStr}_001";
      });
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _finishDate = picked;
      });
    }
  }

  Future<void> pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else _finishTime = picked;
      });
    }
  }

  Future<void> createMission() async {
    if (!_formKey.currentState!.validate()) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final managerId = prefs.getInt('userId');

    if (token == null || managerId == null || _referenceNumber == null) {
      setState(() => _message = "Token, ID ou référence manquants");
      return;
    }

    final body = {
      "referenceNumber": _referenceNumber,
      "type": _selectedType,
      "isExpress": _isExpress,
      "structure": _selectedStructure,
      "service": _selectedService,
      "startDate": _startDate?.toIso8601String().split("T").first,
      "finishDate": _finishDate?.toIso8601String().split("T").first,
      "startTime": _startTime?.format(context),
      "finishTime": _finishTime?.format(context),
      "replacedFirstName": _replacedFirstNameController.text.trim(),
      "replacedLastName": _replacedLastNameController.text.trim(),
      "justification": _justificationController.text.trim(),
      "profil": _selectedProfil,
      "motif": _selectedMotif,
      "administrator": managerId
    };

    setState(() => _isLoading = true);

    final res = await http.post(
      Uri.parse('https://www.parbasante.com/api/mission/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode(body),
    );

    setState(() => _isLoading = false);

    if (res.statusCode == 200 || res.statusCode == 201) {
      Navigator.pop(context);
    } else {
      setState(() => _message = 'Erreur: ${res.body}');
    }
  }

  Widget buildDropdown(String label, List<dynamic> items, String? selected, Function(String?) onChanged, String nameKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        value: selected,
        items: items.map<DropdownMenuItem<String>>((e) {
          return DropdownMenuItem<String>(
            value: e['id'].toString(),
            child: Text(e[nameKey] ?? e['nom'] ?? e['name'] ?? 'Inconnu'),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (val) => val == null ? "Champ requis" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Créer une mission")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_referenceNumber != null)
                Text("Réf. mission : $_referenceNumber", style: TextStyle(fontWeight: FontWeight.bold)),
              buildDropdown("Type (Vacation / Heures Supplémentaires)", types, _selectedType, (val) => setState(() => _selectedType = val), 'label'),
              buildDropdown("Type de mission (Standard / Express)", expressTypes, _isExpress, (val) => setState(() => _isExpress = val), 'label'),
              buildDropdown("Structure", structures, _selectedStructure, (val) => setState(() => _selectedStructure = val), 'name'),
              buildDropdown("Service", services, _selectedService, (val) => setState(() => _selectedService = val), 'name'),
              buildDropdown("Profil", profils, _selectedProfil, (val) => setState(() => _selectedProfil = val), 'name'),
              buildDropdown("Motif", motifs, _selectedMotif, (val) => setState(() => _selectedMotif = val), 'nom'),
              TextFormField(
                controller: _replacedFirstNameController,
                decoration: InputDecoration(labelText: "Prénom de la personne à remplacer"),
                validator: (v) => v!.isEmpty ? "Champ requis" : null,
              ),
              TextFormField(
                controller: _replacedLastNameController,
                decoration: InputDecoration(labelText: "Nom de la personne à remplacer"),
                validator: (v) => v!.isEmpty ? "Champ requis" : null,
              ),
              TextFormField(
                controller: _justificationController,
                decoration: InputDecoration(labelText: "Justification"),
                maxLines: 2,
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => pickDate(true),
                      child: Text(_startDate == null ? "Date début" : _startDate!.toString().split(" ")[0]),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => pickDate(false),
                      child: Text(_finishDate == null ? "Date fin" : _finishDate!.toString().split(" ")[0]),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => pickTime(true),
                      child: Text(_startTime == null ? "Heure début" : _startTime!.format(context)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => pickTime(false),
                      child: Text(_finishTime == null ? "Heure fin" : _finishTime!.format(context)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (_message != null) Text(_message!, style: TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _isLoading ? null : createMission,
                child: _isLoading ? CircularProgressIndicator() : Text("Créer la mission"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
