import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:parbasantemobile/services/auth_service.dart';

class MissionDetailPage extends StatelessWidget {
  final Map<String, dynamic> mission;

  MissionDetailPage({required this.mission});

  Future<void> postulerAMission(BuildContext context, int missionId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Non authentifié")),
      );
      return;
    }

    try {
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
          SnackBar(content: Text("Impossible de récupérer le Worker ID")),
        );
        return;
      }

      final workerId = jsonDecode(workerRes.body)['id'];

      final url = Uri.parse(
          'https://www.parbasante.com/api/mission/$missionId/apply/worker/$workerId/');

      final response = await http.post(url, headers: {
        'Authorization': 'Token $token',
      });

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
    return Scaffold(
      appBar: AppBar(title: Text('Détail de la mission')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mission['referenceNumber'] ?? 'Mission',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            if (mission['replacedFirstName'] != null)
              Text("👤 Remplace : ${mission['replacedFirstName']} ${mission['replacedLastName']}"),
            Text("📅 Du ${mission['startDate']} au ${mission['finishDate']}"),
            Text("🕒 De ${mission['startTime']} à ${mission['finishTime']}"),
            SizedBox(height: 10),
            if (mission['assigned'] != null)
              Text("🔒 Déjà attribuée", style: TextStyle(color: Colors.red)),
            if (mission['assigned'] == null && mission['available'] == true)
              Text("🟢 Mission disponible", style: TextStyle(color: Colors.green)),
            if (mission['assigned'] == null && mission['available'] == false)
              Text("⛔ Indisponible", style: TextStyle(color: Colors.grey)),
            SizedBox(height: 30),
            if (mission['assigned'] == null && mission['available'] == true)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => postulerAMission(context, mission['id']),
                  icon: Icon(Icons.send),
                  label: Text("Postuler à cette mission"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              )
            else
              Center(
                child: Text(
                  "Vous ne pouvez pas postuler à cette mission.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
