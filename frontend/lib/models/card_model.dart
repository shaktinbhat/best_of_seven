class CardModel {
  final String uid;
  final String suit; // "H", "D", "C", "S", "JOKER"
  final int rank; // 1 (Ace) to 13 (King), 0 for Printed Joker
  final bool isPrintedJoker;

  CardModel({
    required this.uid,
    required this.suit,
    required this.rank,
    required this.isPrintedJoker,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      uid: json['uid'] as String,
      suit: json['suit'] as String,
      rank: json['rank'] as int,
      isPrintedJoker: json['is_printed_joker'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'suit': suit,
      'rank': rank,
      'is_printed_joker': isPrintedJoker,
    };
  }

  String get rankLabel {
    if (isPrintedJoker) return 'JK';
    switch (rank) {
      case 1:
        return 'A';
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      default:
        return rank.toString();
    }
  }

  String get suitSymbol {
    switch (suit) {
      case 'H':
        return '♥';
      case 'D':
        return '♦';
      case 'C':
        return '♣';
      case 'S':
        return '♠';
      default:
        return '★';
    }
  }

  bool get isRed => suit == 'H' || suit == 'D';
}