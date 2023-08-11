---
layout: post
title: Implementing a simulation of the game Liar's Dice in Python
subtitle: Developing a Python game easily extendable to testing Reinforcement Learning algorithms
tags: projects
---

Here we're going to be going through the steps to implement a simulation of a variant of Liar's Dice called Skull (rules can be found [here](https://www.wikihow.com/Play-Skull-the-Card-Game#Playing-with-Standard-Playing-Cards)). This game can be played with a standard playing card deck and is a game of incomplete information and deception similar to poker. 

The first thing we'll start with are some gameboard types that we'll be needing going forward so we'll start by creating a `skulltypes.py` file:
<div><pre style="border-width:1px; border-style:solid; border-color:#ccc; padding: 0 10px 0 10px;">skulltypes.py</pre>
</div>
```python
import enum
from collections import namedtuple

__all__ = [
    'Player',
]

class GamePhase(enum.Enum):
    placing = 1
    betting = 2
    choice = 3

    #update phase
    @property
    def next(self):
        if self == GamePhase.placing:
            return GamePhase.betting
        elif self == GamePhase.betting:
            return GamePhase.choice
        return None

class Card(enum.Enum):
    skull = 1
    rose = 2
```

Now that we have some basics we can think a bit about the overall structure of our code. The basic idea is to create a deep learning skull module (dlskull) which will store relevant information to the game which we can then call later on when we're interested in either player ourselves or having a bot play the game. 

Next up we'll create a file to represent the game "board" which stores what's in play and the mechanics of the cards which we'll call `skullboard.py`. We'll begin this by creating `class Move()` which stores and encodes move information:

```python
class Move():
    def __init__(self, place=None, bet=None, choice=None, is_pass=False):
        assert (place is not None) ^ (bet is not None) ^ (choice is not None) ^ is_pass
        self.place = place
        self.bet = bet 
        self.choice = choice
        self.is_pass = is_pass
        self.is_choice = (choice is not None)

    @classmethod
    def pass_bet(cls):  
        return Move(is_pass=True)
```

So every turn we have the possibility of making a bet, placing a card, passing, or choosing a card; depending on the phase of the game.

Before we get into the actual game mechanics we notice that both the table and the players have a "collection" of cards so it will be useful to abstract this away into its own data structure which we call ``Chart()``.

```python
class Chart():
    def __init__(self, table=True, default_hand=True, players=None):
        start = []
        if default_hand:
            start = [Card.skull, Card.rose, Card.rose, Card.rose]
        self.ordered = table
        if self.ordered:
            self._chart = {p : [] for p in players}
            self.chart_cards = 0
        else:
            self._chart = {p : start[:] for p in players}
            self.chart_cards = len(start)*len(self._chart)

    #adds a card to "player's" pile
    def add(self, player, card):
        self.chart_cards += 1
        self._chart[player].append(card)

    #removes the top card placed by "player"
    def remove(self, player, value = None):
        if value == None:
            assert self.ordered == True
            self.chart_cards -= 1    
            return self._chart[player].pop()
        else:
            assert self.ordered == False 
            self.chart_cards -= 1
            return self._chart[player].remove(value)

    def get_player(self, player):
        return self._chart[player]

    def get_num_players(self):
        return len(self._chart)

    def get_total_cards(self):
        return self.chart_cards

    def has_card(self, player, card):
        return card in self._chart[player]

    def get_player_cards(self, player):
        return len(self._chart[player])

    def __eq__(self, other):
        return isinstance(other, Chart) and \
            self._chart == other._chart and \
            self.chart_cards == other.chart_cards

    def __str__(self):
        return str(self._chart)
```
Although it looks complicated the ``Chart()`` class is really quite simple - it's just a dictionary mapping players to their cards with a bunch of useful helper functions that make it easier to understand what we're accessing. It's also worth noting that the ``Chart()`` keeps track of how many cards it has and 



The next thing we'll implement is the ```Board()``` class which we'll break down below: 

```python
class Board():  
    def __init__(self, players):
        self._table = Chart(table=True,players=players)
        self._hands = Chart(table=False,players=players)
        self.players_bet = set()
        self.phase = GamePhase.placing
        self._bets = {}
        self.chosen_cards = 0
        self.last_chosen = None
        self.top_bet = (None,-1)

    def get_table(self):
        return self._table
    
    def get_hand(self,player):
        return self._hands.get_player(player)

    def place_card(self, player, card):
        assert self.phase == GamePhase.placing
        assert self._hands.has_card(player, card)
        self._hands.remove(player,card) 
        self._table.add(player, card)

    def place_bet(self, player, bet):
        if self.phase == GamePhase.choice:
            return
        assert bet > self.top_bet[1] or bet == -1 #exceed max bet or pass
        assert not player in self.players_bet
        self.players_bet.add(player)

        self.phase = GamePhase.betting
        self._bets[player] = bet
        if bet > self.top_bet[1]:
            self.top_bet = (player, bet)
        #the maximum value has been bet
        if bet >= self._table.get_total_cards():
            self.phase = self.phase.next
        #everyone has now bet
        elif len(self.players_bet) == self._table.get_num_players():
            self.phase = self.phase.next
        
    def choose_card(self, start_player, dest_player):
        assert self._table.get_player_cards(dest_player) > 0
        assert start_player != dest_player
        card = self._table.remove(dest_player)
        self.chosen_cards += 1
        self.last_chosen = card
        return card

    def all_cards_chosen(self):
        assert self.phase == GamePhase.choice
        return self.chosen_cards == self.top_bet

    def has_card(self, player, card):
        return self._hands.has_card(player, card)

    def __eq__(self, other):
        return isinstance(other, Board) and \
            self._table == other._table and \
            self._hands == other._hands
```
So this seems like a lot but its important to add all the mechanics of the game to the board along with any relevant functions. 


