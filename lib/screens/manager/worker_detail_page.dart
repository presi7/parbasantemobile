import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WorkerDetailPage extends StatefulWidget {
  final int workerId;

  WorkerDetailPage({required this.workerId});

  @override
  _WorkerDetailPageState createState() => _WorkerDetailPageState();
}

class _WorkerDetailPageState extends State<WorkerDetailPage> {
  Map<String, dynamic>? _worker;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchWorkerDetails();
  }

  Future<void> fetchWorkerDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final res = await http.get(
        Uri.parse('https://www.parbasante.com/api/worker/${widget.workerId}/read/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        setState(() {
          _worker = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        throw Exception("Erreur chargement infos du remplaçant.");
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
    final user = _worker?['user'] ?? {};

    return Scaffold(
      appBar: AppBar(title: Text("Détail Remplaçant")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("👤 Nom : ${user['first_name'] ?? ''} ${user['last_name'] ?? ''}", style: TextStyle(fontSize: 18)),
            Text("📞 Téléphone : ${user['phone'] ?? 'Non dispo'}"),
            Text("✉️ Email : ${user['email'] ?? 'Non dispo'}"),
            Text("🏥 Structure : ${_worker?['structure']?['name'] ?? 'N/A'}"),
            Text("👩‍⚕️ Métier : ${_worker?['metiers']?['name'] ?? 'N/A'}"),
            Text("📌 Statut : ${_worker?['statut']?['name'] ?? 'N/A'}"),
            SizedBox(height: 20),
            if (_worker?['cv'] != null)
              ElevatedButton(
                child: Text("📄 Voir CV"),
                onPressed: () {
                  final url = "https://www.parbasante.com${_worker!['cv']}";
                  // Tu peux intégrer url_launcher ici
                },
              )
          ],
        ),
      ),
    );
  }
}
