import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'create_mission_page.dart';
import 'reseau_page.dart';
import 'toutes_les_missions_page.dart';
import 'declare_mission_page.dart'; // Added import for DeclareMissionPage
// import 'profile_manager_page.dart'; // supprimé

class ManagerHomePage extends StatefulWidget {
  @override
  _ManagerHomePageState createState() => _ManagerHomePageState();
}

class _ManagerHomePageState extends State<ManagerHomePage> {
  List<dynamic> _missions = [];
  List<dynamic> _structures = [];
  List<dynamic> _services = [];
  List<dynamic> _profils = [];
  bool _isLoading = true;
  String? _error;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final managerId = prefs.getInt('userId');

    if (token == null || managerId == null) {
      setState(() {
        _error = "Token ou ID manager non trouvé.";
        _isLoading = false;
      });
      return;
    }

    try {
      final missionsRes = await http.get(
        Uri.parse('https://www.parbasante.com/api/manager/$managerId/missions-created/'),
        headers: {'Authorization': 'Token $token'},
      );
      final structRes = await http.get(Uri.parse('https://www.parbasante.com/api/structures-list/'));
      final servRes = await http.get(Uri.parse('https://www.parbasante.com/api/services-list/'));
      final profilsRes = await http.get(Uri.parse('https://www.parbasante.com/api/metier-category-list/'));

      if (missionsRes.statusCode == 200 &&
          structRes.statusCode == 200 &&
          servRes.statusCode == 200 &&
          profilsRes.statusCode == 200) {
        setState(() {
          _missions = jsonDecode(missionsRes.body);
          _structures = jsonDecode(structRes.body);
          _services = jsonDecode(servRes.body);
          _profils = jsonDecode(profilsRes.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '❌ Erreur de chargement des données.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur : $e';
        _isLoading = false;
      });
    }
  }

  String getStructureName(int id) {
    final match = _structures.firstWhere(
          (s) => s['id'] == id,
      orElse: () => null,
    );
    return match != null ? match['name'] ?? 'Non trouvé' : 'Non trouvé';
  }

  String getServiceName(int id) {
    final match = _services.firstWhere(
          (s) => s['id'] == id,
      orElse: () => null,
    );
    return match != null ? match['name'] ?? 'Non trouvé' : 'Non trouvé';
  }

  String getProfilName(int id) {
    final match = _profils.firstWhere(
          (p) => p['id'] == id,
      orElse: () => null,
    );
    return match != null ? match['name'] ?? match['nom'] ?? 'Non trouvé' : 'Non trouvé';
  }

  void _onBottomNavTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    switch (index) {
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => ReseauPage()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => CreateMissionPage()));
        break;
      case 3: // ✅ au lieu de case 4
        Navigator.push(context, MaterialPageRoute(builder: (_) => DeclareMissionPage()));
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Missions créées"),
        actions: [
          IconButton(
            icon: Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ToutesLesMissionsPage()));
            },
            tooltip: "Voir toutes les missions",
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _missions.isEmpty
          ? Center(child: Text("Aucune mission trouvée."))
          : ListView.builder(
        itemCount: _missions.length,
        itemBuilder: (context, index) {
          final mission = _missions[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text(mission['referenceNumber'] ?? 'Mission'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('👤 Remplace : ${mission['replacedFirstName']} ${mission['replacedLastName']}'),
                  Text('📅 ${mission['startDate']} → ${mission['finishDate']}'),
                  Text('🕒 ${mission['startTime']} – ${mission['finishTime']}'),
                  Text('🏥 Structure : ${getStructureName(mission['structure'])}'),
                  Text('🧪 Service : ${getServiceName(mission['service'])}'),
                  Text('🧑‍⚕️ Profil : ${getProfilName(mission['profil'])}'),
                  Text('🚀 Type : ${mission['isExpress'] == true ? "Express" : "Standard"}'),
                ],
              ),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/mission_detail_page_manager',
                  arguments: mission['id'],
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Missions'),   // index 0
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Réseau'),   // index 1
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Créer'),       // index 2
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Déclarer'),// index 3
        ],
      ),
    );
  }
}
