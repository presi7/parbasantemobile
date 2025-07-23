import 'package:flutter/material.dart';
import 'missions_disponibles_page.dart';
import 'mes_candidatures_page.dart';
import 'profile_page.dart';
import 'mes_missions_page.dart';
import 'mes_admissions_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final _pages = [
    MissionsDisponiblesPage(),
    MesCandidaturesPage(),
    MesMissionsPage(),
    MesAdmissionsPage(),
    ProfilePage(),
  ];

  final _titles = [
    "Missions Disponibles",
    "Mes Candidatures",
    "Missions Obtenues",
    "Mes Admissions",
    "Mon Profil",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Missions"),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: "Candidatures"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in), label: "Obtenues"),
          BottomNavigationBarItem(icon: Icon(Icons.apartment), label: "Admissions"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}
