import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreateManagerPage extends StatefulWidget {
  const CreateManagerPage({Key? key}) : super(key: key);

  @override
  _CreateManagerPageState createState() => _CreateManagerPageState();
}

class _CreateManagerPageState extends State<CreateManagerPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _error;

  final TextEditingController _usernameCtrl    = TextEditingController();
  final TextEditingController _firstNameCtrl   = TextEditingController();
  final TextEditingController _lastNameCtrl    = TextEditingController();
  final TextEditingController _emailCtrl       = TextEditingController();
  final TextEditingController _passwordCtrl    = TextEditingController();
  final TextEditingController _confirmCtrl     = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final url = Uri.parse('https://parbasante.com/account/create-manager/');
    final body = {
      'username':   _usernameCtrl.text.trim(),
      'first_name': _firstNameCtrl.text.trim(),
      'last_name':  _lastNameCtrl.text.trim(),
      'email':      _emailCtrl.text.trim(),
      'password':   _passwordCtrl.text.trim(),
    };

    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode(body),
      );

      setState(() => _isSubmitting = false);

      if (res.statusCode == 201 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Manager créé avec succès !')),
        );
        Navigator.of(context).pop(true);
      } else {
        final msg = res.body.isNotEmpty
            ? jsonDecode(res.body).toString()
            : 'Statut ${res.statusCode}';
        setState(() => _error = 'Erreur API : $msg');
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = 'Erreur réseau : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer un compte Manager'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: TextStyle(color: Colors.red)),
                ),
              TextFormField(
                controller: _usernameCtrl,
                decoration: InputDecoration(labelText: 'Nom d\'utilisateur'),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _firstNameCtrl,
                decoration: InputDecoration(labelText: 'Prénom'),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _lastNameCtrl,
                decoration: InputDecoration(labelText: 'Nom'),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Champ requis';
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  return emailRegex.hasMatch(v.trim())
                      ? null
                      : 'Email invalide';
                },
              ),
              TextFormField(
                controller: _passwordCtrl,
                decoration: InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
                validator: (v) =>
                v == null || v.trim().length < 6
                    ? 'Au moins 6 caractères'
                    : null,
              ),
              TextFormField(
                controller: _confirmCtrl,
                decoration:
                InputDecoration(labelText: 'Confirmer le mot de passe'),
                obscureText: true,
                validator: (v) =>
                v != _passwordCtrl.text ? 'Les mots de passe diffèrent' : null,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text('Créer Manager'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
