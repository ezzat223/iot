import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppHeader extends StatefulWidget {
  final String username;

  const AppHeader({Key? key, required this.username}) : super(key: key);

  @override
  _AppHeaderState createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  late String _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _profileImageUrl = '';
    _loadProfileImage();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: Stack(
        children: [
          CustomPaint(
            painter: HeaderPainter(),
            size: const Size(double.infinity, 200),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: IconButton(
              onPressed: () {
                _showMenu(context);
              },
              icon: const Icon(
                Icons.menu,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            top: 35,
            right: 40,
            child: GestureDetector(
              onTap: () async {
                await _pickAndUploadImage();
              },
              child: CircleAvatar(
                minRadius: 25,
                maxRadius: 25,
                backgroundImage: _profileImageUrl.isNotEmpty
                    ? NetworkImage(_profileImageUrl)
                    : null,
              ),
            ),
          ),
          Positioned(
            left: 33,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hello',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Dr. ${widget.username}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  _performLogout(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _performLogout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _pickAndUploadImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      final File imageFile = File(pickedImage.path);
      final String fileName = 'profile_image.png';

      try {
        final user = FirebaseAuth.instance.currentUser;
        final String userEmail = user!.email!;
        final Reference userDirectory = FirebaseStorage.instance.ref().child('$userEmail/');

        // Delete the previous image if it exists
        final ListResult result = await userDirectory.listAll();
        for (final Reference ref in result.items) {
          await ref.delete();
        }

        await userDirectory.child(fileName).putFile(imageFile);

        final String url = await userDirectory.child(fileName).getDownloadURL();
        setState(() {
          _profileImageUrl = url;
        });

        print('Profile image uploaded successfully: $url');
      } catch (e) {
        print('Error uploading profile image: $e');
      }
    } else {
      print('No image selected.');
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final String userEmail = user!.email!;
      final Reference userDirectory = FirebaseStorage.instance.ref().child('$userEmail/');
      final String fileName = 'profile_image.png';
      final String url = await userDirectory.child(fileName).getDownloadURL();
      setState(() {
        _profileImageUrl = url;
      });

      print('Profile image loaded successfully: $url');
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }
}

class HeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint backColor = Paint()..color = const Color(0xff18b0e8);
    Paint circles = Paint()..color = Colors.white.withAlpha(40);

    canvas.drawRect(
      Rect.fromPoints(
        const Offset(0, 0),
        Offset(size.width, size.height),
      ),
      backColor,
    );

    canvas.drawCircle(Offset(size.width * 0.65, 10), 30, circles);
    canvas.drawCircle(Offset(size.width * 0.60, 130), 10, circles);
    canvas.drawCircle(Offset(size.width - 10, size.height - 10), 20, circles);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
