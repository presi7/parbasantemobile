import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parbasantemobile/screens/manager/mission_detail_page_manager.dart';

class ToutesLesMissionsPage extends StatefulWidget {
  @override
  _ToutesLesMissionsPageState createState() => _ToutesLesMissionsPageState();
}

class _ToutesLesMissionsPageState extends State<ToutesLesMissionsPage> {
  List<dynamic> _missions = [];
  List<dynamic> _structures = [];
  List<dynamic> _services = [];
  List<dynamic> _profils = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final missionsRes = await http.get(
        Uri.parse('https://www.parbasante.com/api/missions-list/'),
        headers: {'Authorization': 'Token $token'},
      );
      final structuresRes = await http.get(Uri.parse('https://www.parbasante.com/api/structures-list/'));
      final servicesRes = await http.get(Uri.parse('https://www.parbasante.com/api/services-list/'));
      final profilsRes = await http.get(Uri.parse('https://www.parbasante.com/api/metier-category-list/'));

      if (missionsRes.statusCode == 200 &&
          structuresRes.statusCode == 200 &&
          servicesRes.statusCode == 200 &&
          profilsRes.statusCode == 200) {
        setState(() {
          _missions = jsonDecode(missionsRes.body);
          _structures = jsonDecode(structuresRes.body);
          _services = jsonDecode(servicesRes.body);
          _profils = jsonDecode(profilsRes.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur HTTP lors du chargement des données.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur : \$e';
        _isLoading = false;
      });
    }
  }

  String getStructureName(dynamic id) {
    final intId = int.tryParse(id.toString());
    final match = _structures.firstWhere((s) => s['id'] == intId, orElse: () => null);
    return match != null ? match['name'] ?? match['nom'] ?? 'Non trouvé' : 'Non trouvé';
  }

  String getServiceName(dynamic id) {
    final intId = int.tryParse(id.toString());
    final match = _services.firstWhere((s) => s['id'] == intId, orElse: () => null);
    return match != null ? match['name'] ?? match['nom'] ?? 'Non trouvé' : 'Non trouvé';
  }

  String getProfilName(dynamic id) {
    final intId = int.tryParse(id.toString());
    final match = _profils.firstWhere((p) => p['id'] == intId, orElse: () => null);
    return match != null ? match['name'] ?? match['nom'] ?? 'Non trouvé' : 'Non trouvé';
  }

  Widget buildMissionCard(Map<String, dynamic> mission) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 2,
      child: ListTile(
        title: Text(
          mission['referenceNumber'] ?? 'Mission',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('🏥 Structure : ${getStructureName(mission['structure'])}'),
            Text('🔧 Service : ${getServiceName(mission['service'])}'),
            Text('👤 Profil : ${getProfilName(mission['profil'])}'),
            Text('🧑 Remplacé : ${mission['replacedFirstName']} ${mission['replacedLastName']}'),
            Text('📅 Du ${mission['startDate']} au ${mission['finishDate']}'),
            Text('🕒 ${mission['startTime']} — ${mission['finishTime']}'),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MissionDetailPageManager(missionId: mission['id']),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Toutes les missions")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _missions.isEmpty
          ? Center(child: Text("Aucune mission disponible."))
          : ListView.builder(
        itemCount: _missions.length,
        itemBuilder: (context, index) {
          return buildMissionCard(_missions[index]);
        },
      ),
    );
  }
}
