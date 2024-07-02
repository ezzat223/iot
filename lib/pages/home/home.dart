import 'package:flutter/material.dart';
import 'package:icu/pages/home/widgets/header.dart';
import 'widgets/activity.dart';

class HomePage extends StatelessWidget {
  final String username;
  final String email;

  const HomePage({Key? key, required this.username, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(username: username),
          RecentActivities(doctorEmail: email),
        ],
      ),
    );
  }
}
