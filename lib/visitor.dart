// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'login.dart';

class Visitor extends StatefulWidget {
  const Visitor({super.key});

  @override
  State<Visitor> createState() => _VisitorState();
}

class _VisitorState extends State<Visitor> {
  RawDatagramSocket? sock;
  List<int> datastream = [];
  Uint8List jpgData = Uint8List(0);
  bool startOfImage = false;
  bool hasNewImage = false;

  @override
  void initState() {
    super.initState();
    initSocket();
  }

  Future<void> initSocket() async {
    try {
      sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8000);
      print('Socket bound to ${sock!.address.address}:${sock!.port}');
    } catch (e) {
      print('Error binding socket: $e');
      return;
    }

    await for (RawSocketEvent event in sock!) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = sock!.receive();
        if (datagram != null) {
          List<int> data = datagram.data;

          if (data.length >= 3 &&
              data[0] == 255 &&
              data[1] == 216 &&
              data[2] == 255) {
            startOfImage = true;
            datastream = List.from(data);
          } else if (startOfImage) {
            datastream.addAll(data);

            if (data.length >= 2 &&
                data[data.length - 2] == 255 &&
                data[data.length - 1] == 217) {
              try {
                Uint8List newJpgData = Uint8List.fromList(datastream);

                if (!Uint8ListEquality().equals(newJpgData, jpgData)) {
                  hasNewImage = true;
                  jpgData = newJpgData;
                }

                startOfImage = false;
                datastream.clear();
              } catch (e) {
                print('Error converting to JPEG: $e');
                startOfImage = false;
                datastream.clear();
              }
            }

            if (hasNewImage) {
              hasNewImage = false;
              setState(() {});
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    sock?.close();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Visitor"),
        actions: [
          IconButton(
            onPressed: () {
              _logout(context);
            },
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text("Display your video widget here"),
      ),
    );
  }
}

class Uint8ListEquality {
  bool equals(Uint8List firstList, Uint8List secondList) {
    if (firstList.length != secondList.length) {
      return false;
    }
    for (int i = 0; i < firstList.length; i++) {
      if (firstList[i] != secondList[i]) {
        return false;
      }
    }
    return true;
  }
}
