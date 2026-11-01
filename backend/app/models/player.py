from typing import List
from app.models.card import Card

class Player:
    def __init__(self, player_id: str, name: str, is_host: bool = False):
        self.player_id = player_id
        self.name = name
        self.is_host = is_host
        self.is_ready = False
        self.hand: List[Card] = []
        self.has_drawn = False
        self.total_match_score = 0
        self.deal_scores: List[int] = []

    def check_joker_unlock(self) -> bool:
        """
        Checks if the player has unlocked the wild joker by forming
        at least one pure sequence of 3 or 4 cards.
        """
        from app.logic.validator import has_unlocked_wild_joker
        return has_unlocked_wild_joker(self.hand)