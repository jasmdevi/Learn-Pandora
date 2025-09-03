import 'package:flutter/material.dart';

void main() {
    runApp(AvatarApp());
}

class AvatarApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Avatar Login',
            theme: ThemeData(
                primarySwatch: Colors.blue,
            ),
            home: LoginPage(),
        );
    }
}

class LoginPage extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: Colors.blue.shade900,
            body: Center(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text(
                                'Welcome to Pandora',
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.cyanAccent,
                                ),
                            ),
                            SizedBox(height: 20),
                            TextField(
                                decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: 'Username',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                    ),
                                ),
                            ),
                            SizedBox(height: 20),
                            TextField(
                                obscureText: true,
                                decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: 'Password',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                    ),
                                ),
                            ),
                            SizedBox(height: 30),
                            ElevatedButton(
                                onPressed: () {
                                    // Handle login logic here
                                },
                                style: ElevatedButton.styleFrom(
                                    primary: Colors.cyanAccent,
                                    onPrimary: Colors.blue.shade900,
                                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                    ),
                                ),
                                child: Text(
                                    'Login',
                                    style: TextStyle(fontSize: 18),
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}

