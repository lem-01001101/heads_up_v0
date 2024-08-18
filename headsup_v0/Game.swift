//
//  Game.swift
//  headsup_v0
//
//  Created by Magtibay , Leo Jacinto  Malaluan on 8/18/24.
//

import Foundation

class PokerGame: ObservableObject {
    @Published var player: Player
    @Published var computer: Player
    @Published var deck = Deck()
    @Published var communityCards: [Card] = []
    @Published var pot: Int = 0

    init() {
        self.player = Player(name: "Player", stack: 1000)
        self.computer = Player(name: "Computer", stack: 1000)
    }

    func dealHands() {
        player.hand = [deck.deal(), deck.deal()]
        computer.hand = [deck.deal(), deck.deal()]
    }

    func dealCommunityCards() {
        communityCards = [deck.deal(), deck.deal(), deck.deal(), deck.deal(), deck.deal()]
    }

    func bettingRound(playerAction: (String) -> Void, computerAction: () -> String) {
        // Handle player and computer actions
    }

    func determineWinner() {
        // Compare hands to determine the winner
    }
}
