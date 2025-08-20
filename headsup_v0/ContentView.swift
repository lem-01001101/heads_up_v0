//
//  ContentView.swift
//  headsup_v0
//
//  Created by Magtibay , Leo Jacinto  Malaluan on 8/18/24.
//

import SwiftUI


struct ContentView: View {
    @StateObject private var game = PokerGame()
    @State private var raiseAmountText: String = "40"

    var body: some View {

        VStack (spacing: 16) {
            Text("Heads Up Poker")
                .font(.largeTitle)
            
            VStack (alignment: .leading, spacing: 6) {
                Text("Computer: \(game.computer.stack)")
                Text("Hand: \(cardsString(game.computer.hand))")
            }

            Spacer()
            
            VStack(spacing: 8) {
                
                Text("Dealer: \(game.dealerIsPlayer ? "You" : "Dealer")")
                Text("Street: \(game.street.rawValue.capitalized)")
                
                Text("Board: \(cardsString(game.communityCards))")
                    .font(.title)
                    .bold()
                
                Text("Pot: \(game.pot)")
                Text("To Call — You: \(game.toCallPlayer), CPU: \(game.toCallComputer)")
                Text("Min Raise: \(game.minRaise)")
                Text("Action: \(game.actorToAct == .player ? "You" : "Computer")")
                                .bold()
                Text(game.message).font(.footnote).foregroundStyle(.secondary)
            }
            
            HStack {
                Button("Deal / Next Hand") { game.startNewHand() }
                .buttonStyle(.bordered)
            }
            .padding(.top, 8)
            


            Spacer()
            
            VStack(spacing: 6) {
                Text("You: \(game.player.stack)")
                Text("Hand: \(cardsString(game.player.hand))")
            }
                        VStack {
                HStack(spacing: 10) {
                    Button(action: { game.playerCheckOrCall() }) {
                        Text(game.toCallPlayer == 0 ? "Check" : "Call \(game.toCallPlayer)")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(game.actorToAct != .player)

                    Button("Fold") {
                        game.playerFold()
                    }
                    .buttonStyle(.bordered)
                    .disabled(game.actorToAct != .player)
                }

                HStack(spacing: 10) {
                    TextField("Bet/Raise", text: $raiseAmountText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)

                    Button("Bet/Raise") {
                        let amt = Int(raiseAmountText) ?? game.minRaise
                        game.playerBetOrRaise(amount: amt)
                    }
                    .buttonStyle(.bordered)
                    .disabled(game.actorToAct != .player)
                }
            }
            .padding(.horizontal)


        }
    }
    
    private func cardsString(_ cards: [Card]) -> String {
        cards.map { "\($0.rank.rawValue)\($0.suit.rawValue)" }.joined(separator: " ")
    }
}


#Preview {
    ContentView()
}
