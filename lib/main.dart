import 'dart:ffi';

import 'screens/signin_screen.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/chat_screen.dart';
import 'screens/company_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/favourite_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

final FlutterSecureStorage _storage = FlutterSecureStorage();

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
  bool _isCompanyType = false;
  List<Widget> _pages = [
    HomeScreen(),
    // ExploreScreen(),
    ChatScreen(),
    FavouriteScreen(),
    // CompanyScreen(),
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
    Map<String, String> user = await _storage.readAll();
    String? UserData = user["user_data"];

    if (UserData != null && UserData.isNotEmpty) {
      try {
        Map<String, dynamic> userData = jsonDecode(UserData);
        print("user Data ${userData}");
        if (userData != null && userData["user_type"] == "company") {
          _pages.insert(2, CompanyScreen());
          _isCompanyType = true;
        }
      } catch (e) {
        print("Error decoding user data: $e");
      }
    } else {
      print("No stored user data found");
    }
    setState(() {
      _isLoading = false;
      if (storedToken != null) {
        _isLoggedIn = true;
        print("isLoggedIn = true - token : $storedToken");
        print("userinfo : ${user}");
      } else {
        _isLoggedIn = false;
        print("isLoggedIn = false - token : $storedToken");
        print("userinfo : ${user}");
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
    List<BottomNavigationBarItem> bottomNavItems = [
      BottomNavigationBarItem(
        icon: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Icon(Icons.home, size: 32),
        ),
        label: 'Home',
      ),
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
          child: Icon(Icons.favorite, size: 32),
        ),
        label: 'Favourite',
      ),
      if (_isCompanyType)
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
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: bottomNavItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
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
          height: MediaQuery.of(context)
              .size
              .height, // Set the height to full screen
          child: SigninScreen(), // Use your existing SigninScreen here
        ));
  }
}
