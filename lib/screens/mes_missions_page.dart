import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:parbasantemobile/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MesMissionsPage extends StatefulWidget {
  @override
  _MesMissionsPageState createState() => _MesMissionsPageState();
}

class _MesMissionsPageState extends State<MesMissionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List _missionsApplied = [];
  List _missionsGranted = [];
  bool _isLoading = true;
  String? _error;

  // Couleurs du logo PARBA
  static const Color parbaBlue = Color(0xFF1E88E5);
  static const Color parbaLightBlue = Color(0xFF64B5F6);
  static const Color parbaGreen = Color(0xFF4CAF50);
  static const Color parbaLightGreen = Color(0xFF81C784);
  static const Color parbaWhite = Color(0xFFFFFFFF);
  static const Color parbaGray = Color(0xFFF5F5F5);
  static const Color parbaTextDark = Color(0xFF2C3E50);
  static const Color parbaTextLight = Color(0xFF7F8C8D);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchMissions();
  }

  Future<void> fetchMissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final token = await AuthService.getToken();
    final prefs = await SharedPreferences.getInstance();
    final workerId = prefs.getInt('userId');

    if (workerId == null) {
      setState(() {
        _error = "⚠️ Impossible de récupérer l'ID du travailleur.";
        _isLoading = false;
      });
      return;
    }

    try {
      final appliedUrl = Uri.parse('https://www.parbasante.com/api/worker/$workerId/missions-applied/');
      final grantedUrl = Uri.parse('https://www.parbasante.com/api/worker/$workerId/missions-granted/');

      final resApplied = await http.get(appliedUrl, headers: {'Authorization': 'Token $token'});
      final resGranted = await http.get(grantedUrl, headers: {'Authorization': 'Token $token'});

      if (resApplied.statusCode == 200 && resGranted.statusCode == 200) {
        setState(() {
          _missionsApplied = jsonDecode(resApplied.body);
          _missionsGranted = jsonDecode(resGranted.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur lors du chargement des missions.';
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

  Widget _buildEmptyState(String message, IconData icon, bool isApplied) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isApplied ? parbaBlue.withOpacity(0.1) : parbaGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              icon,
              size: 60,
              color: isApplied ? parbaBlue : parbaGreen,
            ),
          ),
          SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: parbaTextDark,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            isApplied
                ? "Vous n'avez postulé à aucune mission pour le moment."
                : "Aucune mission ne vous a été attribuée pour le moment.",
            style: TextStyle(
              fontSize: 14,
              color: parbaTextLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission, bool isGranted) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: parbaWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Action lors du tap sur la mission
        },
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isGranted ? parbaGreen.withOpacity(0.1) : parbaBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isGranted ? Icons.assignment_turned_in : Icons.assignment,
                      color: isGranted ? parbaGreen : parbaBlue,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission['titre'] ?? 'Mission',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: parbaTextDark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isGranted ? parbaGreen : parbaBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isGranted ? 'Attribuée' : 'Postulée',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: parbaWhite,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (mission['description'] != null && mission['description'].isNotEmpty)
                Text(
                  mission['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: parbaTextLight,
                    height: 1.4,
                  ),
                ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: parbaTextLight,
                  ),
                  SizedBox(width: 6),
                  Text(
                    mission['date_creation'] ?? 'Date non disponible',
                    style: TextStyle(
                      fontSize: 12,
                      color: parbaTextLight,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: parbaTextLight,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMissionList(List missions, bool isGranted) {
    if (missions.isEmpty) {
      return _buildEmptyState(
        isGranted ? "Aucune mission attribuée" : "Aucune mission disponible",
        isGranted ? Icons.assignment_turned_in_outlined : Icons.work_outline,
        !isGranted,
      );
    }

    return RefreshIndicator(
      onRefresh: fetchMissions,
      color: parbaBlue,
      backgroundColor: parbaWhite,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 16),
        itemCount: missions.length,
        itemBuilder: (context, index) {
          final mission = missions[index];
          return _buildMissionCard(mission, isGranted);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: parbaGray,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: parbaWhite,
        title: Text(
          'Mes Missions',
          style: TextStyle(
            color: parbaTextDark,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: parbaTextDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: parbaBlue),
            onPressed: fetchMissions,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Container(
            color: parbaWhite,
            child: TabBar(
              controller: _tabController,
              indicatorColor: parbaBlue,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: parbaBlue,
              unselectedLabelColor: parbaTextLight,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment, size: 20),
                      SizedBox(width: 8),
                      Text('Postulées'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in, size: 20),
                      SizedBox(width: 8),
                      Text('Attribuées'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Container(
        color: parbaGray,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(parbaBlue),
                strokeWidth: 3,
              ),
              SizedBox(height: 24),
              Text(
                'Chargement des missions...',
                style: TextStyle(
                  fontSize: 16,
                  color: parbaTextLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      )
          : _error != null
          ? Container(
        color: parbaGray,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 24),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 16,
                  color: parbaTextDark,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchMissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: parbaBlue,
                  foregroundColor: parbaWhite,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Réessayer',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          buildMissionList(_missionsApplied, false),
          buildMissionList(_missionsGranted, true),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}