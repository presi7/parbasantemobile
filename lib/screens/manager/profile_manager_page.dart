import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileManagerPage extends StatefulWidget {
  @override
  _ProfileManagerPageState createState() => _ProfileManagerPageState();
}

class _ProfileManagerPageState extends State<ProfileManagerPage> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final roleRes = await http.get(
        Uri.parse('https://parbasante.com/account/role/'),
        headers: {'Authorization': 'Token $token'},
      );

      final id = jsonDecode(roleRes.body)['id'];

      final res = await http.get(
        Uri.parse('https://www.parbasante.com/api/manager/$id/read/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        setState(() {
          _profile = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        throw Exception("Erreur lecture profil.");
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur : $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profil Manager")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nom : ${_profile?['nom'] ?? ''}"),
            Text("Prénom : ${_profile?['prenom'] ?? ''}"),
            Text("Email : ${_profile?['email'] ?? ''}"),
            Text("Téléphone : ${_profile?['telephone'] ?? ''}"),
          ],
        ),
      ),
    );
  }
}
