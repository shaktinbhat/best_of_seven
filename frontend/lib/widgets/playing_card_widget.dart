import 'package:flutter/material.dart';
import '../models/card_model.dart';

class PlayingCardWidget extends StatelessWidget {
  final CardModel? card;
  final bool isSelected;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const PlayingCardWidget({
    super.key,
    this.card,
    this.isSelected = false,
    this.onTap,
    this.width = 56,
    this.height = 86,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        width: width,
        height: height,
        transform: Matrix4.translationValues(0, isSelected ? -14 : 0, 0),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: card == null ? const Color(0xFF1E1038) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.black.withOpacity(0.15),
            width: isSelected ? 2.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFFFFD700).withOpacity(0.4) : Colors.black.withOpacity(0.35),
              blurRadius: isSelected ? 10 : 4,
              offset: Offset(0, isSelected ? 5 : 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5.5),
          child: IgnorePointer(
            ignoring: true,
            child: card == null ? _buildBack() : _buildFront(),
          ),
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C104D), Color(0xFF140428)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Icon(Icons.shield_outlined, color: Color(0xFFD4AF37), size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildFront() {
    final c = card!;
    final isRed = c.isRed;
    final color = isRed ? const Color(0xFFD92727) : const Color(0xFF181818);
    final bool isCourt = c.rank >= 11 && c.rank <= 13;

    if (c.isPrintedJoker) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('JOKER', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 2),
            // Illustrated Court Jester Face
            Container(
              width: 30,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFDEBD0),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.shade800, width: 1.2),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.theater_comedy, color: Color(0xFF900C3F), size: 18),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red.shade900,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Text('JOKER', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(2.5),
      child: Stack(
        children: [
          // 1. Subtle central watermark for regular & Ace cards
          if (!isCourt)
            Center(
              child: Opacity(
                opacity: 0.12,
                child: Text(
                  c.suitSymbol,
                  style: TextStyle(
                    color: color,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // 2. Top-Left Index (Rank & Suit)
          Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.rankLabel,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    height: 1.0,
                  ),
                ),
                Text(
                  c.suitSymbol,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // 3. Center Court Art (King, Queen, Jack) or Pip
          Center(
            child: isCourt ? _buildIllustratedCourt(c, color) : Text(c.suitSymbol, style: TextStyle(color: color.withOpacity(0.85), fontSize: 20)),
          ),

          // 4. Bottom-Right Inverted Index
          Align(
            alignment: Alignment.bottomRight,
            child: RotatedBox(
              quarterTurns: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.rankLabel,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    c.suitSymbol,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Illustrated King (sword), Queen (sceptre), Jack (staff) matching picture 4
  Widget _buildIllustratedCourt(CardModel c, Color suitColor) {
    final bool isKing = c.rank == 13;
    final bool isQueen = c.rank == 12;

    return Container(
      width: 32,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFBCAAA4), width: 0.8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Crown / Headgear
          Icon(
            isKing ? Icons.workspace_premium : (isQueen ? Icons.auto_awesome : Icons.military_tech),
            size: 13,
            color: const Color(0xFFD4AF37),
          ),
          // Character portrait with regalia
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 22,
                height: 24,
                decoration: BoxDecoration(
                  color: isKing ? const Color(0xFF2C3E50) : (isQueen ? const Color(0xFF6C3483) : const Color(0xFF784212)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Center(
                  child: Text(
                    isKing ? 'K' : (isQueen ? 'Q' : 'J'),
                    style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // Sceptre / Sword indicator on the right
              Positioned(
                right: 0,
                bottom: 0,
                child: Icon(
                  isKing ? Icons.colorize : (isQueen ? Icons.flare : Icons.navigation),
                  size: 9,
                  color: const Color(0xFFFFD700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          // Held Suit Badge
          Text(
            c.suitSymbol,
            style: TextStyle(color: suitColor, fontSize: 8, fontWeight: FontWeight.bold, height: 1.0),
          ),
        ],
      ),
    );
  }
}