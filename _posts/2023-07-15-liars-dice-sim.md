---
layout: post
title: Implementing a simulation of the game Liar's Dice in Python
subtitle: Developing a Python game easily extendable to testing Reinforcement Learning algorithms
tags: projects
---

Here we're going to be going through the steps to implement a simulation of a variant of Liar's Dice called Skull (rules can be found [here](https://www.wikihow.com/Play-Skull-the-Card-Game#Playing-with-Standard-Playing-Cards)). This game can be played with a standard playing card deck and is a game of incomplete information and deception similar to poker. All the code presented here can also been viewed on my [github](https://github.com/gangrel2321/RL_LiarsDice).

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

Next up we'll create a file to represent the game "board" which stores what's in play and the mechanics of the cards which we'll call `skullboard.py`. We'll begin this by creating ``class Move()`` which stores and encodes move information:

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
Although it looks complicated the ``Chart()`` class is really quite simple - it's just a dictionary mapping players to their cards with a bunch of useful helper functions that make it easier to understand what we're accessing. It's also worth noting that the ``Chart()`` keeps track of how many cards it has and can either be ordered (the table) or not (the hands). 

The next thing we'll implement is the ``Board()`` class which we'll break down below: 

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
Again, we've thrown a lot of code at you here but its important to add all the mechanics of the game to the board along with any relevant functions. The first thing that we work through is the ``__init__(self, players)`` noting that when we create a game board we need to know how many / which players are going to be in the game so we can distribute the cards properly. We also need a ``Chart()`` for the hands and the table and some variables to hold other board state information like the game phase and player bets. After this we add the essential functions for modifying game state such as placing bets, placing cards, and choosing cards as well as all the accesor methods we may need. 


Now that we've got the ``Board()`` class filled out we can move on to the ``GameState()``. The ``GameState()`` stores information about the board, the current player, previous game state, and the previous move. The functions in ``GameState()`` are a bit larger so we'll go through them one by one. 

```python
class GameState():
    def __init__(self, board, players, previous, move):
        assert len(players) > 0
        self.board = board
        self.players = players
        self._cur_player_index = 0
        self.previous_state = previous
        self.last_move = move
```

Here we initialized the ``GameState()`` to include the information we listed.


Next we add some getter methods and add a method for creating a new game. 

```python
@classmethod
def new_game(cls, bots):
    board = Board(bots)
    return GameState(board, bots, None, None)

def get_cur_player(self):
    return self.players[self._cur_player_index]

# get player after self.get_cur_player()
def get_next_player(self): # TODO: replace with linked list? 
    if self._cur_player_index < len(self.players):
        self._cur_player_index += 1
    else:
        self._cur_player_index = 0
    return self.players[self._cur_player_index]   
```

Then we can move on to adding some functions for applying a new move to an existing board state and checking to see if the game is over.

```python
def apply_move(self, move):
    next_board = copy.deepcopy(self.board)
    if move.place:
        next_board.place_card(self.get_cur_player(), move.place)
    elif move.bet:
        next_board.place_bet(self.get_cur_player(), move.bet)
    elif move.choice:
        next_board.choose_card(self.get_cur_player(), move.choice)
    elif move.is_pass:
        next_board.place_bet(self.get_cur_player(), -1)

    return GameState(next_board, self.get_next_player(), self, move)

def is_over(self):
    if self.last_move is None:
        return False
    if self.last_move.is_choice and self.board.all_cards_chosen():
        print("%s wins!" % self.get_cur_player())
        return True
    if self.last_move.is_choice and \
        ( (self.board.last_chosen == Card.skull ) or \
        len(self.board.get_table().get_player(self.last_move.choice)) == 0): 
        return True
    return False
```

And finally, we want our potential AI bots to be able to choose the next move so they should be able to determine what all the possible moves are from the current position.

```python
 def is_valid_move(self,move):
    if self.is_over():
        return False
    if move.is_pass and self.board.phase != GamePhase.placing:
        return True
    if move.place is not None:
        return self.board.phase == GamePhase.placing and \
            self.board.has_card(self.get_cur_player(), move.place)               
    if move.bet is not None:
        return (self.board.phase == GamePhase.betting and \
            move.bet > 0 and \
            move.bet <= self.board._table.get_total_cards() and \
            move.bet > self.board.top_bet[1]) or \
            (self.board.phase == GamePhase.placing and \
            move.bet > 0 and \
            self.board._table.get_total_cards() >= len(self.players) and \
            move.bet <= self.board._table.get_total_cards() )
    if move.choice is not None:
        return self.board.phase == GamePhase.choice and \
            self.board.top_bet[0] == self.get_cur_player() and \
            self.get_cur_player() != move.choice and \
            self.board._table.get_player_cards(move.choice) > 0      
    return False

def legal_moves(self):
    moves = []
    #place
    for card_type in Card:
        move = Move(place=card_type)
        if self.is_valid_move(move):
            moves.append(move)
    #bet
    for i in range(1,self.board._table.get_total_cards() + 1):
        move = Move(bet=i)
        if self.is_valid_move(move):
            moves.append(move)
    #pass during betting
    if self.is_valid_move(Move.pass_bet()) and self.board.phase == GamePhase.betting:
        moves.append(Move.pass_bet())
    #choice
    for user in Player:
        move = Move(choice=user)
        if self.is_valid_move(move):
            moves.append(move)
    if DEBUG_MODE:
        print("Possible Moves:", len(moves))
    return moves
```

So there's alot of logic we've added in here but what it really boils down to is applying the rules specific to eat of the three phases of the game: placing, betting, and choice. All we've done is take the Skull rules from the beginning of the article and inserted them into our code. 

Now we're basically done with our code; we have relevant data types and structure, the ability to make a move, and the game rules built in. So, all we need to do now is make a bot to play the game. To do this we'll create a new folder called ``agent`` which will store our different bot types. All the "agents" will have to follow a simple abstract base class so they have some common functionality which we'll create as ``base.py``:

```python
__all__ = [
    'Agent',
]

class Agent:
    def __init__(self):
        pass

    def select_move(self, game_state):
        raise NotImplementedError()
        
    def diagnostics(self):
        return {}
```

At this point we're all done, next step is just to implement some AI bots! Here's an example of this running with a simple bot: 

<img src="/assets/2023-07-15-liars-dice-sim/example.gif" alt="drawing" width="1000"/>




