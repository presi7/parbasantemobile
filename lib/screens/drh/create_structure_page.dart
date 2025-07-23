import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreateStructurePage extends StatefulWidget {
  @override
  _CreateStructurePageState createState() => _CreateStructurePageState();
}

class _CreateStructurePageState extends State<CreateStructurePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _adresse = TextEditingController();
  final TextEditingController _code = TextEditingController();

  bool isSubmitting = false;
  String? message;

  Future<void> submitStructure() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.post(
      Uri.parse('https://www.parbasante.com/api/structure/create/'), // à confirmer
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "nom": _nom.text,
        "adresse": _adresse.text,
        "code": _code.text,
      }),
    );

    setState(() => isSubmitting = false);

    if (res.statusCode == 200 || res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Structure créée !")));
      Navigator.pop(context);
    } else {
      final err = jsonDecode(res.body);
      setState(() {
        message = err['detail'] ?? "Erreur lors de la création.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nouvelle structure")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _nom,
              decoration: InputDecoration(labelText: "Nom de la structure"),
              validator: (v) => v!.isEmpty ? "Requis" : null,
            ),
            TextFormField(
              controller: _adresse,
              decoration: InputDecoration(labelText: "Adresse"),
              validator: (v) => v!.isEmpty ? "Requis" : null,
            ),
            TextFormField(
              controller: _code,
              decoration: InputDecoration(labelText: "Code unique"),
              validator: (v) => v!.isEmpty ? "Requis" : null,
            ),
            if (message != null) Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(message!, style: TextStyle(color: Colors.red)),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSubmitting ? null : submitStructure,
              child: isSubmitting
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Créer la structure"),
            )
          ]),
        ),
      ),
    );
  }
}
