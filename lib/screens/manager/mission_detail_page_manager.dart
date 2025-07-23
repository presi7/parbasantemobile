import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MissionDetailPageManager extends StatefulWidget {
  final int missionId;

  MissionDetailPageManager({required this.missionId});

  @override
  _MissionDetailPageManagerState createState() => _MissionDetailPageManagerState();
}

class _MissionDetailPageManagerState extends State<MissionDetailPageManager> {
  Map<String, dynamic>? _mission;
  List<dynamic> _candidates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadMissionDetails();
  }

  Future<void> loadMissionDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      // Détails mission
      final resMission = await http.get(
        Uri.parse('https://www.parbasante.com/api/mission/${widget.missionId}/read/'),
        headers: {'Authorization': 'Token $token'},
      );

      // Liste candidats
      final resCandidates = await http.get(
        Uri.parse('https://www.parbasante.com/api/mission/${widget.missionId}/candidates-list/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (resMission.statusCode == 200 && resCandidates.statusCode == 200) {
        setState(() {
          _mission = jsonDecode(resMission.body);
          _candidates = jsonDecode(resCandidates.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Erreur de chargement.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Erreur : $e";
        _isLoading = false;
      });
    }
  }

  Future<void> attribuerMission(int workerId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.post(
      Uri.parse('https://www.parbasante.com/api/mission/${widget.missionId}/give/worker/$workerId/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Mission attribuée au candidat.")),
      );
      await loadMissionDetails(); // recharge les candidats
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Échec de l’attribution.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Détail Mission")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_mission?['titre'] ?? '', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(_mission?['description'] ?? ''),
            SizedBox(height: 10),
            Text("📍 Lieu : ${_mission?['lieu'] ?? ''}"),
            Text("📅 Du ${_mission?['date_debut'] ?? ''} au ${_mission?['date_fin'] ?? ''}"),
            Text("🗂 Catégorie : ${_mission?['categorie_nom'] ?? ''}"),
            Text("🏥 Service : ${_mission?['service_nom'] ?? ''}"),
            Divider(height: 30),
            Text("👥 Candidats :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_candidates.isEmpty)
              Text("Aucun candidat pour l’instant."),
            for (var c in _candidates)
              Card(
                child: ListTile(
                  title: Text("${c['prenom']} ${c['nom']}"),
                  subtitle: Text("Statut : ${c['statut']} | Téléphone : ${c['telephone']}"),
                  trailing: ElevatedButton(
                    child: Text("Attribuer"),
                    onPressed: () => attribuerMission(c['id']),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
