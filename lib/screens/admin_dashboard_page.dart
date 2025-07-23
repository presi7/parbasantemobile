import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Text("📊 Tableau de bord", style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard("Remplaçants", 48, Icons.person),
            _buildStatCard("Missions", 120, Icons.assignment),
            _buildStatCard("DRH", 5, Icons.badge),
            _buildStatCard("Managers", 10, Icons.supervisor_account),
          ],
        ),
        SizedBox(height: 30),
        Text("🕒 Activités récentes", style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 10),
        ListTile(leading: Icon(Icons.check), title: Text("12 missions validées")),
        ListTile(leading: Icon(Icons.group), title: Text("3 DRH créés cette semaine")),
        ListTile(leading: Icon(Icons.person_add), title: Text("5 nouveaux remplaçants inscrits")),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon) {
    return Card(
      elevation: 3,
      child: Container(
        width: 150,
        height: 120,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.deepPurple),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            Text("$value", style: TextStyle(fontSize: 18, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
