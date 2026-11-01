from typing import List, Dict, Optional
from app.models.player import Player
from app.models.card import Card
from .deck import DeckManager
from .validator import validate_declaration, calculate_loss_points

class GameRoom:
    def __init__(self, room_id: str):
        self.room_id = room_id
        self.players: List[Player] = []
        self.game_state = "WAITING"
        self.current_deal = 0
        self.deck_mgr: Optional[DeckManager] = None
        self.current_player_index = 0
        self.countdown_seconds = 0

    @property
    def current_player(self) -> Optional[Player]:
        if not self.players or self.current_player_index >= len(self.players):
            return None
        return self.players[self.current_player_index]

    def add_or_reconnect_player(self, player_id: str, name: str) -> None:
        """
        Adds a player to the room lobby, or handles reconnecting an existing player.
        The first player joining is automatically designated as host.
        """
        existing = next((p for p in self.players if p.player_id == player_id), None)
        if existing:
            existing.name = name
            return

        is_first = len(self.players) == 0
        new_player = Player(
            player_id=player_id,
            name=name,
            is_host=is_first,
        )
        if is_first:
            new_player.is_ready = True
            
        self.players.append(new_player)

    def toggle_ready(self, player_id: str) -> None:
        p = next((p for p in self.players if p.player_id == player_id), None)
        if p and not p.is_host:
            p.is_ready = not p.is_ready

    def can_start(self) -> bool:
        """
        Game can start if there are at least 2 players and
        all non-host players are ready.
        """
        if len(self.players) < 2:
            return False
        # The host is inherently ready; only check other players
        non_hosts = [p for p in self.players if not p.is_host]
        return len(non_hosts) > 0 and all(p.is_ready for p in non_hosts)

    def start_game(self) -> None:
        """
        Starts the 7-deal match, resets all tournament scores, 
        and triggers the first deal.
        """
        if not self.can_start():
            return
            
        self.game_state = "IN_PROGRESS"
        self.current_deal = 0
        
        # Reset all player match scores for a fresh tournament
        for p in self.players:
            p.total_match_score = 0
            p.deal_scores = []
            
        # Initiate the first deal
        self.next_deal()

    def next_deal(self) -> None:
        if self.current_deal >= 7:
            self.game_state = "MATCH_OVER"
            return
            
        self.current_deal += 1
        self.game_state = "IN_PROGRESS"
        
        # Initialize deck with current deal number
        self.deck_mgr = DeckManager(self.current_deal) 
        self.deck_mgr.setup_new_deal()
        
        # Clear hands, deal 13 cards, and reset draw state
        for p in self.players:
            p.hand = self.deck_mgr.deal_hand(13)
            p.has_drawn = False
            
        self.current_player_index = 0

    def draw_card(self, player_id: str, source: str) -> None:
        p = self.current_player
        if not p or p.player_id != player_id:
            raise ValueError("Not your turn.")
        if p.has_drawn:
            raise ValueError("Already drawn a card this turn.")
        
        if source == "STOCK":
            card = self.deck_mgr.draw()
        elif source == "DISCARD":
            card = self.deck_mgr.draw_discard()
        else:
            raise ValueError("Invalid draw source.")
        
        p.hand.append(card)
        p.has_drawn = True

    def discard_card(self, player_id: str, card_uid: str) -> None:
        p = self.current_player
        if not p or p.player_id != player_id:
            raise ValueError("Not your turn.")
        if not p.has_drawn:
            raise ValueError("Must draw a card before discarding.")
            
        card = next((c for c in p.hand if c.uid == card_uid), None)
        if not card:
            raise ValueError("Card not found in hand.")
            
        p.hand.remove(card)
        self.deck_mgr.discard(card)
        p.has_drawn = False
        
        # Advance Turn
        self.current_player_index = (self.current_player_index + 1) % len(self.players)

    def declare(self, player_id: str, finish_card_uid: str, groups_uids: List[List[str]]) -> dict:
        p = self.current_player
        if not p or p.player_id != player_id:
            raise ValueError("Not your turn.")
        if not p.has_drawn:
            raise ValueError("Must draw before declaring.")

        finish_card = next((c for c in p.hand if c.uid == finish_card_uid), None)
        if not finish_card:
            raise ValueError("Finish card not found in hand.")

        # Temporarily remove the finish card to evaluate the remaining 13
        p.hand.remove(finish_card)
        self.deck_mgr.discard(finish_card)

        hand_lookup = {c.uid: c for c in p.hand}
        flat_cards = [hand_lookup[uid] for group in groups_uids for uid in group if uid in hand_lookup]

        # Check all possible 4-group configurations [4,3,3,3], [3,4,3,3], [3,3,4,3], [3,3,3,4]
        candidate_splits = [
            [flat_cards[0:4], flat_cards[4:7], flat_cards[7:10], flat_cards[10:13]],
            [flat_cards[0:3], flat_cards[3:7], flat_cards[7:10], flat_cards[10:13]],
            [flat_cards[0:3], flat_cards[3:6], flat_cards[6:10], flat_cards[10:13]],
            [flat_cards[0:3], flat_cards[3:6], flat_cards[6:9], flat_cards[9:13]],
        ]

        is_valid = False
        reason = "Invalid arrangement."

        for groups in candidate_splits:
            valid, msg = validate_declaration(groups, self.deck_mgr.wild_joker_rank)
            if valid:
                is_valid = True
                reason = msg
                break
            else:
                reason = msg

        results = {}
        if is_valid:
            p.deal_scores.append(0)
            results[p.name] = {"score": 0, "status": "WINNER 🏆"}
            
            for other in self.players:
                if other.player_id != p.player_id:
                    loss_pts = calculate_loss_points([other.hand], self.deck_mgr.wild_joker_rank, deal_number=self.current_deal)
                    other.total_match_score += loss_pts
                    other.deal_scores.append(loss_pts)
                    results[other.name] = {"score": loss_pts, "status": "WIPED OUT 💀"}
                    
            self._conclude_deal()
            return {
                "success": True,
                "message": "💥 Boom! Clean Sweep! You ran the table!",
                "deal_results": results,
            }
        else:
            wrong_show_pts = calculate_loss_points([], None, deal_number=self.current_deal, is_wrong_show=True)
            p.total_match_score += wrong_show_pts
            p.deal_scores.append(wrong_show_pts)
            results[p.name] = {"score": wrong_show_pts, "status": "BUSTED 🚨"}
            
            for other in self.players:
                if other.player_id != p.player_id:
                    other.deal_scores.append(0)
                    results[other.name] = {"score": 0, "status": "SAFE 🛡️"}
                    
            self._conclude_deal()
            return {
                "success": False,
                "message": f"Ouch! Busted! 🙈 {reason}",
                "penalty": wrong_show_pts,
                "deal_results": results,
            }

    def _conclude_deal(self) -> None:
        self.game_state = "DEAL_OVER"
        if self.current_deal >= 7:
            self.game_state = "MATCH_OVER"

    def get_player_view(self, player_id: str) -> dict:
        player = next((p for p in self.players if p.player_id == player_id), None)
        if not player:
            return {}

        # Handle joker visibility status depending on game state
        is_wild_unlocked = player.check_joker_unlock() if self.game_state == "IN_PROGRESS" else False
        wild_joker_info = None
        
        if self.game_state == "IN_PROGRESS" and 2 <= self.current_deal <= 6 and self.deck_mgr and self.deck_mgr.wild_joker_card:
            if is_wild_unlocked:
                wild_joker_info = {
                    "card": self.deck_mgr.wild_joker_card.to_dict(),
                    "rank": self.deck_mgr.wild_joker_rank,
                    "visible": True
                }
            else:
                wild_joker_info = {
                    "card": None,
                    "rank": None,
                    "visible": False,
                    "hint": "Form a Pure Sequence to reveal"
                }

        # Compile full deal-by-deal scoreboard matrix for all 7 deals
        scoreboard = []
        for p in self.players:
            scoreboard.append({
                "player_id": p.player_id,
                "name": p.name,
                "deal_scores": p.deal_scores,
                "total_score": p.total_match_score,
                "is_host": p.is_host,
            })

        return {
            "room_id": self.room_id,
            "deal_number": self.current_deal,
            "is_double_points_deal": self.current_deal in (1, 7),
            "game_state": self.game_state,
            "countdown_seconds": self.countdown_seconds,
            "can_start": self.can_start(),
            "current_turn_player_id": self.current_player.player_id if self.game_state == "IN_PROGRESS" and self.current_player else None,
            "top_discard": self.deck_mgr.discard_pile[-1].to_dict() if self.deck_mgr and self.deck_mgr.discard_pile else None,
            "wild_joker": wild_joker_info,
            "my_hand": [c.to_dict() for c in player.hand],
            "has_drawn": player.has_drawn,
            "is_me_host": player.is_host,
            "is_me_ready": player.is_ready,
            "scoreboard": scoreboard,
            "players": [
                {
                    "player_id": p.player_id,
                    "name": p.name,
                    "is_host": p.is_host,
                    "is_ready": p.is_ready,
                    "card_count": len(p.hand),
                    "total_score": p.total_match_score,
                }
                for p in self.players
            ],
            "opponents": [
                {
                    "player_id": p.player_id,
                    "name": p.name,
                    "card_count": len(p.hand),
                    "total_score": p.total_match_score,
                }
                for p in self.players if p.player_id != player_id
            ],
        }