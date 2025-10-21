import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'golf_course_detail_page.dart';

// Placeholder for GolfCourseCache
class GolfCourseCache {
  static Future<List<Map<String, dynamic>>> load(BuildContext context) async {
    // TODO: Replace with actual loading logic
    return [];
  }
}

// Placeholder for TapInPage
class TapInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Tap In Page'));
  }
}

// PlayPage implementation (restored)
class PlayPage extends StatefulWidget {
  final String? userEmail;
  final List<Map<String, dynamic>> golfCourses;
  final bool coursesLoaded;
  const PlayPage({super.key, this.userEmail, this.golfCourses = const [], this.coursesLoaded = false});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _filteredCourses = [];
  List<Map<String, dynamic>> _recentCourses = [];
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _filteredCourses = widget.golfCourses;
    _loadRecentCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCourses = widget.golfCourses
          .where((course) =>
            course['name'] != null &&
            course['name'] is String &&
            (course['name'] as String).toLowerCase().contains(query)
          )
          .toList();
    });
  }

  void _onSearchFocusChanged() {
    setState(() {
      _searchFocused = _searchFocusNode.hasFocus;
    });
  }

  Future<void> _loadRecentCourses() async {
    if (widget.userEmail == null) return;
    final storage = FlutterSecureStorage();
    final key = 'recent_courses_${widget.userEmail}';
    final jsonStr = await storage.read(key: key);
    if (jsonStr != null) {
      final List<dynamic> decoded = json.decode(jsonStr);
      setState(() {
        _recentCourses = decoded.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _saveRecentCourses() async {
    if (widget.userEmail == null) return;
    final storage = FlutterSecureStorage();
    final key = 'recent_courses_${widget.userEmail}';
    await storage.write(key: key, value: json.encode(_recentCourses));
  }

  @override
  Widget build(BuildContext context) {
    final loading = !widget.coursesLoaded;
    return Scaffold(
      backgroundColor: const Color(0xFFEFEDED), // new default bg color
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
                  child: Text(
                    'Play',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ), // headlineMedium
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
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
                ),
                if (!_searchFocused && _recentCourses.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Recent searches',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF919194),
                      ), // headlineSmall
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: _recentCourses.map((course) {
                      final name = course['name'] is String ? course['name'] as String : '';
                      final city = (course['tags'] != null && course['tags']['addr:city'] is String)
                          ? course['tags']['addr:city'] as String
                          : null;
                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          title: Text(
                            name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                            ), // bodyMedium
                          ),
                          subtitle: city != null && city.isNotEmpty
                              ? Text(city, style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  color: const Color(0xFF919194),
                                )) // headlineSmall
                              : null,
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
                                  return Card(
                                    color: Colors.white,
                                    elevation: 1,
                                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    child: ListTile(
                                      title: Text(
                                        name,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12,
                                        ), // bodyMedium
                                      ),
                                      subtitle: city != null && city.isNotEmpty
                                          ? Text(city, style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12,
                                              color: const Color(0xFF919194),
                                            )) // headlineSmall
                                          : null,
                                      onTap: () async {
                                        setState(() {
                                          _recentCourses.removeWhere((c) => c['name'] == course['name']);
                                          _recentCourses.insert(0, course);
                                          if (_recentCourses.length > 5) {
                                            _recentCourses = _recentCourses.sublist(0, 5);
                                          }
                                        });
                                        await _saveRecentCourses();
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => GolfCourseDetailPage(course: course),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ))
                      : const Center(child: Text('Type to search golf courses...')),
                ),
              ],
            ),
    );
  }
}

// UserDetailsPage implementation (restored)
class UserDetailsPage extends StatefulWidget {
  final Map<String, String> userData;
  final FlutterSecureStorage storage;
  final void Function(Map<String, String>) onUpdate;
  const UserDetailsPage({super.key, required this.userData, required this.storage, required this.onUpdate});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _passwordController = TextEditingController();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final email = await widget.storage.read(key: 'email') ?? widget.userData['email'] ?? '';
    final firstName = await widget.storage.read(key: 'firstName') ?? widget.userData['firstName'] ?? '';
    final lastName = await widget.storage.read(key: 'lastName') ?? widget.userData['lastName'] ?? '';
    final password = await widget.storage.read(key: 'password') ?? widget.userData['password'] ?? '';
    setState(() {
      _emailController.text = email;
      _firstNameController.text = firstName;
      _lastNameController.text = lastName;
      _passwordController.text = password;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    final updated = {
      'email': _emailController.text,
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'password': _passwordController.text,
    };
  await widget.storage.write(key: 'email', value: updated['email']);
  await widget.storage.write(key: 'password', value: updated['password']);
  await widget.storage.write(key: 'firstName', value: updated['firstName']);
  await widget.storage.write(key: 'lastName', value: updated['lastName']);
    widget.onUpdate(updated);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEDED), // new default bg color
      appBar: AppBar(
        title: Text('User Details', style: GoogleFonts.inter(
          fontWeight: FontWeight.w900,
          fontSize: 16,
        )), // headlineMedium
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ), // bodyMedium
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ), // bodyMedium
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ), // bodyMedium
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ), // bodyMedium
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveDetails,
              child: Text('Save', style: GoogleFonts.inter(
                fontWeight: FontWeight.w400,
                fontSize: 12,
              )), // bodyMedium
            ),
          ],
        ),
      ),
    );
  }
}

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Login', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter your email' : null,
                  onSaved: (value) => _email = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter your password' : null,
                  onSaved: (value) => _password = value ?? '',
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
      ),
    );
  }
}


void main() => runApp(const TapInApp());

class TapInApp extends StatelessWidget {
  const TapInApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap In',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.openSansTextTheme(Theme.of(context).textTheme),
      ),
      home: const AuthGate(),
    );
  }
}
// (Removed stray code fragments outside of classes)

class HomeScreen extends StatefulWidget {
  final Map<String, String> userData;
  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Map<String, dynamic>> _golfCourses = [];
  bool _coursesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final courses = await GolfCourseCache.load(context);
    if (mounted) {
      setState(() {
        _golfCourses = courses;
        _coursesLoaded = true;
      });
    }
  }

  List<Widget> get _pages => [
    TapInPage(),
    PlayPage(
      userEmail: widget.userData['email'],
      golfCourses: _golfCourses,
      coursesLoaded: _coursesLoaded,
    ),
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
      backgroundColor: const Color(0xFFEFEDED),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) {
                final isSelected = _selectedIndex == index;
                final bgColor = isSelected ? Colors.white : const Color(0xFFF8F8F8);
                final icon = [
                  null, // No icon for Tap In
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
                final homeText = 'Home';
                final activeColor = const Color(0xFF3F768E);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(index),
                    child: Container(
                      color: bgColor,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (index == 0) ...[
                            Text(
                              label,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: isSelected ? activeColor : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              homeText,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                color: isSelected ? activeColor : Colors.grey,
                              ),
                            ),
                          ]
                          else ...[
                            Icon(icon, color: isSelected ? activeColor : Colors.grey),
                            const SizedBox(height: 2),
                            Text(
                              label,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                color: isSelected ? activeColor : Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Container(
            height: 10,
            color: Colors.white,
          ),
        ],
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
                      final storage = FlutterSecureStorage();
                      // Find userData from AuthGate ancestor
                      final authGateState = context.findAncestorStateOfType<_AuthGateState>();
                      final userData = authGateState?._userData ?? {};
                      return Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person, color: Colors.blue),
                              title: const Text('User Details'),
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => UserDetailsPage(
                                      userData: userData,
                                      storage: storage,
                                      onUpdate: (updated) {
                                        authGateState?._userData = updated;
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.logout, color: Colors.red),
                              title: const Text('Logout'),
                              onTap: () async {
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


// (Removed duplicate main and TapInApp definitions)

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoggedIn = false;
  Map<String, String>? _userData;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkSavedLogin();
  }

  Future<void> _checkSavedLogin() async {
    final email = await _storage.read(key: 'email');
    final password = await _storage.read(key: 'password');
    if (email != null && password != null) {
      // You can add real authentication here if needed
      setState(() {
        _isLoggedIn = true;
        _userData = {'email': email, 'firstName': 'User', 'lastName': 'Demo'};
      });
    }
  }

  void _onLogin(Map<String, String> userData) async {
    await _storage.write(key: 'email', value: userData['email']);
    await _storage.write(key: 'password', value: userData['password']);
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


