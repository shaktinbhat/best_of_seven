import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/socket_service.dart';
import 'services/user_service.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/waiting_room_screen.dart';
import 'widgets/casino_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => SocketService()),
      ],
      child: const RummyApp(),
    ),
  );
}

class RummyApp extends StatelessWidget {
  const RummyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Best of 7 Rummy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E072D),
      ),
      home: const RootNavigator(),
    );
  }
}

class RootNavigator extends StatelessWidget {
  const RootNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserService>();
    if (!user.isLoggedIn) {
      return LoginScreen(onLoginSuccess: () {});
    }
    return const HomeScreen();
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static IconData _getAvatarIcon(int idx) {
    const icons = [
      Icons.face_retouching_natural,
      Icons.smart_toy_rounded,
      Icons.military_tech_rounded,
      Icons.workspace_premium_rounded,
      Icons.sports_esports_rounded,
      Icons.auto_awesome,
    ];
    return icons[idx % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserService>();

    return Scaffold(
      body: CasinoBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 14,
                left: 16,
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C104D).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFFD4AF37),
                          child: Icon(_getAvatarIcon(user.avatarIndex), size: 16, color: Colors.black87),
                        ),
                        const SizedBox(width: 8),
                        Text(user.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('BEST OF 7', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFD92727), borderRadius: BorderRadius.circular(4)),
                      child: const Text('RUSH', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3.0)),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMainButton(title: 'Play with Friends', icon: Icons.people_outline, onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayWithFriendsScreen()));
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton({required String title, required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      width: 240,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2C1445).withOpacity(0.9),
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// --- FULL SCREEN MODALS ---

class PlayWithFriendsScreen extends StatelessWidget {
  const PlayWithFriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CasinoBackground(
        child: SafeArea(
          child: Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Center(
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF240B36).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Play with Friends', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF381552),
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                          label: const Text('Create Room', style: TextStyle(color: Colors.white, fontSize: 15)),
                          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CreateRoomScreen())),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF381552),
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.login, color: Colors.white),
                          label: const Text('Join Room', style: TextStyle(color: Colors.white, fontSize: 15)),
                          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const JoinRoomScreen())),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});
  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final ipController = TextEditingController(text: '127.0.0.1');
  String gameMode = '7';
  int maxPlayers = 6;

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserService>();
    return Scaffold(
      body: CasinoBackground(
        child: SafeArea(
          child: Stack(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
              Center(
                child: Container(
                  width: 500,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF240B36).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Create Room', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      TextField(
                        controller: ipController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Server IP',
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF1B0727),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: gameMode,
                        dropdownColor: const Color(0xFF240B36),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Game Mode',
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF1B0727),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: '7', child: Text('7 Deals')),
                          DropdownMenuItem(value: '13', enabled: false, child: Text('13 Deals (Coming soon)', style: TextStyle(color: Colors.white38))),
                        ],
                        onChanged: (val) => setState(() => gameMode = val!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: maxPlayers,
                        dropdownColor: const Color(0xFF240B36),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Max Players',
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF1B0727),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: [2, 3, 4, 5, 6].map((n) => DropdownMenuItem(value: n, child: Text('$n Players'))).toList(),
                        onChanged: (val) => setState(() => maxPlayers = val!),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add_circle, color: Colors.black),
                          label: const Text('Create Room', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                          onPressed: () {
                            final roomId = 'R_${1000 + Random().nextInt(9000)}';
                            final uniqueId = 'P_${DateTime.now().millisecondsSinceEpoch % 100000}';
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WaitingRoomScreen(
                                host: ipController.text.trim(), roomId: roomId, playerId: uniqueId, playerName: user.displayName, isCreator: true)));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});
  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final ipController = TextEditingController(text: '127.0.0.1');
  final roomController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserService>();
    return Scaffold(
      body: CasinoBackground(
        child: SafeArea(
          child: Stack(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
              Center(
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF240B36).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Join Room', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      TextField(
                        controller: ipController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Server IP',
                          filled: true,
                          fillColor: const Color(0xFF1B0727),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: roomController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Enter Room Code',
                          filled: true,
                          fillColor: const Color(0xFF1B0727),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.login, color: Colors.black),
                          label: const Text('Join Room', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                          onPressed: () {
                            if (roomController.text.trim().isEmpty) return;
                            final uniqueId = 'P_${DateTime.now().millisecondsSinceEpoch % 100000}';
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WaitingRoomScreen(
                                host: ipController.text.trim(), roomId: roomController.text.trim(), playerId: uniqueId, playerName: user.displayName, isCreator: false)));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}