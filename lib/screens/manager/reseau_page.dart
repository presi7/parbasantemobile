import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'worker_detail_page.dart';

class ReseauPage extends StatefulWidget {
  @override
  _ReseauPageState createState() => _ReseauPageState();
}

class _ReseauPageState extends State<ReseauPage> {
  List<dynamic> _workers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchWorkers();
  }

  Future<void> fetchWorkers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final res = await http.get(
        Uri.parse('https://www.parbasante.com/api/workers-list/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        setState(() {
          _workers = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        throw Exception("Erreur chargement réseau.");
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
      appBar: AppBar(title: Text("Réseau")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView.builder(
        itemCount: _workers.length,
        itemBuilder: (context, index) {
          final worker = _workers[index];
          final user = worker['user'] ?? {};
          return Card(
            child: ListTile(
              title: Text("${user['first_name'] ?? 'null'} ${user['last_name'] ?? 'null'}"),
              subtitle: Text("${worker['metiers']?['name'] ?? 'null'} | ${user['phone'] ?? 'null'}"),
              trailing: IconButton(
                icon: Icon(Icons.info_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkerDetailPage(workerId: user['id']),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
