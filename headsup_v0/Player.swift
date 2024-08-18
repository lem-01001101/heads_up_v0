//
//  Player.swift
//  headsup_v0
//
//  Created by Magtibay , Leo Jacinto  Malaluan on 8/18/24.
//

import Foundation

class Player: ObservableObject {
    let name: String
    @Published var stack: Int
    @Published var hand: [Card]

    init(name: String, stack: Int) {
        self.name = name
        self.stack = stack
        self.hand = []
    }

    func bet(amount: Int) -> Int {
        let betAmount = min(amount, stack)
        stack -= betAmount
        return betAmount
    }

    func fold() {
        hand = []
    }
}
