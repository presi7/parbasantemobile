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
  List<dynamic> _structures = [];
  List<dynamic> _services = [];
  List<dynamic> _profils = [];
  List<dynamic> _motifs = [];
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
      final resMission = await http.get(
        Uri.parse('https://www.parbasante.com/api/mission/${widget.missionId}/read/'),
        headers: {'Authorization': 'Token $token'},
      );

      final resCandidates = await http.get(
        Uri.parse('https://www.parbasante.com/api/mission/${widget.missionId}/candidates-list/'),
        headers: {'Authorization': 'Token $token'},
      );

      final res1 = await http.get(Uri.parse('https://www.parbasante.com/api/structures-list/'));
      final res2 = await http.get(Uri.parse('https://www.parbasante.com/api/services-list/'));
      final res3 = await http.get(Uri.parse('https://www.parbasante.com/api/metier-category-list/'));
      final res4 = await http.get(Uri.parse('https://www.parbasante.com/api/motifs-list/'));

      if (resMission.statusCode == 200 &&
          resCandidates.statusCode == 200 &&
          res1.statusCode == 200 &&
          res2.statusCode == 200 &&
          res3.statusCode == 200 &&
          res4.statusCode == 200) {
        setState(() {
          _mission = jsonDecode(resMission.body);
          _candidates = jsonDecode(resCandidates.body);
          _structures = jsonDecode(res1.body);
          _services = jsonDecode(res2.body);
          _profils = jsonDecode(res3.body);
          _motifs = jsonDecode(res4.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Erreur lors du chargement des données.";
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

  String getNameById(List<dynamic> list, dynamic id) {
    if (id == null) return 'Non trouvé';
    final intId = int.tryParse(id.toString());
    if (intId == null) return 'Non trouvé';
    final match = list.firstWhere((e) => e['id'] == intId, orElse: () => null);
    return match != null ? match['name'] ?? match['nom'] ?? 'Non trouvé' : 'Non trouvé';
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
      await loadMissionDetails();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Échec de l’attribution.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _mission;

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
            if (m == null) Text("Aucune donnée trouvée."),
            if (m != null) ...[
              Text("🆔 Référence : ${m['referenceNumber']}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("🏥 Structure : ${getNameById(_structures, m['structure'])}"),
              Text("🔧 Service : ${getNameById(_services, m['service'])}"),
              Text("👤 Profil : ${getNameById(_profils, m['profil'])}"),
              Text("📝 Motif : ${getNameById(_motifs, m['motif'])}"),
              Text("👨‍💼 Administrateur ID : ${m['administrator']}"),
              Text("🧑 Remplacé : ${m['replacedFirstName']} ${m['replacedLastName']}"),
              Text("📅 Du ${m['startDate']} au ${m['finishDate']}"),
              Text("🕒 De ${m['startTime']} à ${m['finishTime']}"),
              Text("🚨 Type : ${m['type'] == 2 ? 'Heures supplémentaires' : 'Vacation'}"),
              Text("⚡ Mission : ${m['isExpress'] == true ? 'Express' : 'Standard'}"),
              Text(
                "📦 Statut : ${m['assigned'] != null ? 'Mission pourvue' : 'Non pourvue'}",
                style: TextStyle(
                  color: m['assigned'] != null ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (m['assigned'] != null && m['assigned'] is Map<String, dynamic>) ...[
                SizedBox(height: 20),
                Text("👨‍🔧 Remplaçant :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.cyan,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, size: 40, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            "${m['assigned']['prenom'] ?? 'N/A'} ${m['assigned']['nom'] ?? ''}",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "📅 Mission attribuée le ${m['assigned']['attributionDate'] ?? 'date inconnue'}",
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        "📞 Téléphone : ${m['assigned']['telephone'] ?? 'non disponible'}",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
              Divider(height: 30),
              Text("👥 Candidats :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (_candidates.isEmpty)
                Text("Aucun candidat pour l’instant."),
              for (var c in _candidates)
                Card(
                  child: ListTile(
                    title: Text("${c['prenom']} ${c['nom']}"),
                    subtitle: Text("📞 ${c['telephone']} • Statut : ${c['statut']}"),
                    trailing: ElevatedButton(
                      child: Text("Attribuer"),
                      onPressed: () => attribuerMission(c['id']),
                    ),
                  ),
                ),
            ]
          ],
        ),
      ),
    );
  }
}
