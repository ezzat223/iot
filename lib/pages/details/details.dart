import 'package:flutter/material.dart';
import 'package:icu/pages/details/widgets/appbar.dart';
import 'package:icu/pages/details/widgets/dates.dart';
import 'package:icu/pages/details/widgets/graph.dart';
import 'package:icu/widgets/bottom_navigation.dart';

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MainAppBar(appBar: AppBar()),
      body: const Column(
        children: [
          Dates(),
          Graph(),
          Divider(height: 100),
          SizedBox(height: 50),
          BottomNavigation(),
        ],
      ),
    );
  }
}