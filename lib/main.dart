import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const TapInApp());

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

class LoginScreen extends StatefulWidget {
  final void Function(Map<String, String>) onLogin;
  final FlutterSecureStorage storage;
  const LoginScreen({super.key, required this.onLogin, required this.storage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _password = '';
  bool _isNewAccount = false;

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      await widget.storage.write(key: 'firstName', value: _firstName);
      await widget.storage.write(key: 'lastName', value: _lastName);
      await widget.storage.write(key: 'email', value: _email);
      await widget.storage.write(key: 'password', value: _password);
      widget.onLogin({
        'firstName': _firstName,
        'lastName': _lastName,
        'email': _email,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login / Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SwitchListTile(
                title: const Text('Create new account'),
                value: _isNewAccount,
                onChanged: (val) => setState(() => _isNewAccount = val),
              ),
              if (_isNewAccount) ...[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'First Name'),
                  onSaved: (val) => _firstName = val ?? '',
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  onSaved: (val) => _lastName = val ?? '',
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
              ],
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
                child: Text(_isNewAccount ? 'Sign Up' : 'Login'),
              ),
            ],
          ),
        ),
      ),
    );
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

  static const List<Widget> _pages = <Widget>[
    TapInPage(),
    PlayPage(),
    BookPage(),
    SearchPage(),
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
              children: List.generate(5, (index) {
                final isSelected = _selectedIndex == index;
                final bgColor = isSelected ? Colors.white : const Color(0xFFF8F8F8);
                final icon = [
                  null,
                  Icons.golf_course,
                  Icons.book,
                  Icons.search,
                  Icons.person,
                ][index];
                final label = [
                  'Tap In',
                  'Play',
                  'Book',
                  'Search',
                  'You',
                ][index];
                Widget menuContent = Container(
                  height: 64,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (index == 0) ...[
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            color: isSelected ? const Color(0xFF3F768E) : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Home', style: TextStyle(color: isSelected ? const Color(0xFF3F768E) : Colors.grey, fontSize: 12)),
                      ] else ...[
                        Icon(icon, size: 20, color: isSelected ? const Color(0xFF3F768E) : Colors.grey),
                        const SizedBox(height: 4),
                        Text(label, style: TextStyle(color: isSelected ? const Color(0xFF3F768E) : Colors.grey)),
                      ],
                    ],
                  ),
                );
                menuContent = GestureDetector(
                  onTap: () => _onItemTapped(index),
                  behavior: HitTestBehavior.opaque,
                  child: menuContent,
                );
                if (index == 0 && isSelected) {
                  return Expanded(
                    child: Container(
                      color: Colors.white,
                      child: menuContent,
                    ),
                  );
                } else {
                  return Expanded(
                    child: Container(
                      color: bgColor,
                      child: menuContent,
                    ),
                  );
                }
              }),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Tap In';
      case 1:
        return 'Play';
      case 2:
        return 'Book';
      case 3:
        return 'Search';
      case 4:
        return 'You';
      default:
        return '';
    }
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

class PlayPage extends StatelessWidget {
  const PlayPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(child: Text('Play Page', style: Theme.of(context).textTheme.headlineMedium)),
    );
  }
}

class BookPage extends StatelessWidget {
  const BookPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(child: Text('Book Page', style: Theme.of(context).textTheme.headlineMedium)),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(child: Text('Search Page', style: Theme.of(context).textTheme.headlineMedium)),
    );
  }
}

class YouPage extends StatelessWidget {
  const YouPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(child: Text('You Page', style: Theme.of(context).textTheme.headlineMedium)),
    );
  }
}
