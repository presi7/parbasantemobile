import 'package:flutter/material.dart';
import 'package:parbasantemobile/services/auth_service.dart';

class AdminProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("👤 Mon Profil", style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.account_circle, size: 40),
            title: Text("Admin Principal"),
            subtitle: Text("admin@parba.com"),
          ),
          SizedBox(height: 20),
          Text("Rôle : Administrateur", style: TextStyle(color: Colors.grey[700])),
          Text("Accès : complet", style: TextStyle(color: Colors.grey[700])),
          Spacer(),
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                await AuthService.clearToken();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              },
              icon: Icon(Icons.logout),
              label: Text("Se déconnecter"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
