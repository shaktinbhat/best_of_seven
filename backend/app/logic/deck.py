import random
import uuid
from typing import List, Optional
from app.models.card import Card

class DeckManager:
    def __init__(self, deal_number: int = 1):
        self.deal_number = deal_number
        self.stock_pile: List[Card] = []
        self.discard_pile: List[Card] = []
        self.wild_joker_card: Optional[Card] = None
        self.wild_joker_rank: Optional[int] = None

    def setup_new_deal(self) -> None:
        """
        Sets up 3 decks (156 suited cards + 6 printed jokers = 162 total cards),
        shuffles, extracts a wild joker card, and puts the first card onto the discard pile.
        """
        self.stock_pile.clear()
        self.discard_pile.clear()

        suits = ['H', 'S', 'D', 'C']
        
        # 3 standard decks
        for _ in range(3):
            for suit in suits:
                for rank in range(1, 14):
                    self.stock_pile.append(
                        Card(
                            uid=str(uuid.uuid4())[:8],
                            suit=suit,
                            rank=rank,
                            is_printed_joker=False,
                        )
                    )
            # 2 printed jokers per deck
            for _ in range(2):
                self.stock_pile.append(
                    Card(
                        uid=str(uuid.uuid4())[:8],
                        suit='JOKER',
                        rank=0,
                        is_printed_joker=True,
                    )
                )

        random.shuffle(self.stock_pile)

        # Select wild joker (must be a standard suited card)
        for i, card in enumerate(self.stock_pile):
            if not card.is_printed_joker:
                self.wild_joker_card = self.stock_pile.pop(i)
                self.wild_joker_rank = self.wild_joker_card.rank
                break

        # Flip the first valid card to form the discard pile
        for i, card in enumerate(self.stock_pile):
            if not card.is_printed_joker:
                self.discard_pile.append(self.stock_pile.pop(i))
                break

    def deal_hand(self, count: int = 13) -> List[Card]:
        hand = []
        for _ in range(count):
            if self.stock_pile:
                hand.append(self.stock_pile.pop())
        return hand

    def draw(self) -> Card:
        if not self.stock_pile:
            self._reshuffle_discard()
        return self.stock_pile.pop()

    def draw_discard(self) -> Card:
        if not self.discard_pile:
            raise ValueError("Discard pile is empty.")
        return self.discard_pile.pop()

    def discard(self, card: Card) -> None:
        self.discard_pile.append(card)

    def _reshuffle_discard(self) -> None:
        if len(self.discard_pile) <= 1:
            raise ValueError("Not enough cards to reshuffle.")
        top_card = self.discard_pile.pop()
        self.stock_pile = self.discard_pile
        self.discard_pile = [top_card]
        random.shuffle(self.stock_pile)