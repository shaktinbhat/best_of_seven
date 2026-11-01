import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/socket_service.dart';
import '../models/card_model.dart';
import '../widgets/casino_background.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/chat_sheet.dart';

class GameScreen extends StatefulWidget {
  final String host;
  final String roomId;
  final String playerId;
  final String playerName;

  const GameScreen({
    super.key,
    required this.host,
    required this.roomId,
    required this.playerId,
    required this.playerName,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String? selectedCardUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socket = context.read<SocketService>();
      socket.connect(
        host: widget.host,
        roomId: widget.roomId,
        playerId: widget.playerId,
        playerName: widget.playerName,
      );

      socket.onDeclareResult = (result) {
        if (!mounted) return;
        _showDeclareOutcomeDialog(result);
      };
    });
  }

  void _onCardTapped(String uid) {
    setState(() {
      if (selectedCardUid == null) {
        selectedCardUid = uid;
      } else if (selectedCardUid == uid) {
        selectedCardUid = null;
      } else {
        // Swap cards on double selection
        final socket = context.read<SocketService>();
        final idx1 = socket.myHand.indexWhere((c) => c.uid == selectedCardUid);
        final idx2 = socket.myHand.indexWhere((c) => c.uid == uid);

        if (idx1 != -1 && idx2 != -1) {
          final temp = socket.myHand[idx1];
          socket.myHand[idx1] = socket.myHand[idx2];
          socket.myHand[idx2] = temp;
          socket.notifyListeners();
        }
        selectedCardUid = null;
      }
    });
  }

  void _autoSortHand(SocketService socket) {
    setState(() {
      socket.myHand.sort((a, b) {
        const suitOrder = {'H': 0, 'S': 1, 'D': 2, 'C': 3, 'JOKER': 4};
        final sA = suitOrder[a.suit] ?? 5;
        final sB = suitOrder[b.suit] ?? 5;
        if (sA != sB) return sA.compareTo(sB);
        return a.rank.compareTo(b.rank);
      });
      selectedCardUid = null;
    });
  }

  void _showScoreboardDialog(SocketService socket) {
    final scoreboard = (socket.gameState?['scoreboard'] as List<dynamic>?) ?? [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E072D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.leaderboard_rounded, color: Color(0xFFD4AF37), size: 24),
            const SizedBox(width: 10),
            const Text(
              'Tournament Scoreboard',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Spacer(),
            Text(
              'Deal ${socket.currentDeal} of 7',
              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF330E4E)),
              dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) => const Color(0xFF160322),
              ),
              columnSpacing: 14,
              horizontalMargin: 8,
              columns: const [
                DataColumn(label: Text('Player', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
                DataColumn(label: Text('D1 (2X)', style: TextStyle(color: Colors.white70, fontSize: 11))),
                DataColumn(label: Text('D2', style: TextStyle(color: Colors.white70, fontSize: 11))),
                DataColumn(label: Text('D3', style: TextStyle(color: Colors.white70, fontSize: 11))),
                DataColumn(label: Text('D4', style: TextStyle(color: Colors.white70, fontSize: 11))),
                DataColumn(label: Text('D5', style: TextStyle(color: Colors.white70, fontSize: 11))),
                DataColumn(label: Text('D6', style: TextStyle(color: Colors.white70, fontSize: 11))),
                DataColumn(label: Text('D7 (2X)', style: TextStyle(color: Colors.white70, fontSize: 11))),
                DataColumn(label: Text('Total', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
              ],
              rows: scoreboard.map((entry) {
                final String name = entry['name'] ?? 'Player';
                final bool isMe = entry['player_id'] == widget.playerId;
                final List<dynamic> dealScores = entry['deal_scores'] ?? [];
                final int totalScore = entry['total_score'] ?? 0;

                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name + (isMe ? ' (You)' : ''),
                            style: TextStyle(
                              color: isMe ? Colors.greenAccent : Colors.white,
                              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Deals 1 to 7 scores
                    for (int d = 0; d < 7; d++)
                      DataCell(
                        Text(
                          d < dealScores.length ? '${dealScores[d]}' : '-',
                          style: TextStyle(
                            color: d < dealScores.length && dealScores[d] == 0
                                ? Colors.greenAccent
                                : Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    // Total match penalty score (Lowest wins in Rummy)
                    DataCell(
                      Text(
                        '$totalScore',
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final socket = context.watch<SocketService>();
    final isMyTurn = socket.currentTurnPlayerId == widget.playerId;
    final wildJoker = socket.wildJokerInfo;
    final bool hasDrawn = socket.gameState?['has_drawn'] ?? false;

    return Scaffold(
      body: RoomChatOverlay(
        child: CasinoBackground(
          child: SafeArea(
            child: Column(
            children: [
              // Top Bar Header
              _buildTopBar(socket),

              // Opponent View
              _buildOpponentSection(socket),

              const Spacer(),

              // Clean Center Table
              _buildCenterTable(socket, wildJoker, isMyTurn, hasDrawn),

              const Spacer(),

              // Turn Status Indicator Pill
              _buildTurnStatusPill(isMyTurn, socket),

              const SizedBox(height: 6),

              // Seamless Hand Ribbon with Quick Sort Icon
              _buildSmoothHandRibbon(socket),

              const SizedBox(height: 8),

              // Bottom Actions: Discard, Declare
              _buildBottomControls(socket, isMyTurn, hasDrawn),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildTopBar(SocketService socket) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.style, color: Color(0xFFD4AF37), size: 18),
          ),
          const SizedBox(width: 8),
          Text(
            'Room ${widget.roomId}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE5A93C), Color(0xFFB87B14)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Deal ${socket.currentDeal} / 7',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          if (socket.isDoubleDeal) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('2X PTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
          const Spacer(),

          // Tournament Scoreboard Button (Replaces Sort)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C1958).withOpacity(0.9),
              side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            icon: const Icon(Icons.leaderboard_rounded, color: Color(0xFFD4AF37), size: 16),
            label: const Text(
              'Scoreboard',
              style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _showScoreboardDialog(socket),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentSection(SocketService socket) {
    final opponents = socket.gameState?['opponents'] as List<dynamic>? ?? [];
    if (opponents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Waiting for opponent...', style: TextStyle(color: Colors.white38, fontSize: 11)),
      );
    }

    final opp = opponents.first;
    final int cardCount = opp['card_count'] ?? 13;
    final String oppName = opp['name'] ?? 'Opponent';
    final String oppShortId = (opp['player_id'] as String? ?? '').split('_').last;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD4AF37), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.35),
                blurRadius: 8,
              )
            ],
          ),
          child: const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF2B0C46),
            child: Icon(Icons.smart_toy_rounded, color: Colors.lightBlueAccent, size: 20),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$oppName ${oppShortId.isNotEmpty ? '#$oppShortId' : ''} • Pts: ${opp['total_score']}',
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),

        // Opponent Face-down Hand Fan
        SizedBox(
          height: 38,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              cardCount.clamp(0, 14),
              (index) => Align(
                widthFactor: 0.35,
                child: Container(
                  width: 26,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1038),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFFD4AF37), width: 0.8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterTable(SocketService socket, Map<String, dynamic>? wildJoker, bool isMyTurn, bool hasDrawn) {
    final canDraw = isMyTurn && !hasDrawn;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stock Pile
        _tablePile(
          label: 'STOCK',
          child: PlayingCardWidget(
            card: null,
            width: 64,
            height: 94,
            onTap: canDraw ? () => socket.drawCard('STOCK') : null,
          ),
        ),

        const SizedBox(width: 28),

        // Discard Pile
        _tablePile(
          label: 'DISCARD',
          child: socket.topDiscard != null
              ? PlayingCardWidget(
                  card: socket.topDiscard,
                  width: 64,
                  height: 94,
                  onTap: canDraw ? () => socket.drawCard('DISCARD') : null,
                )
              : Container(
                  width: 64,
                  height: 94,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Center(
                    child: Text('Empty', style: TextStyle(color: Colors.white30, fontSize: 11)),
                  ),
                ),
        ),

        const SizedBox(width: 28),

        // Wild Joker Pile
        _tablePile(
          label: 'WILD JOKER',
          labelColor: const Color(0xFFFFD700),
          child: _buildWildJokerSlot(wildJoker),
        ),
      ],
    );
  }

  Widget _tablePile({required String label, required Widget child, Color labelColor = Colors.white70}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(color: labelColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _buildWildJokerSlot(Map<String, dynamic>? wildJoker) {
    if (wildJoker == null) {
      return Container(
        width: 64,
        height: 94,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: const Center(
          child: Text('No Wild\nJoker', textAlign: TextAlign.center, style: TextStyle(color: Colors.white30, fontSize: 10)),
        ),
      );
    }

    final bool isVisible = wildJoker['visible'] ?? false;
    if (isVisible && wildJoker['card'] != null) {
      return PlayingCardWidget(
        card: CardModel.fromJson(wildJoker['card']),
        width: 64,
        height: 94,
      );
    }

    return Container(
      width: 64,
      height: 94,
      decoration: BoxDecoration(
        color: const Color(0xFF1E0E38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_rounded, color: Color(0xFFD4AF37), size: 20),
          SizedBox(height: 2),
          Text('SECRET', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTurnStatusPill(bool isMyTurn, SocketService socket) {
    final state = socket.gameState?['game_state'] ?? 'WAITING';

    if (state == 'DEAL_OVER') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4AF37),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 18),
        label: Text('Start Deal ${socket.currentDeal} ▶', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
        onPressed: () => socket.nextDeal(),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isMyTurn ? const Color(0xFFD4AF37) : Colors.black45,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isMyTurn
            ? [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.4), blurRadius: 10)]
            : null,
      ),
      child: Text(
        isMyTurn ? 'YOUR TURN' : "Opponent's Turn",
        style: TextStyle(
          color: isMyTurn ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSmoothHandRibbon(SocketService socket) {
    final hand = socket.myHand;
    if (hand.isEmpty) {
      return const SizedBox(
        height: 110,
        child: Center(child: Text('No cards dealt yet.', style: TextStyle(color: Colors.white38))),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = (screenWidth / 18).clamp(44.0, 56.0);
    final double cardHeight = cardWidth * 1.55;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Direct Auto-Sort Action Icon
        IconButton(
          icon: const Icon(Icons.sort_rounded, color: Color(0xFFD4AF37), size: 22),
          tooltip: 'Sort by Suit and Rank',
          onPressed: () => _autoSortHand(socket),
        ),
        const SizedBox(width: 4),

        // Horizontal Drag Hand Ribbon
        SizedBox(
          height: cardHeight + 18,
          child: Center(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              buildDefaultDragHandles: false,
              itemCount: hand.length,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) {
                    final animVal = Curves.easeOutCubic.transform(animation.value);
                    return Transform.rotate(
                      angle: -0.05 * animVal,
                      child: Transform.scale(
                        scale: 1.08,
                        child: Material(
                          color: Colors.transparent,
                          elevation: 16,
                          shadowColor: const Color(0xFFFFD700).withOpacity(0.4),
                          child: child,
                        ),
                      ),
                    );
                  },
                );
              },
              onReorder: (oldIndex, newIndex) {
                socket.reorderHand(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final card = hand[index];
                final isSelected = card.uid == selectedCardUid;

                return ReorderableDragStartListener(
                  key: ValueKey(card.uid),
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: PlayingCardWidget(
                      card: card,
                      width: cardWidth,
                      height: cardHeight,
                      isSelected: isSelected,
                      onTap: () => _onCardTapped(card.uid),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls(SocketService socket, bool isMyTurn, bool hasDrawn) {
    final canDiscard = isMyTurn && hasDrawn && selectedCardUid != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Discard Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: canDiscard ? const Color(0xFFC62828) : Colors.grey.shade900,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: canDiscard ? 6 : 0,
          ),
          icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 17),
          label: const Text('Discard', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          onPressed: canDiscard
              ? () {
                  socket.discardCard(selectedCardUid!);
                  setState(() {
                    selectedCardUid = null;
                  });
                }
              : null,
        ),
        const SizedBox(width: 16),

        // Declare Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: (isMyTurn && hasDrawn && selectedCardUid != null)
                ? const Color(0xFFD4AF37)
                : Colors.grey.shade900,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: (isMyTurn && hasDrawn && selectedCardUid != null) ? 6 : 0,
          ),
          icon: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 17),
          label: const Text('Declare', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
          onPressed: (isMyTurn && hasDrawn && selectedCardUid != null)
              ? () {
                  final finishCardUid = selectedCardUid!;
                  final remainingUids = socket.myHand
                      .where((c) => c.uid != finishCardUid)
                      .map((c) => c.uid)
                      .toList();

                  socket.declareHand(finishCardUid, [remainingUids]);
                  setState(() {
                    selectedCardUid = null;
                  });
                }
              : null,
        ),
      ],
    );
  }

  void _showDeclareOutcomeDialog(Map<String, dynamic> result) {
    final bool success = result['success'] ?? false;
    final String message = result['message'] ?? '';
    final dealResults = result['deal_results'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E072D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: success ? const Color(0xFF00E676) : const Color(0xFFFF5252),
            width: 2.0,
          ),
        ),
        title: Row(
          children: [
            Text(
              success ? '🎉 Victory Show!' : '💥 Busted! Wrong Show',
              style: TextStyle(
                color: success ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
            ),
            const SizedBox(height: 16),
            if (dealResults != null) ...[
              const Text(
                'Deal Breakdown:',
                style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...dealResults.entries.map((e) {
                final score = e.value['score'];
                final status = e.value['status'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('$status ($score pts)', style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                    ],
                  ),
                );
              }),
            ],
            if (!success && result['penalty'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Penalty Taken: +${result['penalty']} pts',
                style: const TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ]
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final socket = context.read<SocketService>();
              if (socket.gameState?['game_state'] == 'DEAL_OVER') {
                socket.nextDeal();
              }
            },
            child: Text(
              context.read<SocketService>().gameState?['game_state'] == 'DEAL_OVER' ? 'Next Deal ▶' : 'Got it 👍',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}