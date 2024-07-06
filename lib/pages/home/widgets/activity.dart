import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:icu/pages/patient/patient.dart';

class RecentActivities extends StatelessWidget {
  final String doctorEmail;
  final _formKey = GlobalKey<FormState>(); // Define the _formKey here

  RecentActivities({Key? key, required this.doctorEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        child: Column(
          children: [
            Text(
              'Patients',
              style: Theme.of(context).textTheme.headline6?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'Patient')
                    .where('doctorEmail', isEqualTo: doctorEmail)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  List<Patient> patients = snapshot.data!.docs.map((doc) {
                    return Patient(
                      uid: doc.id, // Use the UID as the document ID
                      username: doc['username'],
                      email: doc['email'],
                      password: '********', // Masked password for security
                      watchId: doc['watch_id'] ?? '', // Retrieve watch_id if available
                    );
                  }).toList();

                  return ListView.builder(
                    itemCount: patients.length,
                    itemBuilder: (context, index) => ActivityItem(
                      patient: patients[index],
                      onDelete: () {
                        _showDeleteConfirmation(context, patients[index]);
                      },
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientPage(
                              username: patients[index].username,
                              watchId: patients[index].watchId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _showAddPatientDialog(context); // Pass context here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              child: const Text('Add Patient', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Patient patient) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete ${patient.username}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deletePatient(context, patient);
                Navigator.of(context).pop(); // Close the dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deletePatient(BuildContext context, Patient patient) {
    FirebaseFirestore.instance.collection('users').doc(patient.uid).delete(); // Use UID here
  }

  void _showAddPatientDialog(BuildContext context) {
    TextEditingController usernameController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    TextEditingController watchIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Patient'),
          content: Form(
            key: _formKey, // Use the _formKey for validation
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Username cannot be empty";
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Email cannot be empty";
                    }
                    if (!RegExp("^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+.[a-z]").hasMatch(value)) {
                      return "Please enter a valid email";
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Password cannot be empty";
                    }
                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                  obscureText: true,
                ),
                TextFormField(
                  controller: watchIdController,
                  decoration: const InputDecoration(labelText: 'Watch ID'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Watch ID cannot be empty";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String username = usernameController.text.trim();
                String email = emailController.text.trim();
                String password = passwordController.text.trim();
                String watchId = watchIdController.text.trim();

                if (_formKey.currentState!.validate()) {
                  _addPatient(username, email, password, watchId);
                  Navigator.of(context).pop(); // Close the dialog
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addPatient(String username, String email, String password, String watchId) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'username': username,
          'email': email,
          'role': 'Patient',
          'doctorEmail': doctorEmail, // Set the doctorEmail field
          'watch_id': watchId, // Set the watch_id field
        });
      }
    } catch (e) {
      print('Error creating user: $e');
    }
  }
}

class ActivityItem extends StatelessWidget {
  final Patient patient;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const ActivityItem({
    Key? key,
    required this.patient,
    required this.onDelete,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xffe1e1e1),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xffcff2ff),
              ),
              height: 35,
              width: 35,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/dental.jpg'),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Text(
              patient.username,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Expanded(child: SizedBox()),
            ElevatedButton(
              onPressed: onDelete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              child: const Icon(Icons.delete),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}

class Patient {
  final String uid; // Use UID instead of username
  final String username;
  final String email;
  final String password;
  final String watchId; // Include watchId field

  Patient({
    required this.uid,
    required this.username,
    required this.email,
    required this.password,
    required this.watchId,
  });
}
