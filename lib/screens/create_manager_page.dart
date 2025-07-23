import 'package:flutter/material.dart';

class CreateManagerPage extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  void createManager() {
    // Ajoute logique d’envoi ici
    print("Créer un manager : ${_nameController.text}, ${_emailController.text}");
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Text("👤 Créer un manager ou DRH", style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 20),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: 'Nom complet'),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(labelText: 'Email'),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: createManager,
          child: Text("Créer le compte"),
        ),
        Divider(height: 40),
        Text("📋 Comptes existants", style: Theme.of(context).textTheme.titleMedium),
        ListTile(
          leading: Icon(Icons.person),
          title: Text("manager1@parba.com"),
          subtitle: Text("Manager"),
          trailing: Icon(Icons.edit),
        ),
        ListTile(
          leading: Icon(Icons.person),
          title: Text("drh1@parba.com"),
          subtitle: Text("DRH"),
          trailing: Icon(Icons.edit),
        ),
      ],
    );
  }
}
