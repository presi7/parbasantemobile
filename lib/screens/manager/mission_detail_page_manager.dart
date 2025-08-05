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

class _MissionDetailPageManagerState extends State<MissionDetailPageManager> with TickerProviderStateMixin {
  Map<String, dynamic>? _mission;
  List<dynamic> _candidates = [];
  List<dynamic> _structures = [];
  List<dynamic> _services = [];
  List<dynamic> _profils = [];
  List<dynamic> _motifs = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // PARBA Brand Colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightBlue = Color(0xFF64B5F6);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color backgroundColor = Color(0xFFF8FFFE);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color successColor = Color(0xFF27AE60);
  static const Color warningColor = Color(0xFFF39C12);
  static const Color errorColor = Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    loadMissionDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        _animationController.forward();
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
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.assignment_turned_in, color: primaryBlue),
            SizedBox(width: 8),
            Text('Confirmer l\'attribution'),
          ],
        ),
        content: Text('Êtes-vous sûr de vouloir attribuer cette mission à ce candidat ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryBlue)),
            SizedBox(width: 16),
            Text('Attribution en cours...'),
          ],
        ),
      ),
    );

    try {
      final res = await http.post(
        Uri.parse('https://www.parbasante.com/api/mission/${widget.missionId}/give/worker/$workerId/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text("Mission attribuée avec succès !"),
              ],
            ),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        await loadMissionDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text("Échec de l'attribution"),
              ],
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text("Erreur: $e"),
            ],
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Widget _buildHeaderCard() {
    final m = _mission!;
    final isAssigned = m['assigned'] != null;
    final isExpress = m['isExpress'] == true;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAssigned
              ? [successColor, lightGreen]
              : [primaryBlue, lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isAssigned ? successColor : primaryBlue).withOpacity(0.3),
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
                child: Icon(
                  isAssigned ? Icons.assignment_turned_in : Icons.assignment,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m['referenceNumber'] ?? 'Référence inconnue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isAssigned ? 'Mission pourvue' : 'Mission en attente',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (isExpress)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: warningColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flash_on, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Express',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.person_outline, color: Colors.white.withOpacity(0.8), size: 18),
              SizedBox(width: 8),
              Text(
                'Remplace: ${m['replacedFirstName']} ${m['replacedLastName']}',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final m = _mission!;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: primaryBlue, size: 24),
              SizedBox(width: 8),
              Text(
                'Informations de la mission',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildInfoRow(Icons.business_outlined, 'Structure', getNameById(_structures, m['structure'])),
          _buildInfoRow(Icons.work_outline, 'Service', getNameById(_services, m['service'])),
          _buildInfoRow(Icons.medical_services_outlined, 'Profil', getNameById(_profils, m['profil'])),
          _buildInfoRow(Icons.description_outlined, 'Motif', getNameById(_motifs, m['motif'])),
          _buildInfoRow(Icons.admin_panel_settings_outlined, 'Administrateur ID', m['administrator'].toString()),
          _buildInfoRow(Icons.calendar_today_outlined, 'Période', '${m['startDate']} → ${m['finishDate']}'),
          _buildInfoRow(Icons.access_time_outlined, 'Horaires', '${m['startTime']} - ${m['finishTime']}'),
          _buildInfoRow(
            Icons.category_outlined,
            'Type',
            m['type'] == 2 ? 'Heures supplémentaires' : 'Vacation',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textSecondary),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedWorkerCard() {
    final assigned = _mission!['assigned'];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [successColor, lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: successColor.withOpacity(0.3),
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
                child: Icon(Icons.person_pin, color: Colors.white, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remplaçant assigné',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "${assigned['prenom'] ?? 'N/A'} ${assigned['nom'] ?? ''}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.check_circle, color: Colors.white, size: 24),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.phone_outlined, color: Colors.white.withOpacity(0.8), size: 18),
              SizedBox(width: 8),
              Text(
                'Téléphone: ${assigned['telephone'] ?? 'non disponible'}',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.event_outlined, color: Colors.white.withOpacity(0.8), size: 18),
              SizedBox(width: 8),
              Text(
                'Attribuée le: ${assigned['attributionDate'] ?? 'date inconnue'}',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCandidatesSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_outlined, color: primaryBlue, size: 24),
              SizedBox(width: 8),
              Text(
                'Candidats (${_candidates.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_candidates.isEmpty)
            Container(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.person_off_outlined, size: 48, color: textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'Aucun candidat pour cette mission',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...(_candidates.map((candidate) => _buildCandidateCard(candidate)).toList()),
        ],
      ),
    );
  }

  Widget _buildCandidateCard(Map<String, dynamic> candidate) {
    final isAssigned = _mission!['assigned'] != null &&
        _mission!['assigned']['id'] == candidate['id'];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAssigned ? successColor.withOpacity(0.1) : backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAssigned ? successColor : Colors.grey.withOpacity(0.2),
          width: isAssigned ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAssigned ? successColor : primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isAssigned ? Icons.person_pin : Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${candidate['prenom']} ${candidate['nom']}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: textSecondary),
                    SizedBox(width: 4),
                    Text(
                      candidate['telephone'] ?? 'N/A',
                      style: TextStyle(color: textSecondary, fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.info, size: 14, color: textSecondary),
                    SizedBox(width: 4),
                    Text(
                      'Statut: ${candidate['statut']}',
                      style: TextStyle(color: textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isAssigned)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: successColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Assigné',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: () => attribuerMission(candidate['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_turned_in, size: 16),
                  SizedBox(width: 4),
                  Text('Attribuer'),
                ],
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
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, color: primaryBlue),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue, primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.assignment, color: Colors.white, size: 18),
            ),
            SizedBox(width: 12),
            Text(
              "Détail Mission",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
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
              child: Icon(Icons.refresh, color: textPrimary),
            ),
            onPressed: loadMissionDetails,
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
              'Chargement des détails...',
              style: TextStyle(color: textSecondary),
            ),
          ],
        ),
      )
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: errorColor),
            SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: errorColor, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadMissionDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 18),
                  SizedBox(width: 8),
                  Text('Réessayer'),
                ],
              ),
            ),
          ],
        ),
      )
          : _mission == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: textSecondary),
            SizedBox(height: 16),
            Text(
              'Aucune donnée trouvée.',
              style: TextStyle(
                fontSize: 18,
                color: textPrimary,
              ),
            ),
          ],
        ),
      )
          : SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                _buildInfoSection(),
                if (_mission!['assigned'] != null && _mission!['assigned'] is Map<String, dynamic>)
                  _buildAssignedWorkerCard(),
                _buildCandidatesSection(),
                SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}