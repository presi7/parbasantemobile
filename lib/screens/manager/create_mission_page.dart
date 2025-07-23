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
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lieuController = TextEditingController();
  DateTime? _dateDebut;
  DateTime? _dateFin;

  List services = [];
  List categories = [];
  List structures = [];
  List metiers = [];
  List motifs = [];
  List statuts = [];

  String? _selectedService;
  String? _selectedCategorie;
  String? _selectedStructure;
  String? _selectedMetier;
  String? _selectedMotif;
  String? _selectedStatut;

  bool _isSubmitting = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    fetchDropdowns();
  }

  Future<void> fetchDropdowns() async {
    try {
      final resServices = await http.get(Uri.parse('https://www.parbasante.com/api/services-list/'));
      final resCategories = await http.get(Uri.parse('https://www.parbasante.com/api/missions-category-list/'));
      final resStructures = await http.get(Uri.parse('https://www.parbasante.com/api/structures-list/'));
      final resMetiers = await http.get(Uri.parse('https://www.parbasante.com/api/metier-category-list/'));
      final resMotifs = await http.get(Uri.parse('https://www.parbasante.com/api/motifs-list/'));
      final resStatuts = await http.get(Uri.parse('https://www.parbasante.com/api/statuts-category-list/'));

      if (resServices.statusCode == 200 &&
          resCategories.statusCode == 200 &&
          resStructures.statusCode == 200 &&
          resMetiers.statusCode == 200 &&
          resMotifs.statusCode == 200 &&
          resStatuts.statusCode == 200) {
        setState(() {
          services = jsonDecode(resServices.body);
          categories = jsonDecode(resCategories.body);
          structures = jsonDecode(resStructures.body);
          metiers = jsonDecode(resMetiers.body);
          motifs = jsonDecode(resMotifs.body);
          statuts = jsonDecode(resStatuts.body);
        });
      } else {
        setState(() {
          _message = "Erreur de chargement des données.";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Erreur de chargement : $e";
      });
    }
  }

  Future<void> createMission() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateDebut == null || _dateFin == null) {
      setState(() => _message = "Veuillez choisir les dates.");
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final body = {
      'titre': _titreController.text,
      'description': _descriptionController.text,
      'lieu': _lieuController.text,
      'date_debut': _dateDebut!.toIso8601String(),
      'date_fin': _dateFin!.toIso8601String(),
      'service': _selectedService,
      'categorie': _selectedCategorie,
      'structure': _selectedStructure,
      'metier': _selectedMetier,
      'motif': _selectedMotif,
      'statut': _selectedStatut,
    };

    final res = await http.post(
      Uri.parse('https://www.parbasante.com/api/mission/create/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    setState(() => _isSubmitting = false);

    if (res.statusCode == 201 || res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Mission créée avec succès !")),
      );
      Navigator.pop(context);
    } else {
      final err = jsonDecode(res.body);
      setState(() => _message = err['detail'] ?? "❌ Erreur lors de la création.");
    }
  }

  Future<void> pickDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(Duration(days: 1)),
      lastDate: now.add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _dateDebut = picked;
        else _dateFin = picked;
      });
    }
  }

  Widget buildDropdown({
    required String label,
    required List data,
    required String? selectedValue,
    required Function(String?) onChanged,
    required String keyName,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      value: selectedValue,
      items: data
          .where((e) => e[keyName] != null)
          .map<DropdownMenuItem<String>>((e) {
        return DropdownMenuItem(
          value: e['id'].toString(),
          child: Text(e[keyName] ?? 'Inconnu'),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? "Requis" : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Créer une mission")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _titreController,
              decoration: InputDecoration(labelText: "Titre"),
              validator: (val) => val!.isEmpty ? "Champ requis" : null,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Description"),
              maxLines: 3,
              validator: (val) => val!.isEmpty ? "Champ requis" : null,
            ),
            TextFormField(
              controller: _lieuController,
              decoration: InputDecoration(labelText: "Lieu"),
              validator: (val) => val!.isEmpty ? "Champ requis" : null,
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => pickDate(context, true),
                    child: Text(_dateDebut == null
                        ? "Date début"
                        : "Début : ${_dateDebut!.toLocal().toString().split(' ')[0]}"),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => pickDate(context, false),
                    child: Text(_dateFin == null
                        ? "Date fin"
                        : "Fin : ${_dateFin!.toLocal().toString().split(' ')[0]}"),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            buildDropdown(
              label: "Service",
              data: services,
              selectedValue: _selectedService,
              onChanged: (val) => setState(() => _selectedService = val),
              keyName: 'nom',
            ),
            buildDropdown(
              label: "Catégorie",
              data: categories,
              selectedValue: _selectedCategorie,
              onChanged: (val) => setState(() => _selectedCategorie = val),
              keyName: 'nom',
            ),
            buildDropdown(
              label: "Structure",
              data: structures,
              selectedValue: _selectedStructure,
              onChanged: (val) => setState(() => _selectedStructure = val),
              keyName: 'nom',
            ),
            buildDropdown(
              label: "Profil (métier)",
              data: metiers,
              selectedValue: _selectedMetier,
              onChanged: (val) => setState(() => _selectedMetier = val),
              keyName: 'nom',
            ),
            buildDropdown(
              label: "Motif d’absence",
              data: motifs,
              selectedValue: _selectedMotif,
              onChanged: (val) => setState(() => _selectedMotif = val),
              keyName: 'nom',
            ),
            buildDropdown(
              label: "Statut de l’agent",
              data: statuts,
              selectedValue: _selectedStatut,
              onChanged: (val) => setState(() => _selectedStatut = val),
              keyName: 'nom',
            ),
            SizedBox(height: 20),
            if (_message != null)
              Text(_message!, style: TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _isSubmitting ? null : createMission,
              child: _isSubmitting
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Créer la mission"),
            ),
          ]),
        ),
      ),
    );
  }
}
