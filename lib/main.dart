import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'golf_course_detail_page.dart';

class LoginScreen extends StatefulWidget {
  final void Function(Map<String, String>) onLogin;
  final FlutterSecureStorage storage;
  const LoginScreen({super.key, required this.onLogin, required this.storage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      await widget.storage.write(key: 'email', value: _email);
      await widget.storage.write(key: 'password', value: _password);
      widget.onLogin({'email': _email, 'firstName': 'User', 'lastName': 'Demo'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                onSaved: (val) => _email = val ?? '',
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (val) => _password = val ?? '',
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GolfCourseCache {
  static List<Map<String, dynamic>>? _golfCourses;
  static Future<List<Map<String, dynamic>>> load(BuildContext context) async {
    if (_golfCourses != null) return _golfCourses!;
    final String data = await DefaultAssetBundle.of(context).loadString('assets/golf_courses_sweden.json');
    final Map<String, dynamic> jsonData = json.decode(data);
    _golfCourses = List<Map<String, dynamic>>.from(jsonData['golf_courses']);
    return _golfCourses!;
  }
}

class TapInApp extends StatelessWidget {
  const TapInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap In',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          bodyMedium: GoogleFonts.inter(
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
            fontSize: 12,
          ),
          headlineMedium: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
          labelSmall: GoogleFonts.inter(
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: const Color(0xFF919194),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _storage = const FlutterSecureStorage();
  bool _isLoggedIn = false;
  Map<String, String>? _userData;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final email = await _storage.read(key: 'email');
    final firstName = await _storage.read(key: 'firstName');
    final lastName = await _storage.read(key: 'lastName');
    final password = await _storage.read(key: 'password');
    if (email != null && firstName != null && lastName != null && password != null) {
      setState(() {
        _isLoggedIn = true;
        _userData = {
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
        };
      });
    }
  }

  void _onLogin(Map<String, String> userData) {
    setState(() {
      _isLoggedIn = true;
      _userData = userData;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn && _userData != null) {
      return HomeScreen(userData: _userData!);
    } else {
      return LoginScreen(onLogin: _onLogin, storage: _storage);
    }
  }
}

class HomeScreen extends StatefulWidget {
  final Map<String, String> userData;
  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
    TapInPage(),
    PlayPage(userEmail: widget.userData['email']),
    BookPage(),
    YouPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) {
                final isSelected = _selectedIndex == index;
                final bgColor = isSelected ? Colors.white : const Color(0xFFF8F8F8);
                final icon = [
                  Icons.home,
                  Icons.golf_course,
                  Icons.book,
                  Icons.person,
                ][index];
                final label = [
                  'Tap In',
                  'Play',
                  'Book',
                  'You',
                ][index];
                Widget menuContent = Container(
                  height: 64,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20, color: isSelected ? const Color(0xFF3F768E) : Colors.grey),
                      const SizedBox(height: 4),
                      Text(label, style: TextStyle(color: isSelected ? const Color(0xFF3F768E) : Colors.grey)),
                    ],
                  ),
                );
                menuContent = GestureDetector(
                  onTap: () => _onItemTapped(index),
                  behavior: HitTestBehavior.opaque,
                  child: menuContent,
                );
                return Expanded(
                  child: Container(
                    color: bgColor,
                    child: menuContent,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class TapInPage extends StatelessWidget {
  const TapInPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(child: Text('Tap In Home Page', style: Theme.of(context).textTheme.headlineMedium)),
    );
  }
}

class PlayPage extends StatefulWidget {
  final String? userEmail;
  const PlayPage({super.key, this.userEmail});
  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  List<Map<String, dynamic>> _recentCourses = [];
  final _storage = const FlutterSecureStorage();
  final FocusNode _searchFocusNode = FocusNode();
  bool _searchFocused = false;
  @override
  void initState() {
    super.initState();
    // Attach listeners immediately for instant focus
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      if (_searchFocused != _searchFocusNode.hasFocus) {
        setState(() {
          _searchFocused = _searchFocusNode.hasFocus;
        });
      }
    });
    // Load data in the background, do not block UI
    Future.microtask(() async {
      final courses = await GolfCourseCache.load(context);
      if (mounted) {
        setState(() {
          _golfCourses = courses;
          _loading = false;
        });
      }
    });
    Future.microtask(_loadRecentCourses);
  }

  Future<void> _loadRecentCourses() async {
    if (widget.userEmail == null) return;
    final jsonString = await _storage.read(key: 'recent_courses_${widget.userEmail}');
    if (jsonString != null) {
      final List<dynamic> decoded = json.decode(jsonString);
      if (mounted) {
        setState(() {
          _recentCourses = decoded.cast<Map<String, dynamic>>();
        });
      }
    }
  }

  Future<void> _saveRecentCourses() async {
    if (widget.userEmail == null) return;
    final jsonString = json.encode(_recentCourses);
    await _storage.write(key: 'recent_courses_${widget.userEmail}', value: jsonString);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool isValidLatLon(dynamic lat, dynamic lon) {
    return lat is num && lon is num && !lat.isNaN && !lon.isNaN;
  }
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _golfCourses = [];
  List<Map<String, dynamic>> _filteredCourses = [];
  bool _loading = true;


  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCourses = _golfCourses
          .where((course) =>
            course['name'] != null &&
            course['name'] is String &&
            (course['name'] as String).toLowerCase().contains(query)
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Search golf courses...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(32)),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                    if (!_searchFocused) ...[
                      const SizedBox(height: 16),
                      if (_recentCourses.isNotEmpty) ...[
                        Text('Recent searches', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Column(
                          children: _recentCourses.map((course) {
                            final name = course['name'] is String ? course['name'] as String : '';
                            final city = (course['tags'] != null && course['tags']['addr:city'] is String)
                                ? course['tags']['addr:city'] as String
                                : null;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(name),
                                subtitle: city != null && city.isNotEmpty ? Text(city) : null,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => GolfCourseDetailPage(course: course),
                                    ),
                                  );
                                  setState(() {
                                    _recentCourses.removeWhere((c) => c['name'] == course['name']);
                                    _recentCourses.insert(0, course);
                                    if (_recentCourses.length > 5) {
                                      _recentCourses = _recentCourses.sublist(0, 5);
                                    }
                                  });
                                  await _saveRecentCourses();
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                    Expanded(
                      child: _searchController.text.isNotEmpty
                          ? (_filteredCourses.isEmpty
                              ? const Center(child: Text('No results found'))
                              : Scrollbar(
                                  thumbVisibility: true,
                                  child: ListView.builder(
                                    itemCount: _filteredCourses.length,
                                    itemBuilder: (context, index) {
                                      final course = _filteredCourses[index];
                                      final name = course['name'] is String ? course['name'] as String : '';
                                      final city = (course['tags'] != null && course['tags']['addr:city'] is String)
                                          ? course['tags']['addr:city'] as String
                                          : null;
                                      return ListTile(
                                        title: Text(name),
                                        subtitle: city != null && city.isNotEmpty ? Text(city) : null,
                                        onTap: () async {
                                          setState(() {
                                            _recentCourses.removeWhere((c) => c['name'] == course['name']);
                                            _recentCourses.insert(0, course);
                                            if (_recentCourses.length > 5) {
                                              _recentCourses = _recentCourses.sublist(0, 5);
                                            }
                                          });
                                          await _saveRecentCourses();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => GolfCourseDetailPage(course: course),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ))
                          : const Center(child: Text('Type to search golf courses...')),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class BookPage extends StatelessWidget {
  const BookPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: SafeArea(
        child: Center(
          child: Text('Book Page', style: Theme.of(context).textTheme.headlineMedium),
        ),
      ),
    );
  }
}

class YouPage extends StatelessWidget {
  const YouPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Text('You Page', style: Theme.of(context).textTheme.headlineMedium),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.settings, size: 28, color: Colors.black),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.logout, color: Colors.red),
                              title: const Text('Logout'),
                              onTap: () async {
                                const storage = FlutterSecureStorage();
                                await storage.deleteAll();
                                Navigator.of(context).pop();
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (context) => const AuthGate()),
                                  (route) => false,
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() => runApp(const TapInApp());


