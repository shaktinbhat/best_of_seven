from app.logic.room import GameRoom
from app.models.card import Card, Suit
from app.logic.validator import is_valid_set, is_pure_set

# Setup room with 2 players
room = GameRoom(room_id="ROOM_001")
room.add_player("P1", "Alice")
room.add_player("P2", "Bob")

# Deal 1 starts (Double points, No Wild Joker)
room.start_deal()
print(f"Deal {room.current_deal} Started. State: {room.game_state}")
print(f"Is Double Points: {room.get_player_view('P1')['is_double_points_deal']}")
print(f"Wild Joker in Deal 1: {room.get_player_view('P1')['wild_joker']}")

# Turn 1: Player draws from stock
p1_id = room.current_player.player_id
drawn = room.draw_card(p1_id, source="STOCK")
print(f"\n{p1_id} drew: {drawn}. Hand count: {len(room.current_player.hand)}")

# Turn 1: Player discards
discarded = room.discard_card(p1_id, card_uid=drawn.uid)
print(f"{p1_id} discarded: {discarded}. Now turn of: {room.current_player.name}")



# 3 copies of 7 of Hearts from 3 different decks
three_7_hearts = [
    Card(Suit.HEARTS, 7, uid="D1_H7"),
    Card(Suit.HEARTS, 7, uid="D2_H7"),
    Card(Suit.HEARTS, 7, uid="D3_H7"),
]

print("Is pure set (7H-7H-7H):", is_pure_set(three_7_hearts))
print("Is valid 3-card set:", is_valid_set(three_7_hearts, wild_joker_rank=None, target_len=3))


# Test 3 Printed Jokers
three_printed_jokers = [
    Card(Suit.JOKER, 0, is_printed_joker=True, uid="D1_PJ1"),
    Card(Suit.JOKER, 0, is_printed_joker=True, uid="D2_PJ1"),
    Card(Suit.JOKER, 0, is_printed_joker=True, uid="D3_PJ1"),
]

print("Is 3 Printed Jokers a Pure Set:", is_pure_set(three_printed_jokers))
print("Is 3 Printed Jokers a Valid Set:", is_valid_set(three_printed_jokers, wild_joker_rank=None, target_len=3))