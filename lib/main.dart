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

/// Secure storage instance for authentication tokens.
final FlutterSecureStorage _storage = FlutterSecureStorage();

/// Main entry point for the Flutter application.
Future<void> main() async {
  /// Android secure storage options.
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
    encryptedSharedPreferences: true,
  );
  final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

/// The root widget of the application.
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

/// The main screen containing bottom navigation.
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

/// The _MainScreenState _MainScreenState _MainScreenState _MainScreenState screen containing bottom navigation.
class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final _storage = FlutterSecureStorage();
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isCompanyType = false;

  /// List of pages shown in the bottom navigation bar.
  List<Widget> _pages = [
    HomeScreen(),
    ChatScreen(),
    FavouriteScreen(),
    ProfileScreen(),
  ];

  /// Handles bottom navigation item selection.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  /// Checks if the user is authenticated and updates UI accordingly.
  Future<void> _checkLoginStatus() async {
    String? storedToken = await _storage.read(key: 'auth_token');
    Map<String, String> user = await _storage.readAll();
    String? UserData = user["user_data"];

    if (UserData != null && UserData.isNotEmpty) {
      try {
        Map<String, dynamic> userData = jsonDecode(UserData);
        if (userData["user_type"] == "company") {
          _pages.insert(2, CompanyScreen());
          _isCompanyType = true;
        }
      } catch (e) {
        print("Error decoding user data: $e");
      }
    }

    setState(() {
      _isLoading = false;
      _isLoggedIn = storedToken != null;
    });

    if (storedToken == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
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
      bottomNavigationBar: BottomNavigationBar(
        items: _buildBottomNavItems(),
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

  /// Builds the bottom navigation bar items dynamically.
  List<BottomNavigationBarItem> _buildBottomNavItems() {
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
          child: Icon(Icons.favorite, size: 32),
        ),
        label: 'Favourite',
      ),
      BottomNavigationBarItem(
        icon: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Icon(Icons.person, size: 32),
        ),
        label: 'Profile',
      ),
    ];
    return bottomNavItems;
  }
}

/// Sign-in popup modal for unauthenticated users.
class SigninPopup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        height: MediaQuery.of(context).size.height,
        child: SigninScreen(),
      ),
    );
  }
}