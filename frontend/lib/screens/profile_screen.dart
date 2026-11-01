import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../widgets/casino_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserService>();
    _nameController = TextEditingController(text: user.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserService>();

    return Scaffold(
      body: CasinoBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Back Button (Top Left)
              Positioned(
                top: 12,
                left: 12,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Main Modal Box (Matching Picture 3)
              Center(
                child: Container(
                  width: 580,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF220835).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 24,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Edit Profile',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Avatar Column
                          Column(
                            children: [
                              // Avatar with Golden Glow Rim
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD4AF37).withOpacity(0.4),
                                      blurRadius: 10,
                                    )
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 36,
                                  backgroundColor: const Color(0xFF381552),
                                  child: Icon(
                                    _getAvatarIcon(user.avatarIndex),
                                    color: Colors.lightBlueAccent,
                                    size: 40,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // "Random" Button
                              SizedBox(
                                width: 110,
                                height: 34,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: EdgeInsets.zero,
                                  ),
                                  icon: const Icon(Icons.shuffle, size: 16),
                                  label: const Text('Random', style: TextStyle(fontSize: 12)),
                                  onPressed: () => user.randomizeAvatar(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // "Recents" Button
                              SizedBox(
                                width: 110,
                                height: 34,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: EdgeInsets.zero,
                                  ),
                                  icon: const Icon(Icons.history, size: 16),
                                  label: const Text('Recents', style: TextStyle(fontSize: 12)),
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 24),

                          // Right Fields Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Display Name Box
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Display Name', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: _nameController,
                                        maxLength: 15,
                                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          counterStyle: TextStyle(color: Colors.white30, fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Save Changes Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF381552),
                                      side: BorderSide(color: Colors.white.withOpacity(0.15)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () {
                                      user.updateProfile(
                                        newName: _nameController.text,
                                        newAvatarIndex: user.avatarIndex,
                                      );
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Logout Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6E2A12),
                                      side: BorderSide(color: Colors.red.withOpacity(0.3)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () {
                                      user.logout();
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  IconData _getAvatarIcon(int idx) {
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
}