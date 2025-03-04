import 'dart:ffi';

import 'screens/signin_screen.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'screens/explore_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/company_screen.dart';
import 'screens/profile_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
    encryptedSharedPreferences: true,
  );
  final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: Colors.orange, canvasColor: Colors.white),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final _storage = FlutterSecureStorage(); // Create storage instance here
  bool _isLoading = true; // Add a loading state
  bool _isLoggedIn = false;

  final List<Widget> _pages = [
    HomeScreen(),
    // ExploreScreen(),
    ChatScreen(),
    CompanyScreen(),
    ProfileScreen(),
    // SigninScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Call a separate async function
  }


  Future<void> _checkLoginStatus() async {
    String? storedToken = await _storage.read(key: 'auth_token');
    setState(() {
      _isLoading = false;
      if(storedToken != null){
        _isLoggedIn = true;
        print("isLoggedIn = true - token : $storedToken");
      }else{
        _isLoggedIn = false;
        print("isLoggedIn = false - token : $storedToken");
      }
    });

    // if (true) {
    if (storedToken == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true, // Allow the sheet to be full screen
          builder: (BuildContext context) {
            return SigninPopup();
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(Icons.home, size: 32),
                ),
                label: 'Home',
              ),
              // BottomNavigationBarItem(
              //   icon: Padding(
              //     padding: EdgeInsets.only(top: 8),
              //     child: Icon(Icons.explore, size: 32),
              //   ),
              //   label: 'Explore',
              // ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(Icons.chat, size: 32),
                ),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(Icons.business, size: 32),
                ),
                label: 'Company',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(Icons.person, size: 32),
                ),
                label: 'Profile',
              ),
              // BottomNavigationBarItem(
              //   icon: Padding(
              //     padding: EdgeInsets.only(top: 8),
              //     child: Icon(Icons.login, size: 32),
              //   ),
              //   label: 'Login',
              // ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.orange,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}

// SigninPopup Widget
class SigninPopup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false, // Prevent back button and gesture
    child: Container(
      height: MediaQuery.of(context).size.height, // Set the height to full screen
      child: SigninScreen(), // Use your existing SigninScreen here
    )
    );
  }
}