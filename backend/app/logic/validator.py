import itertools
from typing import List, Tuple, Optional
from app.models.card import Card


def is_pure_sequence(cards: List[Card]) -> bool:
    if len(cards) < 3:
        return False
    # No jokers allowed in pure sequence
    if any(c.is_printed_joker for c in cards):
        return False
    # All same suit
    suit = cards[0].suit
    if any(c.suit != suit for c in cards):
        return False

    ranks = [c.rank for c in cards]
    sorted_ranks = sorted(ranks)
    # Check regular consecutive order
    if all(sorted_ranks[i] + 1 == sorted_ranks[i + 1] for i in range(len(sorted_ranks) - 1)):
        return True

    # Check Ace-high sequence (e.g., Q-K-A or J-Q-K-A)
    if 1 in sorted_ranks:
        ace_high = sorted([14 if r == 1 else r for r in ranks])
        if all(ace_high[i] + 1 == ace_high[i + 1] for i in range(len(ace_high) - 1)):
            return True

    return False


def is_impure_sequence(cards: List[Card], wild_joker_rank: Optional[int]) -> bool:
    if len(cards) < 3:
        return False

    naturals = [c for c in cards if not (c.is_printed_joker or (wild_joker_rank and c.rank == wild_joker_rank))]
    jokers_count = len(cards) - len(naturals)

    if not naturals:
        return True  # All jokers

    suit = naturals[0].suit
    if any(c.suit != suit for c in naturals):
        return False

    def can_form(ranks_list):
        ranks = sorted(ranks_list)
        if len(ranks) != len(set(ranks)):
            return False
        gaps = 0
        for i in range(len(ranks) - 1):
            gaps += (ranks[i + 1] - ranks[i] - 1)
        return gaps <= jokers_count

    nat_ranks = [c.rank for c in naturals]
    if can_form(nat_ranks):
        return True
    if 1 in nat_ranks:
        ace_high = [14 if r == 1 else r for r in nat_ranks]
        if can_form(ace_high):
            return True

    return False


def is_valid_set(cards: List[Card], wild_joker_rank: Optional[int], target_len: int = 3) -> bool:
    if len(cards) != target_len:
        return False

    naturals = [c for c in cards if not (c.is_printed_joker or (wild_joker_rank and c.rank == wild_joker_rank))]
    if not naturals:
        return True

    target_rank = naturals[0].rank
    if any(c.rank != target_rank for c in naturals):
        return False

    suits = [c.suit for c in naturals]
    # Distinct suits or identical trio (in 3-deck Rummy)
    if len(suits) == len(set(suits)):
        return True
    if len(set(suits)) == 1:
        return True

    return False


def has_unlocked_wild_joker(hand: List[Card]) -> bool:
    """
    Checks if a player has at least one valid Pure Sequence of 3 or 4 cards
    in their hand to unlock the hidden Wild Joker.
    """
    if len(hand) < 3:
        return False

    for length in (3, 4):
        for combo in itertools.combinations(hand, length):
            if is_pure_sequence(list(combo)):
                return True
    return False


def get_card_points(card: Card, wild_joker_rank: Optional[int]) -> int:
    """Calculates deadwood loss points for unmelded cards."""
    if card.is_printed_joker or (wild_joker_rank and card.rank == wild_joker_rank):
        return 0
    if card.rank == 1 or card.rank >= 10:  # Ace, 10, J, Q, K
        return 10
    return card.rank


def calculate_loss_points(
    groups: List[List[Card]],
    wild_joker_rank: Optional[int],
    deal_number: int = 1,
    is_wrong_show: bool = False,
) -> int:
    """
    Calculates total penalty points:
    - Max penalty is 80 (capped).
    - Deals 1 and 7 are 2X points (max 160).
    """
    is_double_deal = deal_number in (1, 7)

    if is_wrong_show:
        max_penalty = 80
        return max_penalty * 2 if is_double_deal else max_penalty

    # Check if losing player at least has a pure sequence
    flat_cards = [c for g in groups for c in g]
    has_pure = has_unlocked_wild_joker(flat_cards)

    raw_points = 0
    if not has_pure:
        # Full deadwood penalty if no pure sequence
        raw_points = sum(get_card_points(c, wild_joker_rank) for c in flat_cards)
    else:
        # Player has pure sequence: only score cards not in valid sets or sequences
        for g in groups:
            if not (is_pure_sequence(g) or is_impure_sequence(g, wild_joker_rank) or is_valid_set(g, wild_joker_rank, len(g))):
                raw_points += sum(get_card_points(c, wild_joker_rank) for c in g)

    capped_points = min(80, raw_points)
    return capped_points * 2 if is_double_deal else capped_points


def validate_declaration(groups: List[List[Card]], wild_joker_rank: Optional[int]) -> Tuple[bool, str]:
    flat = [c for g in groups for c in g]
    if len(flat) != 13:
        return False, f"Whoops! You need exactly 13 cards to declare, but had {len(flat)}."

    four_card_groups = [g for g in groups if len(g) == 4]
    three_card_groups = [g for g in groups if len(g) == 3]

    if len(four_card_groups) != 1 or len(three_card_groups) != 3:
        return False, "Hand must be grouped into three 3-card melds and one 4-card meld."

    g4 = four_card_groups[0]
    g4_is_pure = is_pure_sequence(g4)
    g4_valid = g4_is_pure or is_impure_sequence(g4, wild_joker_rank) or is_valid_set(g4, wild_joker_rank, 4)

    pure_found = g4_is_pure
    invalid_three_groups = 0

    for g in three_card_groups:
        if is_pure_sequence(g):
            pure_found = True
        elif not (is_impure_sequence(g, wild_joker_rank) or is_valid_set(g, wild_joker_rank, 3)):
            invalid_three_groups += 1

    if not pure_found:
        return False, "No Pure Sequence! You need at least one straight run without any Jokers!"

    if not g4_valid:
        return False, "Your 4-card group doesn't make a complete run or 4-of-a-kind!"

    if invalid_three_groups > 0:
        return False, f"You still have {invalid_three_groups} group(s) with stray cards that don't make a set or sequence!"

    return True, "Boom! Clean Sweep! 🔥 You nailed this deal!"