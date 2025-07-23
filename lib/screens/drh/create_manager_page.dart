import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreateManagerPage extends StatefulWidget {
  @override
  _CreateManagerPageState createState() => _CreateManagerPageState();
}

class _CreateManagerPageState extends State<CreateManagerPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _prenom = TextEditingController();
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _telephone = TextEditingController();

  bool _loading = false;
  String? _message;

  Future<void> createManager() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.post(
      Uri.parse('https://www.parbasante.com/api/account/create-manager/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "email": _email.text,
        "password": _password.text,
        "prenom": _prenom.text,
        "nom": _nom.text,
        "telephone": _telephone.text,
      }),
    );

    setState(() => _loading = false);

    if (res.statusCode == 201 || res.statusCode == 200) {
      setState(() => _message = "✅ Manager créé !");
      Navigator.pop(context);
    } else {
      setState(() {
        _message = "❌ Échec : ${jsonDecode(res.body)['detail'] ?? 'Erreur inconnue'}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Créer un manager")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(controller: _prenom, decoration: InputDecoration(labelText: 'Prénom'), validator: (v) => v!.isEmpty ? 'Requis' : null),
            TextFormField(controller: _nom, decoration: InputDecoration(labelText: 'Nom'), validator: (v) => v!.isEmpty ? 'Requis' : null),
            TextFormField(controller: _email, decoration: InputDecoration(labelText: 'Email'), validator: (v) => v!.isEmpty ? 'Requis' : null),
            TextFormField(controller: _telephone, decoration: InputDecoration(labelText: 'Téléphone')),
            TextFormField(controller: _password, decoration: InputDecoration(labelText: 'Mot de passe'), obscureText: true),
            if (_message != null) Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(_message!, style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: _loading ? null : createManager,
              child: _loading ? CircularProgressIndicator(color: Colors.white) : Text("Créer"),
            )
          ]),
        ),
      ),
    );
  }
}
