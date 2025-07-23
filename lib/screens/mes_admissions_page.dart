import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parbasantemobile/services/auth_service.dart';

class MesAdmissionsPage extends StatefulWidget {
  @override
  _MesAdmissionsPageState createState() => _MesAdmissionsPageState();
}

class _MesAdmissionsPageState extends State<MesAdmissionsPage> {
  List<dynamic> _structures = [];
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
    fetchStructures();
  }

  Future<void> fetchStructures() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final token = await AuthService.getToken();
    final prefs = await SharedPreferences.getInstance();
    final workerId = prefs.getInt('userId');

    if (token == null || workerId == null) {
      setState(() {
        _error = "Token ou ID manquant.";
        _isLoading = false;
      });
      return;
    }

    try {
      final url = Uri.parse('https://www.parbasante.com/api/worker/$workerId/structures-allowed/');
      final res = await http.get(url, headers: {'Authorization': 'Token $token'});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() {
            _structures = data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Réponse inattendue.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Erreur serveur : ${res.statusCode}';
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

  Widget _buildEmptyState() {
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
              color: parbaGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.local_hospital_outlined,
              size: 60,
              color: parbaGreen,
            ),
          ),
          SizedBox(height: 24),
          Text(
            "Aucune admission",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: parbaTextDark,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            "Vous n'êtes admis dans aucune structure sanitaire pour le moment.",
            style: TextStyle(
              fontSize: 14,
              color: parbaTextLight,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: fetchStructures,
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
              'Actualiser',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructureCard(Map<String, dynamic> structure) {
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
          // Action lors du tap sur la structure
        },
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [parbaGreen, parbaLightGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: parbaGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.local_hospital,
                      color: parbaWhite,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          structure['name'] ?? 'Nom inconnu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: parbaTextDark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: parbaGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Admis',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: parbaGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Informations de la structure
              if (structure['code'] != null) ...[
                _buildInfoRow(
                  Icons.qr_code,
                  'Code',
                  structure['code'],
                ),
                SizedBox(height: 12),
              ],

              if (structure['adresse'] != null) ...[
                _buildInfoRow(
                  Icons.location_on,
                  'Adresse',
                  structure['adresse'],
                ),
                SizedBox(height: 12),
              ],

              if (structure['type'] != null) ...[
                _buildInfoRow(
                  Icons.business,
                  'Type',
                  structure['type'],
                ),
                SizedBox(height: 12),
              ],

              if (structure['telephone'] != null) ...[
                _buildInfoRow(
                  Icons.phone,
                  'Téléphone',
                  structure['telephone'],
                ),
                SizedBox(height: 12),
              ],

              // Actions
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Action pour voir les détails
                      },
                      style:OutlinedButton.styleFrom(
                        foregroundColor: parbaBlue,
                        side: BorderSide(color: parbaBlue),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      icon: Icon(Icons.visibility, size: 18),
                      label: Text(
                        'Voir détails',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: parbaGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Action pour contacter
                      },
                      icon: Icon(
                        Icons.phone,
                        color: parbaGreen,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: parbaBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 16,
            color: parbaBlue,
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
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: parbaTextDark,
                ),
              ),
            ],
          ),
        ),
      ],
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
          "Mes Admissions",
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
            onPressed: fetchStructures,
          ),
        ],
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
                'Chargement des admissions...',
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
              ElevatedButton.icon(
                onPressed: fetchStructures,
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
      )
          : _structures.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: fetchStructures,
        color: parbaBlue,
        backgroundColor: parbaWhite,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: parbaWhite,
              child: Column(
                children: [
                  Text(
                    '${_structures.length} structure${_structures.length > 1 ? 's' : ''} autorisée${_structures.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: parbaTextDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Vous êtes admis dans ces établissements de santé',
                    style: TextStyle(
                      fontSize: 14,
                      color: parbaTextLight,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 16),
                itemCount: _structures.length,
                itemBuilder: (context, index) {
                  final structure = _structures[index];
                  return _buildStructureCard(structure);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}