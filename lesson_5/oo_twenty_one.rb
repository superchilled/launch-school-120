# oo_twenty_one.rb

module Screen
  def self.clear
    system('clear') || system('cls')
  end
end

module Hand
  HIGHEST_SCORE = 21

  def show_cards
    cards = []
    hand.each { |card| cards << "#{card.card_symbol}#{card.suit_symbol}" }
    cards.join("  ")
  end

  def show_score
    calculate_score
  end

  def calculate_score
    score = 0
    hand.each { |card| score += card.points }
    score = reduce_aces(score) if score > HIGHEST_SCORE && ace_count > 0
    score
  end

  def ace_count
    ace_count = 0
    hand.each { |card| ace_count += 1 if card.card_symbol == "A" }
    ace_count
  end

  def reduce_aces(score)
    aces = ace_count
    while score > HIGHEST_SCORE && aces > 0
      score -= 10
      aces -= 1
    end
    score
  end
end

class Participant
  PARTICIPANT_OPTIONS = { 'h' => 'Hit', 's' => 'Stick' }.freeze

  include Hand

  attr_accessor :hand, :type

  def initialize(type)
    @hand = []
    @type = type
  end

  def busted?
    calculate_score > HIGHEST_SCORE
  end
end

class Player < Participant
  def choose
    hit_or_stick = ""
    loop do
      puts "Hit or Stick? (type H or S)"
      hit_or_stick = gets.chomp
      break unless !valid_choice?(hit_or_stick.downcase)
      puts "Sorry, that's not a valid choice"
    end
    hit_or_stick
  end

  def valid_choice?(choice)
    PARTICIPANT_OPTIONS.key?(choice)
  end
end

class House < Participant
  HOUSE_STICK_SCORE = 17

  attr_accessor :turn

  def initialize(type)
    @turn = false
    super
  end

  def choose
    calculate_score >= HOUSE_STICK_SCORE ? "s" : "h"
  end

  def show_score
    turn ? calculate_score : "??"
  end

  def show_cards
    cards = []
    hand.each { |card| cards << "#{card.card_symbol}#{card.suit_symbol}" }
    cards[0].replace('??') unless turn
    cards.join("  ")
  end
end

module Dealer
  def deal(deck, participant)
    card = deck.shift
    participant.hand << card
  end

  def announce_choice(choice, player_type)
    if choice == 'h'
      puts "#{player_type} chose to hit"
    else
      puts "#{player_type} chose to stick"
    end
  end

  def announce_bust(player_type)
    puts "#{player_type} busted!"
  end
end

class Deck
  SUITS = [
    { name: "Spades", symbol: "\u2660" },
    { name: "Hearts", symbol: "\u2665" },
    { name: "Clubs", symbol: "\u2663" },
    { name: "Diamonds", symbol: "\u2666" }
  ].freeze

  CARDS = [
    { name: "Two", symbol: "2", points: 2 },
    { name: "Three", symbol: "3", points: 3 },
    { name: "Four", symbol: "4", points: 4 },
    { name: "Five", symbol: "5", points: 5 },
    { name: "Six", symbol: "6", points: 6 },
    { name: "Seven", symbol: "7", points: 7 },
    { name: "Eight", symbol: "8", points: 8 },
    { name: "Nine", symbol: "9", points: 9 },
    { name: "Ten", symbol: "10", points: 10 },
    { name: "Jack", symbol: "J", points: 10 },
    { name: "Queen", symbol: "Q", points: 10 },
    { name: "King", symbol: "K", points: 10 },
    { name: "Ace", symbol: "A", points: 11 }
  ].freeze

  attr_reader :cards

  def initialize
    @cards = SUITS.product(CARDS).map { |card| Card.new(*card) }
  end

  def shuffle
    @deck.shuffle
  end
end

class Card
  def initialize(suit, value)
    @suit = suit
    @value = value
  end

  def card_symbol
    @value[:symbol]
  end

  def suit_symbol
    @suit[:symbol]
  end

  def points
    @value[:points]
  end
end

class Game
  extend Screen
  include Dealer

  attr_reader :deck

  def initialize
    @deck = Deck.new.cards.shuffle
    @house = House.new('House')
    @player = Player.new('Player')
    @current_participant = @player
  end

  def start
    show_welcome_message
    sleep(1)
    game_loop
    show_goodbye_message
  end

  def game_loop
    loop do
      deal_initial_cards
      show_table
      play_turn
      if !@player.busted?
        switch_participant
        play_turn
      end
      show_result
      break unless play_again?
      reset_game
    end
  end

  def show_welcome_message
    puts "Welcome to OO Twenty One!"
    puts "House rules: House wins in a tie condition!"
  end

  def show_goodbye_message
    puts "Thanks for playing OO Twenty One. Goodbye!"
  end

  def deal_initial_cards
    2.times do
      deal(deck, @player)
      deal(deck, @house)
    end
  end

  def show_table
    Screen.clear
    puts "-----------------------------------------"
    puts " PLAYER | SCORE  | CARDS"
    puts "-----------------------------------------"
    puts " Player |  #{@player.show_score}".ljust(17, ' ') + "| #{@player.show_cards}"
    puts " House  |  #{@house.show_score}".ljust(17, ' ') + "| #{@house.show_cards}"
    puts "-----------------------------------------"
  end

  def play_turn
    loop do
      show_table
      choice = @current_participant.choose
      announce_choice(choice.downcase, @current_participant.type)
      sleep(1)
      deal(deck, @current_participant) if hit?(choice)
      break if @current_participant.busted? || stick?(choice)
    end
    show_table
    announce_bust(@current_participant.type) if @current_participant.busted?
  end

  def hit?(choice)
    choice.casecmp('h') == 0
  end

  def stick?(choice)
    choice.casecmp('s') == 0
  end

  def switch_participant
    if @current_participant == @player
      @current_participant = @house
      @house.turn = true
    else
      @current_participant = @player
      @house.turn = false
    end
  end

  def decide_winner
    if @house.busted?
      @player
    elsif @house.calculate_score >= @player.calculate_score
      @house
    else
      @player
    end
  end

  def winner
    @player.busted? ? @house : decide_winner
  end

  def show_result
    puts "#{winner.type} won the game!"
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp.downcase
      break if %w(y n).include? answer
      puts "Sorry, must be y or n"
    end

    answer == 'y'
  end

  def reset_game
    @deck = Deck.new.cards.shuffle
    @current_participant = @player
    @house.turn = false
    clear_hands([@player.hand, @house.hand])
  end

  def clear_hands(hands)
    hands.each(&:clear)
  end
end

Game.new.start
