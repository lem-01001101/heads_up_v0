//
//  Deck.swift
//  headsup_v0
//
//  Created by Magtibay , Leo Jacinto  Malaluan on 8/18/24.
//


import Foundation

/*
 # Represents the four suits in a deck of cards: Hearts, Diamonds, Clubs, and Spades.
 # String is the raw value type, which means each case has a raw value (H, D, C, S).
 # CaseIterable is a protocol that allows you to iterate over all cases of the enum. This is useful for generating all possible suits.
 */
enum Suit: String, CaseIterable {
    case hearts = "H", diamonds = "D", clubs = "C", spades = "S"
}

/*
 # Represents the 13 ranks in a deck of cards: 2 through 10, Jack, Queen, King, and Ace.
 # String is the raw value type, so each rank has a corresponding string value.
 */
enum Rank: String, CaseIterable {
    case two = "2", three = "3", four = "4", five = "5", six = "6", seven = "7", eight = "8", nine = "9", ten = "10", jack = "J", queen = "Q", king = "K", ace = "A"
}

/*
 # Represents a single card in the deck.
 # Contains two properties: suit and rank, both of which are enums (Suit and Rank).
 # The Card struct is a simple data structure with immutable properties, meaning that once a Card is created, its suit and rank cannot be changed.
 */

struct Card {
    let suit: Suit
    let rank: Rank
}


// Manages a collection of Card objects, representing a standard deck of 52 playing cards.
class Deck {
    private var cards: [Card] = []

    init() {
        // Suit.allCases: This returns a collection of all possible values in the Suit enum. For the Suit enum, it would be [hearts, diamonds, clubs, spades].
        self.cards = Suit.allCases.flatMap { suit in
            // Rank.allCases: Similarly, this returns a collection of all possible values in the Rank enum. For the Rank enum, it would be [two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace].
            // flatMap: This is a higher-order function used to flatten a collection of collections into a single collection. It applies the provided closure to each element of the Suit.allCases collection and concatenates the results.
            Rank.allCases.map { rank in
                // Rank.allCases: this returns a collection of all possible values in the Rank enum. For the Rank enum, it would be [two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace].
                Card(suit: suit, rank: rank)
                    // flatMap: This is another higher-order function used to flatten a collection of collections into a single collection. It applies the provided closure to each element of the Suit.allCases collection and concatenates the results.
            }
        }
        
        // This will generate:
        // [Card(suit: .hearts, rank: .two), Card(suit: .hearts, rank: .three),
        //  Card(suit: .diamonds, rank: .two), Card(suit: .diamonds, rank: .three)] etc.
        
        self.cards.shuffle()
    }

    func deal() -> Card {
        return cards.removeLast()
    }
}
