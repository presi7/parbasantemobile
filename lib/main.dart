import 'package:flutter/material.dart';
import 'package:parbasantemobile/screens/admin_main.dart';
import 'package:parbasantemobile/screens/drh/create_structure_page.dart';
import 'package:parbasantemobile/screens/drh/drh_main_page.dart';
import 'package:parbasantemobile/screens/drh/structure_list_page.dart';
import 'package:parbasantemobile/screens/manager/candidates_list_page.dart';
import 'package:parbasantemobile/screens/manager/create_mission_page.dart';
import 'package:parbasantemobile/screens/manager/manager_home_page.dart';
import 'package:parbasantemobile/screens/manager/mission_detail_page_manager.dart';
import 'package:parbasantemobile/screens/manager/profile_manager_page.dart';
import 'package:parbasantemobile/screens/manager/reseau_page.dart';
import 'package:parbasantemobile/screens/register_page.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/profile_page.dart';

void main() {
  runApp(const ParbaSanteApp());
}

class ParbaSanteApp extends StatelessWidget {
  const ParbaSanteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ParBa Santé Mobile',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(),
        '/profile': (context) => ProfilePage(),
        '/manager_home_page': (context) => ManagerHomePage(),
        '/create_mission': (context) => CreateMissionPage(),
        '/profile_manager_page': (context) => ProfileManagerPage(),
        '/reseau_page': (context) => ReseauPage(),
        '/drh_main': (context) => DrhMainPage(),
        '/admin_main': (context) => AdminMainPage(),
        '/create_structure': (context) => CreateStructurePage(),
        '/structure_list_page': (context) => StructureListPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/mission_detail_page_manager') {
          final missionId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (_) => MissionDetailPageManager(missionId: missionId),
          );
        }
        if (settings.name == '/candidates_list_page') {
          final missionId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (_) => CandidatesListPage(missionId: missionId),
          );
        }
        return null;
      },
    );
  }
}
