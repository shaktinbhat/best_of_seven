import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../widgets/casino_background.dart';

class LoginScreen extends StatelessWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  void _showGoogleProfileSetupDialog(BuildContext context) {
    final user = context.read<UserService>();
    final emailController = TextEditingController(text: 'player@gmail.com');
    final nameController = TextEditingController(text: 'Benki');
    int selectedAvatar = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF220835),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
            ),
            title: const Row(
              children: [
                Text('G ', style: TextStyle(color: Color(0xFF4285F4), fontSize: 24, fontWeight: FontWeight.w900)),
                Text('Google Profile Setup', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Choose your avatar and set your player identity:',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Avatar Picker Carousel
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (idx) {
                      final isCurrent = selectedAvatar == idx;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedAvatar = idx;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCurrent ? const Color(0xFFD4AF37) : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isCurrent
                                ? [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.5), blurRadius: 8)]
                                : null,
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF381552),
                            child: Icon(_getAvatarIcon(idx), size: 20, color: isCurrent ? Colors.white : Colors.white54),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // Google Email Field
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Google Email',
                      labelStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFD4AF37), size: 18),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Display Name Field
                  TextField(
                    controller: nameController,
                    maxLength: 15,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Player Display Name',
                      labelStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFD4AF37), size: 18),
                      filled: true,
                      fillColor: Colors.black26,
                      counterStyle: const TextStyle(color: Colors.white30, fontSize: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final enteredEmail = emailController.text.trim();
                  final enteredName = nameController.text.trim();
                  if (enteredName.isEmpty) return;

                  user.completeGoogleSignIn(
                    enteredEmail: enteredEmail,
                    enteredName: enteredName,
                    selectedAvatar: selectedAvatar,
                  );
                  Navigator.pop(ctx);
                  onLoginSuccess();
                },
                child: const Text(
                  'Confirm & Play ▶',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

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
    final user = context.read<UserService>();

    return Scaffold(
      body: CasinoBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Side Logo
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFannedCardsLogo(),
                        const SizedBox(height: 20),
                        const Text(
                          'Battle your friends.\nRace to victory.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            letterSpacing: 0.8,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 48),

                  // Right Side Card
                  Container(
                    width: 360,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF220938).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Sign in to play!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Google Sign-In button opens profile creation
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            onPressed: () => _showGoogleProfileSetupDialog(context),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'G',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4285F4)),
                                ),
                                SizedBox(width: 14),
                                Text(
                                  'Continue with Google',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Skip for now (Guest)
                        TextButton(
                          onPressed: () {
                            user.loginAsGuest();
                            onLoginSuccess();
                          },
                          child: const Text(
                            'Skip for now',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFannedCardsLogo() {
    return Column(
      children: [
        SizedBox(
          height: 90,
          width: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: const Offset(-36, 6),
                child: Transform.rotate(
                  angle: -0.22,
                  child: _fannedMiniCard('♦', Colors.red),
                ),
              ),
              Transform.translate(
                offset: const Offset(36, 6),
                child: Transform.rotate(
                  angle: 0.22,
                  child: _fannedMiniCard('♥', Colors.red),
                ),
              ),
              _fannedMiniCard('♣', Colors.black),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'BEST OF 7',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFD92727),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'RUSH',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3.0),
          ),
        ),
      ],
    );
  }

  Widget _fannedMiniCard(String suit, Color color) {
    return Container(
      width: 44,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Center(
        child: Text(suit, style: TextStyle(color: color, fontSize: 24)),
      ),
    );
  }
}