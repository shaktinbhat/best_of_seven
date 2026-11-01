import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/socket_service.dart';
import '../widgets/casino_background.dart';
import '../widgets/chat_sheet.dart';
import 'game_screen.dart';

class WaitingRoomScreen extends StatefulWidget {
  final String host;
  final String roomId;
  final String playerId;
  final String playerName;
  final bool isCreator;

  const WaitingRoomScreen({
    super.key,
    required this.host,
    required this.roomId,
    required this.playerId,
    required this.playerName,
    required this.isCreator,
  });

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SocketService>().connect(
        host: widget.host,
        roomId: widget.roomId,
        playerId: widget.playerId,
        playerName: widget.playerName,
      );
    });
  }

  void _copyShareableInvite() {
    final inviteText = 'Join my Best of 7 room!\nCode: ${widget.roomId}\nIP: ${widget.host}';
    Clipboard.setData(ClipboardData(text: inviteText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Room Code copied!'), backgroundColor: Color(0xFF2E7D32)),
    );
  }

  void _attemptStart(SocketService socket, bool canStart, int playerCount) {
    if (canStart) {
      socket.startGame();
    } else {
      String reason = playerCount < 2 ? "At least 2 players are required to start." : "All players must click Ready.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reason), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final socket = context.watch<SocketService>();
    final isHost = socket.isMeHost;
    final isReady = socket.isMeReady;
    final canStart = socket.canStart;
    final players = socket.players;

    if (socket.gameState?['game_state'] == 'IN_PROGRESS') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => GameScreen(
              host: widget.host, roomId: widget.roomId, playerId: widget.playerId, playerName: widget.playerName)),
        );
      });
    }

    return Scaffold(
      body: RoomChatOverlay(
        child: CasinoBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // --- TOP HEADER ---
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          socket.disconnect();
                          Navigator.pop(context);
                        },
                      ),
                      Text('Room ${widget.roomId}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      
                      const Spacer(),

                      // Top Right Button (Start Match for Host, Ready for Guest)
                      if (isHost)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canStart ? const Color(0xFF2E7D32) : Colors.grey.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                          label: const Text('Start Match', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          onPressed: () => _attemptStart(socket, canStart, players.length),
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isReady ? const Color(0xFF2E7D32) : const Color(0xFF4A148C),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: Icon(isReady ? Icons.check_circle : Icons.radio_button_unchecked, color: Colors.white, size: 20),
                          label: Text(isReady ? 'Ready' : 'Set Ready', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          onPressed: () => socket.toggleReady(),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // --- TWO COLUMN LAYOUT (Ref: play with friends picture) ---
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT COLUMN: Settings
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              // Room Code Box
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C1445).withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Column(
                                  children: [
                                    const Text('Room Code', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(widget.roomId, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 12),
                                        InkWell(
                                          onTap: _copyShareableInvite,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                                            child: const Icon(Icons.share, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Game Type Box
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C1445).withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: const Column(
                                  children: [
                                    Text('Game Type', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                    SizedBox(height: 8),
                                    Text('7 Deals', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 24),

                        // RIGHT COLUMN: 6 Player Slots Grid
                        Expanded(
                          flex: 3,
                          child: GridView.builder(
                            itemCount: 6, // Show exactly 6 slots
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 3.2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemBuilder: (context, idx) {
                              if (idx < players.length) {
                                // Active Player Slot
                                final p = players[idx];
                                final bool pIsHost = p['is_host'] ?? false;
                                final bool pIsReady = p['is_ready'] ?? false;
                                final String pName = p['name'] ?? 'Player';

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF240B36).withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: pIsReady ? Colors.greenAccent : Colors.white12),
                                  ),
                                  child: Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.white12,
                                        child: Icon(Icons.person, color: Colors.white, size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(pName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                      ),
                                      if (pIsHost)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: const Color(0xFFD4AF37), borderRadius: BorderRadius.circular(4)),
                                          child: const Text('ADMIN', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
                                        )
                                      else if (pIsReady)
                                        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                                    ],
                                  ),
                                );
                              } else {
                                // Empty Waiting Slot
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.person_add_alt, color: Colors.white30, size: 18),
                                      SizedBox(width: 10),
                                      Text('Waiting for player...', style: TextStyle(color: Colors.white30, fontSize: 13)),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
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
}