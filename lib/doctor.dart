// ignore_for_file: prefer_const_constructors, deprecated_member_use, use_key_in_widget_constructors, use_build_context_synchronously, avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:icu/pages/signup/login.dart';
import 'package:oscilloscope/oscilloscope.dart';

class Doctor extends StatefulWidget {
  const Doctor({Key? key});

  @override
  State<Doctor> createState() => _DoctorState();
}

class _DoctorState extends State<Doctor> {
  final ref = FirebaseDatabase.instance.ref('sensor');
  final List<double> ldrData = [];
  final List<double> voltageData = [];

  bool isLedOn = false; // Track LED state
  // Track button states
  bool isLedOnButtonActive = false;
  bool isLedOffButtonActive = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();

    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void showNotification() async {
    print("Showing notification"); // Add this line for debugging

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
    );
    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Voltage Alert',
      'VoltageData is more than 3!',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  void setLedState(int state) {
    // Set LED state in the database
    ref.child('LED').set(state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Doctor"),
        ),
        body: SizedBox(
          height: 300,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: StreamBuilder(
                        stream: ref.onValue,
                        builder: (context, snapshot) {
                          if (snapshot.hasData &&
                              snapshot.data!.snapshot.value != null) {
                            var data = snapshot.data!.snapshot.value as Map;
                            var ldrValue = data['ldr_data']?.toDouble();
                            var voltageValue = data['voltage']?.toDouble();

                            if (ldrValue != null && voltageValue != null) {
                              ldrData.add(ldrValue);
                              voltageData.add(voltageValue);

                              // Check if voltageData is more than 3.5 and show notification
                              if (voltageValue > 3) {
                                showNotification();
                              }
                            }

                            return Column(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Oscilloscope(
                                    showYAxis: true,
                                    yAxisColor: Colors.orange,
                                    padding: 20.0,
                                    backgroundColor: Colors.black,
                                    traceColor: Colors.green,
                                    yAxisMax: 4100.0,
                                    yAxisMin: 0.0,
                                    dataSet: ldrData,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text('LDR'),
                                const SizedBox(height: 10),
                                Card(
                                  color: Colors.blue,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                        'Current LDR Data: ${ldrValue.toStringAsFixed(2)}'),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: StreamBuilder(
                        stream: ref.onValue,
                        builder: (context, snapshot) {
                          if (snapshot.hasData &&
                              snapshot.data!.snapshot.value != null) {
                            var data = snapshot.data!.snapshot.value as Map;
                            var ldrValue = data['ldr_data']?.toDouble();
                            var voltageValue = data['voltage']?.toDouble();

                            if (ldrValue != null && voltageValue != null) {
                              ldrData.add(ldrValue);
                              voltageData.add(voltageValue);

                              // Check if voltageData is more than 3.5 and show notification
                              if (voltageValue > 3.5) {
                                showNotification();
                              }
                            }

                            return Column(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Oscilloscope(
                                    showYAxis: true,
                                    yAxisColor: Colors.orange,
                                    padding: 20.0,
                                    backgroundColor: Colors.black,
                                    traceColor: Colors.red,
                                    yAxisMax: 5.0,
                                    yAxisMin: 0.0,
                                    dataSet: voltageData,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text('Voltage'),
                                const SizedBox(height: 10),
                                Card(
                                  color: Colors.blue,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                        'Current Voltage Data: ${voltageValue.toStringAsFixed(2)}'),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLedOn = false;
                    isLedOnButtonActive = false;
                    isLedOffButtonActive = true;
                    setLedState(0);
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      return isLedOffButtonActive
                          ? Colors.red
                          : Colors.red.shade200;
                    },
                  ),
                ),
                child: Text('LED Off'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLedOn = true;
                    isLedOnButtonActive = true;
                    isLedOffButtonActive = false;
                    setLedState(1);
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      return isLedOnButtonActive
                          ? Colors.green
                          : Colors.green.shade200;
                    },
                  ),
                ),
                child: Text('LED On'),
              ),
            ],
          ),
        ));
  }
}

Future<void> logout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => LoginPage(),
    ),
  );
}
