// lib/screens/manager/manager_home_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'create_mission_page.dart';
import 'declare_mission_page.dart';
import 'reseau_page.dart';
import 'toutes_les_missions_page.dart';

class ManagerHomePage extends StatefulWidget {
  @override
  _ManagerHomePageState createState() => _ManagerHomePageState();
}

class _ManagerHomePageState extends State<ManagerHomePage> with TickerProviderStateMixin {
  List<dynamic> _missions = [];
  List<dynamic> _structures = [];
  List<dynamic> _services = [];
  List<dynamic> _profils = [];
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // PARBA Brand Colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightBlue = Color(0xFF64B5F6);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color backgroundColor = Color(0xFFF8FFFE);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchAllData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final managerId = prefs.getInt('userId');

    if (token == null || managerId == null) {
      setState(() {
        _error = "Token ou ID manager manquant";
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
          _error = null;
          _isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() {
          _error = 'Erreur HTTP lors du chargement';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur réseau : $e';
        _isLoading = false;
      });
    }
  }

  String _getName(List<dynamic> list, int id, {String? fallbackKey}) {
    final found = list.firstWhere((e) => e['id'] == id, orElse: () => null);
    if (found == null) return 'Non trouvé';
    if (fallbackKey != null && found[fallbackKey] != null) return found[fallbackKey];
    return found['name'] ?? found['nom'] ?? 'Non trouvé';
  }

  Future<void> _onDeclareTap() async {
    final returned = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => DeclareMissionPage()),
    );
    if (returned != null) {
      setState(() {
        _missions.add(returned);
      });
    }
  }

  Future<void> _navigateAndRefresh(Widget page) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (result == true) {
      _fetchAllData();
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
        _navigateAndRefresh(CreateMissionPage());
        break;
      case 3:
        _onDeclareTap();
        break;
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _buildStatsCard() {
    final totalMissions = _missions.length;
    final expressMissions = _missions.where((m) => m['isExpress'] == true).length;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.medical_services, color: Colors.white, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tableau de bord',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Gestion des missions',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total', totalMissions.toString(), Icons.assignment),
              ),
              SizedBox(width: 20),
              Expanded(
                child: _buildStatItem('Express', expressMissions.toString(), Icons.flash_on),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Actions rapides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Créer Mission',
                  Icons.add_circle_outline,
                  primaryGreen,
                      () => _navigateAndRefresh(CreateMissionPage()),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Déclarer',
                  Icons.notification_important_outlined,
                  Colors.orange,
                  _onDeclareTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission, int index) {
    final isExpress = mission['isExpress'] == true;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/mission_detail_page_manager',
                    arguments: mission['id'],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isExpress ? Colors.orange.withOpacity(0.1) : primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isExpress ? Icons.flash_on : Icons.schedule,
                                    size: 16,
                                    color: isExpress ? Colors.orange : primaryBlue,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    isExpress ? 'Express' : 'Standard',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isExpress ? Colors.orange : primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.arrow_forward_ios, size: 16, color: textSecondary),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          mission['referenceNumber'] ?? '—',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.person_outline,
                          'Remplace : ${mission['replacedFirstName']} ${mission['replacedLastName']}',
                        ),
                        _buildInfoRow(
                          Icons.calendar_today_outlined,
                          '${mission['startDate']} → ${mission['finishDate']}',
                        ),
                        _buildInfoRow(
                          Icons.access_time_outlined,
                          '${mission['startTime']} – ${mission['finishTime']}',
                        ),
                        _buildInfoRow(
                          Icons.business_outlined,
                          _getName(_structures, mission['structure']),
                        ),
                        _buildInfoRow(
                          Icons.work_outline,
                          _getName(_services, mission['service']),
                        ),
                        _buildInfoRow(
                          Icons.medical_services_outlined,
                          _getName(_profils, mission['profil'], fallbackKey: 'nom'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textSecondary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardColor,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue, primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.medical_services, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PARBA",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Text(
                  "Gestion des missions",
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.list_alt, color: textPrimary),
            ),
            tooltip: "Voir toutes les missions",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ToutesLesMissionsPage()),
            ),
          ),
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.logout, color: Colors.red),
            ),
            tooltip: "Déconnexion",
            onPressed: _logout,
          ),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement des missions...',
              style: TextStyle(color: textSecondary),
            ),
          ],
        ),
      )
          : (_error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Réessayer'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCard(),
            _buildQuickActions(),
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Missions récentes (${_missions.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ),
            _missions.isEmpty
                ? Container(
              margin: EdgeInsets.all(32),
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucune mission trouvée',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Commencez par créer votre première mission',
                    style: TextStyle(color: textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : Column(
              children: _missions
                  .asMap()
                  .entries
                  .map((entry) => _buildMissionCard(entry.value, entry.key))
                  .toList(),
            ),
            SizedBox(height: 100),
          ],
        ),
      )),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onBottomNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: primaryGreen,
          unselectedItemColor: textSecondary,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 0 ? primaryGreen.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.list),
              ),
              label: 'Missions',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 1 ? primaryGreen.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.people),
              ),
              label: 'Réseau',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 2 ? primaryGreen.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add),
              ),
              label: 'Créer',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 3 ? primaryGreen.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.notification_important),
              ),
              label: 'Déclarer',
            ),
          ],
        ),
      ),
    );
  }
}