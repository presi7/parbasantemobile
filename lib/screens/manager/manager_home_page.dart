import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'create_mission_page.dart';
import 'reseau_page.dart';
import 'profile_manager_page.dart';

class ManagerHomePage extends StatefulWidget {
  @override
  _ManagerHomePageState createState() => _ManagerHomePageState();
}

class _ManagerHomePageState extends State<ManagerHomePage> {
  List<dynamic> _missions = [];
  bool _isLoading = true;
  String? _error;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchMissions();
  }

  Future<void> fetchMissions() async {
    setState(() => _isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() {
        _error = "Token non trouvé.";
        _isLoading = false;
      });
      return;
    }

    try {
      final roleRes = await http.get(
        Uri.parse('https://parbasante.com/account/role/'),
        headers: {'Authorization': 'Token $token'},
      );

      final managerId = jsonDecode(roleRes.body)['id'];

      final missionsRes = await http.get(
        Uri.parse('https://www.parbasante.com/api/manager/$managerId/missions-created/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (missionsRes.statusCode == 200) {
        setState(() {
          _missions = jsonDecode(missionsRes.body);
          _isLoading = false;
        });
      } else {
        throw Exception("Erreur de chargement des missions.");
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur : $e';
        _isLoading = false;
      });
    }
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
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileManagerPage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Missions créées")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView.builder(
        itemCount: _missions.length,
        itemBuilder: (context, index) {
          final mission = _missions[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text(mission['titre'] ?? 'Mission'),
              subtitle: Text('Statut : ${mission['statut'] ?? 'Inconnu'}'),
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
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Missions'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Réseau'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Créer'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
