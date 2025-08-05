// lib/screens/worker/mission_detail_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:parbasantemobile/services/auth_service.dart';

class MissionDetailPage extends StatelessWidget {
  final Map<String, dynamic> mission;

  /// On déclare un constructeur nommé `mission` obligatoire.
  const MissionDetailPage({Key? key, required this.mission}) : super(key: key);

  /// Fonction pour postuler à une mission
  Future<void> postulerAMission(BuildContext context, int missionId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Non authentifié")),
      );
      return;
    }
    try {
      // On récupère d'abord l'ID utilisateur / worker
      final roleRes = await http.get(
        Uri.parse('https://parbasante.com/account/role/'),
        headers: {'Authorization': 'Token $token'},
      );
      final userId = jsonDecode(roleRes.body)['id'];

      final workerRes = await http.get(
        Uri.parse('https://www.parbasante.com/api/worker/$userId/read/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (workerRes.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Impossible de récupérer le worker ID")),
        );
        return;
      }
      final workerId = jsonDecode(workerRes.body)['id'];

      // Puis on poste la candidature
      final url = Uri.parse(
        'https://www.parbasante.com/api/mission/$missionId/apply/worker/$workerId/',
      );
      final response = await http.post(
        url,
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🎉 Candidature envoyée avec succès")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la candidature")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref           = mission['referenceNumber'] ?? '—';
    final replacedFirst = mission['replacedFirstName'] ?? '';
    final replacedLast  = mission['replacedLastName'] ?? '';
    final startDate     = mission['startDate'] ?? 'N/D';
    final finishDate    = mission['finishDate'] ?? 'N/D';
    final startTime     = mission['startTime'] ?? 'N/D';
    final finishTime    = mission['finishTime'] ?? 'N/D';
    final available     = mission['available'] ?? false;
    final assigned      = mission['assigned'] != null;
    final missionId     = mission['id'] as int;

    return Scaffold(
      appBar: AppBar(title: Text('Détail de la mission')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Réf. mission : $ref',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            if (replacedFirst.isNotEmpty || replacedLast.isNotEmpty)
              Text('👤 Remplace : $replacedFirst $replacedLast'),
            SizedBox(height: 12),
            Text('📅 Période : $startDate → $finishDate'),
            Text('🕒 Horaires : $startTime – $finishTime'),
            SizedBox(height: 24),
            if (assigned)
              Text('🔒 Déjà attribuée', style: TextStyle(color: Colors.red))
            else if (available)
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.send),
                  label: Text("Postuler à cette mission"),
                  onPressed: () => postulerAMission(context, missionId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              )
            else
              Text('⛔ Indisponible', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
