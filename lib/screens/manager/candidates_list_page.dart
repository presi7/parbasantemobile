import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CandidatesListPage extends StatelessWidget {
  final int missionId;

  CandidatesListPage({required this.missionId});

  Future<List<dynamic>> fetchCandidates(String token) async {
    final res = await http.get(
      Uri.parse('https://www.parbasante.com/api/mission/$missionId/candidates-list/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Erreur de chargement candidats.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Candidats de la mission")),
      body: FutureBuilder(
        future: SharedPreferences.getInstance().then((prefs) {
          final token = prefs.getString('token')!;
          return fetchCandidates(token);
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text("Erreur : ${snapshot.error}"));
          final candidates = snapshot.data as List<dynamic>;
          if (candidates.isEmpty)
            return Center(child: Text("Aucun candidat trouvé."));

          return ListView.builder(
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              final c = candidates[index];
              return Card(
                child: ListTile(
                  title: Text("${c['prenom']} ${c['nom']}"),
                  subtitle: Text("${c['statut']}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
