import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Champs texte
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  final _structureController = TextEditingController();

  // Données dynamiques
  List<dynamic> statuts = [];
  List<dynamic> metiers = [];
  List<dynamic> services = [];
  List<dynamic> structures = [];

  // Sélections
  String? _selectedStatut;
  String? _selectedMetier;
  String? _selectedService;
  String? _selectedStructure;
  bool _isCustomStructure = false;

  // Dispo jour/nuit
  bool jour = false;
  bool nuit = false;

  bool _isSubmitting = false;
  String? _message;

  // Couleurs du thème PARBA
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightBlue = Color(0xFF64B5F6);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color backgroundColor = Color(0xFFF8FAFB);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF37474F);

  @override
  void initState() {
    super.initState();
    fetchDropdownData();
  }

  Future<void> fetchDropdownData() async {
    try {
      final statutsUrl = Uri.parse('https://www.parbasante.com/api/statuts-category-list/');
      final metiersUrl = Uri.parse('https://www.parbasante.com/api/metier-category-list/');
      final servicesUrl = Uri.parse('https://www.parbasante.com/api/services-list/');
      final structuresUrl = Uri.parse('https://www.parbasante.com/api/structures-list/');

      final statutsRes = await http.get(statutsUrl);
      final metiersRes = await http.get(metiersUrl);
      final servicesRes = await http.get(servicesUrl);
      final structuresRes = await http.get(structuresUrl);

      if (statutsRes.statusCode == 200 &&
          metiersRes.statusCode == 200 &&
          servicesRes.statusCode == 200 &&
          structuresRes.statusCode == 200) {
        setState(() {
          statuts = jsonDecode(statutsRes.body);
          metiers = jsonDecode(metiersRes.body);
          services = jsonDecode(servicesRes.body);
          structures = jsonDecode(structuresRes.body);
        });
      } else {
        // On évite un crash en cas de réponse non‑JSON (HTML d’erreur, etc.)
        setState(() {
          _message = "Impossible de charger les listes (code réseau ${statutsRes.statusCode}/${metiersRes.statusCode}/${servicesRes.statusCode}/${structuresRes.statusCode}). Vérifiez votre connexion.";
        });
      }
    } catch (e) {
      // Si la requête échoue (pas d’Internet, certificat, etc.), on évite le crash
      setState(() {
        _message = "Erreur lors du chargement des listes : $e";
      });
    }
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    final body = {
      "prenom": _firstNameController.text.trim(),
      "nom": _lastNameController.text.trim(),
      "username": _emailController.text.trim(),
      "email": _emailController.text.trim(),
      "telephone": _telephoneController.text.trim(),
      "password": _passwordController.text,
      "password_confirmation": _passwordConfirmationController.text,
      "statut": _selectedStatut,
      "metier": _selectedMetier,
      "service": _selectedService,
      "structure": _isCustomStructure
          ? _structureController.text.trim()
          : _selectedStructure,
      "disponibilite_jour": jour,
      "disponibilite_nuit": nuit
    };

    final response = await http.post(
      Uri.parse('https://parbasante.com/account/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    setState(() {
      _isSubmitting = false;
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() => _message = '✅ Inscription réussie. Vous pouvez maintenant vous connecter.');
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      final data = jsonDecode(response.body);
      setState(() {
        _message = data['detail'] ?? '❌ Échec de l\'inscription.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Inscription Remplaçant",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête avec icône
              Container(
                padding: EdgeInsets.all(24),
                margin: EdgeInsets.only(bottom: 32),
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
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryBlue, lightBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        Icons.person_add_alt_1,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Rejoignez PARBA",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Créez votre compte de remplaçant",
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Section Informations personnelles
              _buildSection(
                title: "Informations personnelles",
                icon: Icons.person,
                color: primaryBlue,
                children: [
                  Row(
                    children: [
                      Expanded(child: buildInput("Prénom", _firstNameController, Icons.person_outline)),
                      SizedBox(width: 16),
                      Expanded(child: buildInput("Nom", _lastNameController, Icons.person_outline)),
                    ],
                  ),
                  buildInput("Téléphone", _telephoneController, Icons.phone_outlined),
                  buildInput("Email", _emailController, Icons.email_outlined),
                ],
              ),

              // Section Sécurité
              _buildSection(
                title: "Sécurité",
                icon: Icons.lock,
                color: primaryGreen,
                children: [
                  buildInput("Mot de passe", _passwordController, Icons.lock_outline, obscure: true),
                  buildInput("Confirmation mot de passe", _passwordConfirmationController, Icons.lock_outline, obscure: true),
                ],
              ),

              // Section Profil professionnel
              _buildSection(
                title: "Profil professionnel",
                icon: Icons.work,
                color: primaryBlue,
                children: [
                  buildDropdown("Statut", statuts, _selectedStatut, (val) => setState(() => _selectedStatut = val)),
                  buildDropdown("Métier", metiers, _selectedMetier, (val) => setState(() => _selectedMetier = val)),
                  buildDropdown("Spécialité", services, _selectedService, (val) => setState(() => _selectedService = val)),
                ],
              ),

              // Section Structure
              _buildSection(
                title: "Structure",
                icon: Icons.business,
                color: primaryGreen,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: lightGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _isCustomStructure,
                          onChanged: (val) => setState(() => _isCustomStructure = val!),
                          activeColor: primaryGreen,
                        ),
                        Expanded(
                          child: Text(
                            "Saisir un code structure manuellement",
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  _isCustomStructure
                      ? buildInput("Code structure", _structureController, Icons.business_outlined)
                      : buildDropdown("Structure", structures, _selectedStructure,
                          (val) => setState(() => _selectedStructure = val)),
                ],
              ),

              // Section Disponibilité
              _buildSection(
                title: "Disponibilité",
                icon: Icons.schedule,
                color: primaryBlue,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: lightBlue.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: jour,
                              onChanged: (val) => setState(() => jour = val!),
                              activeColor: primaryBlue,
                            ),
                            Icon(Icons.wb_sunny, color: primaryBlue),
                            SizedBox(width: 8),
                            Text(
                              "Disponible le jour",
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: nuit,
                              onChanged: (val) => setState(() => nuit = val!),
                              activeColor: primaryBlue,
                            ),
                            Icon(Icons.nightlight_round, color: primaryBlue),
                            SizedBox(width: 8),
                            Text(
                              "Disponible la nuit",
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32),

              // Message d'erreur ou succès
              if (_message != null)
                Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _message!.contains('✅') ? primaryGreen.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _message!.contains('✅') ? primaryGreen : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.contains('✅') ? primaryGreen : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Bouton d'inscription
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, lightBlue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Inscription en cours...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                      : Text(
                    "Finaliser l'inscription",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(24),
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
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget buildInput(String label, TextEditingController controller, IconData icon, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: primaryBlue),
          filled: true,
          fillColor: backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
      ),
    );
  }

  Widget buildDropdown(String label, List items, String? selected, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          value: selected,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
            prefixIcon: Icon(Icons.arrow_drop_down, color: primaryBlue),
            filled: true,
            fillColor: backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: items
              .map<DropdownMenuItem<String>>((item) => DropdownMenuItem(
            value: item['id'].toString(),
            child: Text(
              item['nom'] ?? item['name'] ?? '...',
              style: TextStyle(color: textColor),
            ),
          ))
              .toList(),
          onChanged: onChanged,
          validator: (val) => val == null ? 'Champ requis' : null,
        ),
      ),
    );
  }
}