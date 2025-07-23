import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StructureListPage extends StatefulWidget {
  @override
  _StructureListPageState createState() => _StructureListPageState();
}

class _StructureListPageState extends State<StructureListPage> {
  List structures = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchStructures();
  }

  Future<void> fetchStructures() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final res = await http.get(
        Uri.parse('https://www.parbasante.com/api/structures-list/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        setState(() {
          structures = jsonDecode(res.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Erreur lors du chargement.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Erreur réseau : $e";
        isLoading = false;
      });
    }
  }

  Future<void> validerStructure(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.post(
      Uri.parse('https://www.parbasante.com/api/structure/$id/validate/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200 || res.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Structure validée")),
      );
      fetchStructures(); // refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Échec de la validation")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : ListView.builder(
        itemCount: structures.length,
        itemBuilder: (context, index) {
          final s = structures[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text(s['nom'] ?? 'Structure'),
              subtitle: Text("Adresse : ${s['adresse'] ?? 'NC'}\nCode : ${s['code'] ?? ''}"),
              trailing: s['valide'] == false
                  ? ElevatedButton(
                onPressed: () => validerStructure(s['id']),
                child: Text("Valider"),
              )
                  : Icon(Icons.check, color: Colors.green),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create_structure');
        },
        child: Icon(Icons.add),
        tooltip: "Ajouter une structure",
      ),
    );
  }
}
