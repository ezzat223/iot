import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:oscilloscope/oscilloscope.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:icu/pages/signup/login.dart';

class PatientPage extends StatefulWidget {
  final String username;
  final String watchId;

  const PatientPage({Key? key, required this.username, required this.watchId}) : super(key: key);

  @override
  _PatientPageState createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  List<double> irValueTraceData = [];
  List<double> spo2TraceData = [0]; // Ensure there is an initial value
  Map<String, double> spo2DataMap = {"SpO2": 0}; // Initial SpO2 value
  List<Color> spo2ColorList = [Colors.blue]; // Change SpO2 color to blue
  int globalCurrentHRValue = 0; // Changed to integer for HR value

  late DatabaseReference databaseReference;
  FirebaseAuth auth = FirebaseAuth.instance; // Firebase Auth instance
  String currentUsername = ''; // Variable to hold current user's username

  Timer? _timer; // Timer to periodically generate trace data

  @override
  void initState() {
    super.initState();
    currentUsername = widget.username; // Initialize with passed username
    databaseReference = FirebaseDatabase.instance.ref().child(widget.watchId); // Initialize database reference with watchId
    getCurrentUserInfo(); // Optional: Call this to update username from Firebase

    _timer = Timer.periodic(Duration(milliseconds: 500), _generateTrace);
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  // Function to get current user's information
  void getCurrentUserInfo() {
    User? user = auth.currentUser;
    if (user != null) {
      setState(() {
        currentUsername = user.displayName ?? ''; // Set username if available
      });
    }
  }

  // Function to handle logout
  Future<void> _logout() async {
    await auth.signOut(); // Sign out the user from Firebase
    print('User logged out');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()), 
      (route) => false, // Clear all previous routes
    );
  }

  // Function to generate trace data
  void _generateTrace(Timer t) {
    setState(() {
      // Add logic to update trace data if needed
      // irValueTraceData.add(someValue);
    });
  }

  Widget buildStreamBuilder() {
    return StreamBuilder(
      stream: databaseReference.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          double globalCurrentIRValue = data['irValue'].toDouble();
          double globalCurrentSpo2Value = data['spo2'].toDouble();
          globalCurrentHRValue = data['HR'];

          irValueTraceData.add(globalCurrentIRValue);
          spo2TraceData[0] = globalCurrentSpo2Value;
          spo2DataMap["SpO2"] = globalCurrentSpo2Value;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Oscilloscope(
                    showYAxis: true,
                    yAxisColor: Colors.orange,
                    padding: 20.0,
                    backgroundColor: Colors.black,
                    traceColor: Colors.green,
                    yAxisMax: 3000.0,
                    yAxisMin: 0.0,
                    dataSet: irValueTraceData,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Current IR Value',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '${globalCurrentIRValue.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: PieChart(
                    dataMap: {
                      "SpO2": globalCurrentSpo2Value,
                      "Remaining": 100 - globalCurrentSpo2Value
                    },
                    colorList: [Colors.blue, Colors.grey],
                    chartRadius: MediaQuery.of(context).size.width / 2.7,
                    chartType: ChartType.disc,
                    animationDuration: Duration(milliseconds: 800),
                    chartValuesOptions: ChartValuesOptions(
                      showChartValuesInPercentage: true,
                      showChartValuesOutside: false,
                      decimalPlaces: 1,
                    ),
                    legendOptions: LegendOptions(
                      showLegends: true,
                      legendTextStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                      legendPosition: LegendPosition.right,
                      legendShape: BoxShape.circle,
                      showLegendsInRow: false,
                      legendLabels: {
                        "SpO2": "SpO2",
                      },
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: <Widget>[
                            Text(
                              '$globalCurrentHRValue',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'BPM',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Logout') {
                _logout(); // Call the logout function
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Logout'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal[200]!, Colors.teal[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                widget.username,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Expanded(child: buildStreamBuilder()),
            ],
          ),
        ),
      ),
    );
  }
}
