//
//  ContentView.swift
//  headsup_v0
//
//  Created by Magtibay , Leo Jacinto  Malaluan on 8/18/24.
//

import SwiftUI


struct ContentView: View {
    @StateObject private var game = PokerGame()

    var body: some View {

        VStack {
            Text("Heads Up Poker")
                .padding()
                .bold()
                .background(
                    Color(.blue))
            
            VStack {
                // Display computer's hand
                Text("Computer's Hand: \(game.computer.hand.map { "\($0.rank.rawValue)\($0.suit.rawValue)" }.joined(separator: ", "))")
                Text("Computer Stack: \(game.computer.stack)")
            }
            Spacer()
            VStack{
                // Display community cards
                Text("Community Cards: \(game.communityCards.map { "\($0.rank.rawValue)\($0.suit.rawValue)" }.joined(separator: ", "))")
                Text("Pot: \(game.pot)")
            }
            Spacer()
            VStack {
                // Display computer's hand
                Text("Your Hand: \(game.player.hand.map { "\($0.rank.rawValue)\($0.suit.rawValue)" }.joined(separator: ", "))")
                Text("Your Stack: \(game.player.stack)")
                HStack {
                        Button("Check") {
                            // Implement check action
                        }
                        Button("Call") {
                            // Implement call action
                        }
                        Button("Raise") {
                            // Implement raise action
                        }
                        Button("Fold") {
                            // Implement fold action
                        }
                }
                .padding()
            }
        }
        .padding()
        .onAppear {
            game.dealHands()
            //game.dealCommunityCards()
            // checking if pushing works
            
        }
    }
}


#Preview {
    ContentView()
}
