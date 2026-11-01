from enum import Enum
from typing import Optional

class Suit(str, Enum):
    HEARTS = "H"
    DIAMONDS = "D"
    CLUBS = "C"
    SPADES = "S"
    JOKER = "JOKER"

class Card:
    def __init__(self, suit: Suit, rank: int, is_printed_joker: bool = False, uid: Optional[str] = None):
        """
        rank: 1 (Ace) to 13 (King). For printed jokers, rank = 0.
        uid: Unique identifier for each physical card across the 3 decks.
        """
        self.suit = suit
        self.rank = rank
        self.is_printed_joker = is_printed_joker
        self.uid = uid or f"{suit.value}_{rank}"

    def is_wild_joker(self, wild_joker_rank: Optional[int]) -> bool:
        if self.is_printed_joker:
            return True
        if wild_joker_rank is not None and self.rank == wild_joker_rank:
            return True
        return False

    def get_points(self, wild_joker_rank: Optional[int]) -> int:
        if self.is_wild_joker(wild_joker_rank):
            return 0
        if self.rank == 1 or self.rank >= 10:  # Ace, 10, J, Q, K
            return 10
        return self.rank  # 2-9

    def to_dict(self):
        return {
            "uid": self.uid,
            "suit": self.suit.value,
            "rank": self.rank,
            "is_printed_joker": self.is_printed_joker
        }

    def __repr__(self):
        if self.is_printed_joker:
            return "PJOKER"
        names = {1: "A", 11: "J", 12: "Q", 13: "K"}
        val = names.get(self.rank, str(self.rank))
        return f"{val}{self.suit.value}"