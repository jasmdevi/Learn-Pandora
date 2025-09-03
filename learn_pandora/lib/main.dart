import 'package:flutter/material.dart';
import 'package:learn_pandora/welcome.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Learn Pandora',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // onGenerateRoute: (settings) {
      //   if (settings.name == '/avatarLogin') {
      //     return MaterialPageRoute(
      //   builder: (context) => const AvatarLoginPage(),
      //     );
      //   }
      //   return null;
      // },
      home: const AvatarLoginPage(), // Updated to open AvatarLoginPage
    );
  }
}



// This is now a framework for storing user information
class UserInfo {
  String name;
  String email;

  UserInfo({required this.name, required this.email});
}

class UserStorage {
  final List<UserInfo> _users = [];

  void addUser(UserInfo user) {
    _users.add(user);
  }

  List<UserInfo> getUsers() {
    return List.unmodifiable(_users);
  }
}
