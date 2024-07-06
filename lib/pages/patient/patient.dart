import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oscilloscope/oscilloscope.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:icu/pages/signup/login.dart';

class PatientPage extends StatefulWidget {
  final String username;
  final String watchId;

  const PatientPage({Key? key, required this.username, required this.watchId})
      : super(key: key);

  @override
  _PatientPageState createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  List<double> irValueTraceData = [];
  List<double> spo2TraceData = [0];
  Map<String, double> spo2DataMap = {"SpO2": 0};
  List<Color> spo2ColorList = [Colors.blue];
  int globalCurrentHRValue = 0;

  late DatabaseReference databaseReference;
  FirebaseAuth auth = FirebaseAuth.instance;
  String currentUsername = '';
  String? profileImageUrl; // URL to the profile image

  Timer? _timer;
  final ImagePicker _picker = ImagePicker(); // Image picker instance

  @override
  void initState() {
    super.initState();
    currentUsername = widget.username;
    databaseReference = FirebaseDatabase.instance.ref().child(widget.watchId);
    getCurrentUserInfo();

    _timer = Timer.periodic(Duration(milliseconds: 500), _generateTrace);

    _loadProfileImage(); // Load profile image on init
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void getCurrentUserInfo() {
    User? user = auth.currentUser;
    if (user != null) {
      setState(() {
        currentUsername = user.displayName ?? '';
      });
    }
  }

  Future<void> _logout() async {
    await auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  void _generateTrace(Timer t) {
    setState(() {
      // Update trace data
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
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '${globalCurrentIRValue.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: PieChart(
                    dataMap: {
                      "SpO2": globalCurrentSpo2Value,
                      "": 100 - globalCurrentSpo2Value
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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      await _uploadImage(imageFile);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      final storageReference = FirebaseStorage.instance
          .ref()
          .child(widget.username)
          .child('profile.jpg');

      // Check for existing images and delete them
      final listResult = await storageReference.listAll();
      for (var item in listResult.items) {
        await item.delete();
      }

      // Upload the new image
      await storageReference.putFile(imageFile);

      // Retrieve the download URL
      final downloadUrl = await storageReference.getDownloadURL();

      setState(() {
        profileImageUrl = downloadUrl;
      });
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final storageReference = FirebaseStorage.instance
          .ref()
          .child(widget.username)
          .child('profile.jpg');

      // Fetch the download URL for the profile image
      final downloadUrl = await storageReference.getDownloadURL();

      setState(() {
        profileImageUrl = downloadUrl;
      });
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Logout') {
                _logout();
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
              Row(
                // Use Row instead of Column for "Welcome" and username
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
                  SizedBox(
                      width:
                          10), // Add some space between "Welcome" and the username
                  Text(
                    widget.username,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: profileImageUrl != null
                    ? CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(profileImageUrl!),
                      )
                    : CircleAvatar(
                        radius: 30,
                        child: Icon(
                          Icons.person,
                          size: 30,
                        ),
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
