import 'package:flutter/material.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/halo_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/profile_screen.dart';
import 'features/products/screens/home_screen.dart';
import 'features/products/screens/search_screen.dart';
import 'features/products/screens/stylist_screen.dart';
import 'features/cart/screens/cart_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'halo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A1A),
          surface: Halo.bg,
        ),
        scaffoldBackgroundColor: Halo.bg,
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: FutureBuilder<bool>(
        future: TokenStorage.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Halo.bg,
              body: Center(
                child: CircularProgressIndicator(color: Halo.ink, strokeWidth: 1.5),
              ),
            );
          }
          return snapshot.data == true ? const MainScreen() : const LoginScreen();
        },
      ),
      routes: {
        '/main': (_) => const MainScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _index;

  static const _pages = [
    HomeScreen(),
    SearchScreen(),
    StylistScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _HaloNavBar(
        current: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _HaloNavBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;

  const _HaloNavBar({required this.current, required this.onTap});

  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home, 'Discover'),
    _NavItem(Icons.search, Icons.search, 'Search'),
    _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome, 'For You'),
    _NavItem(Icons.shopping_bag_outlined, Icons.shopping_bag, 'Bag'),
    _NavItem(Icons.person_outline, Icons.person, 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Halo.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == current;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        size: 22,
                        color: selected ? Halo.ink : Halo.inkFaint,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? Halo.ink : Halo.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
