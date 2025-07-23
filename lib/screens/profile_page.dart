import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parbasantemobile/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profile;
  List<dynamic> _structuresAutorisees = [];
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
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final token = await AuthService.getToken();
    final prefs = await SharedPreferences.getInstance();
    final workerId = prefs.getInt('userId');

    if (token == null || workerId == null) {
      setState(() {
        _error = "Token ou ID introuvable.";
        _isLoading = false;
      });
      return;
    }

    try {
      final profileUrl =
      Uri.parse('https://www.parbasante.com/api/worker/$workerId/read/');
      final structUrl = Uri.parse(
          'https://www.parbasante.com/api/worker/$workerId/structures-allowed/');

      final profileRes =
      await http.get(profileUrl, headers: {'Authorization': 'Token $token'});
      final structRes =
      await http.get(structUrl, headers: {'Authorization': 'Token $token'});

      if (profileRes.statusCode == 200 && structRes.statusCode == 200) {
        setState(() {
          _profile = jsonDecode(profileRes.body);
          _structuresAutorisees = jsonDecode(structRes.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error =
          'Erreur de chargement (code ${profileRes.statusCode} / ${structRes.statusCode})';
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

  Widget _buildProfileHeader() {
    final firstName = _profile?['user']?['first_name'] ?? '';
    final lastName = _profile?['user']?['last_name'] ?? '';
    final email = _profile?['user']?['email'] ?? '';
    final initials =
        '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [parbaBlue, parbaLightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: parbaWhite),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Spacer(),
                  Text(
                    'Mon Profil',
                    style: TextStyle(
                      color: parbaWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh, color: parbaWhite),
                    onPressed: fetchProfile,
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: parbaWhite,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: parbaBlue,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                '$firstName $lastName',
                style: TextStyle(
                  color: parbaWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(
                  color: parbaWhite.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: parbaWhite.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _profile?['statut']?['name'] ?? 'Statut non défini',
                  style: TextStyle(
                    color: parbaWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
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
                    color: parbaBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    icon,
                    color: parbaBlue,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(  // ← on contraint le texte
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: parbaTextDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: parbaGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 16,
              color: parbaTextLight,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: parbaTextLight,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'Non renseigné',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color:
                    value.isNotEmpty ? parbaTextDark : parbaTextLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructureCard(Map<String, dynamic> structure) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: parbaGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: parbaGreen.withOpacity(0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: parbaGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.local_hospital,
                color: parbaGreen,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    structure['name'] ?? 'Nom inconnu',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: parbaTextDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (structure['code'] != null) ...[
                    SizedBox(height: 4),
                    Text(
                      'Code : ${structure['code']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: parbaTextLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (structure['adresse'] != null) ...[
                    SizedBox(height: 2),
                    Text(
                      structure['adresse'],
                      style: TextStyle(
                        fontSize: 12,
                        color: parbaTextLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(),
        style: ElevatedButton.styleFrom(
          backgroundColor: parbaBlue,
          foregroundColor: parbaWhite,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 2,
        ),
        icon: Icon(Icons.logout, size: 20),
        label: Text(
          'Se déconnecter',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Dans votre _ProfilePageState :

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Déconnexion',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: parbaTextDark,
            ),
          ),
          content: Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
            style: TextStyle(color: parbaTextLight),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Ferme simplement la boîte de dialogue
                Navigator.of(dialogCtx).pop();
              },
              child: Text(
                'Annuler',
                style: TextStyle(color: parbaTextLight),
              ),
            ),
            TextButton(
              onPressed: () async {
                // 1) Ferme la boîte de dialogue tout de suite
                Navigator.of(dialogCtx).pop();

                // 2) Appel asynchrone au backend (facultatif)
                final token = await AuthService.getToken();
                if (token != null) {
                  await http.post(
                    Uri.parse('https://parbasante.com/account/logout/'),
                    headers: {'Authorization': 'Token $token'},
                  );
                }

                // 3) On efface le token local
                await AuthService.clearToken();

                // 4) On vérifie toujours que le State est monté
                if (!mounted) return;

                // 5) On remplace toute la stack par la page de login
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                      (Route<dynamic> route) => false,
                );
              },
              child: Text(
                'Déconnecter',
                style: TextStyle(
                  color: parbaBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

// Vous pouvez conserver cette méthode pour la réutiliser ailleurs si besoin
  Future<void> logoutAndGoToLogin() async {
    final token = await AuthService.getToken();
    if (token != null) {
      await http.post(
        Uri.parse('https://parbasante.com/account/logout/'),
        headers: {'Authorization': 'Token $token'},
      );
    }
    await AuthService.clearToken();
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: parbaGray,
      body: _isLoading
          ? _buildLoading()
          : _error != null
          ? _buildError()
          : Column(
        children: [
          _buildProfileHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchProfile,
              color: parbaBlue,
              backgroundColor: parbaWhite,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 16),
                    _buildInfoCard(
                      'Informations personnelles',
                      Icons.person,
                      [
                        _buildInfoRow(
                          'Nom',
                          _profile?['user']?['last_name'] ?? '',
                          Icons.person_outline,
                        ),
                        _buildInfoRow(
                          'Prénom',
                          _profile?['user']?['first_name'] ?? '',
                          Icons.person_outline,
                        ),
                        _buildInfoRow(
                          'Email',
                          _profile?['user']?['email'] ?? '',
                          Icons.email_outlined,
                        ),
                        _buildInfoRow(
                          'Téléphone',
                          _profile?['user']?['phone'] ?? '',
                          Icons.phone_outlined,
                        ),
                      ],
                    ),
                    _buildInfoCard(
                      'Informations professionnelles',
                      Icons.work,
                      [
                        _buildInfoRow(
                          'Statut',
                          _profile?['statut']?['name'] ?? '',
                          Icons.badge_outlined,
                        ),
                        _buildInfoRow(
                          'Métier',
                          _profile?['metiers']?['name'] ?? '',
                          Icons.work_outline,
                        ),
                      ],
                    ),
                    _buildInfoCard(
                      'Structures autorisées (${_structuresAutorisees.length})',
                      Icons.local_hospital,
                      _structuresAutorisees.isEmpty
                          ? [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Aucune structure autorisée.',
                            style: TextStyle(
                              color: parbaTextLight,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ]
                          : _structuresAutorisees
                          .map((s) =>
                          _buildStructureCard(s))
                          .toList(),
                    ),
                    SizedBox(height: 16),
                    _buildLogoutButton(),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
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
              'Chargement du profil...',
              style: TextStyle(
                fontSize: 16,
                color: parbaTextLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
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
            ElevatedButton.icon(
              onPressed: fetchProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: parbaBlue,
                foregroundColor: parbaWhite,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 2,
              ),
              icon: Icon(Icons.refresh, size: 18),
              label: Text(
                'Réessayer',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
