import 'package:flutter/material.dart';
import 'create_manager_page.dart';
import 'structure_list_page.dart'; // à créer ensuite
import '../manager/profile_manager_page.dart'; // ou une page DRH dédiée

class DrhMainPage extends StatefulWidget {
  @override
  _DrhMainPageState createState() => _DrhMainPageState();
}

class _DrhMainPageState extends State<DrhMainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    CreateManagerPage(),       // Onglet 0
    StructureListPage(),       // Onglet 1 (à créer)
    ProfileManagerPage(),      // Onglet 2 (profil DRH temporaire)
  ];

  final List<String> _titles = [
    'Créer Manager',
    'Structures',
    'Profil',
  ];

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person_add), label: 'Créer'),
          BottomNavigationBarItem(icon: Icon(Icons.apartment), label: 'Structures'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
