//
//  Game.swift
//  headsup_v0
//
//  Created by Magtibay , Leo Jacinto  Malaluan on 8/18/24.
//

/*
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
 */

import Foundation

enum Street: String {
    case preflop, flop, turn, river, showdown
}

enum Actor {
    case player, computer
}

final class PokerGame: ObservableObject {

    // MARK: - Config
    let smallBlind = 10
    let bigBlind = 20
    let startingStack = 1000

    // MARK: - Public UI State
    @Published var player: Player
    @Published var computer: Player
    @Published var deck = Deck()
    @Published var communityCards: [Card] = []
    @Published var pot: Int = 0
    @Published var street: Street = .preflop
    @Published var actorToAct: Actor = .player
    @Published var message: String = ""
    @Published var toCallPlayer: Int = 0
    @Published var toCallComputer: Int = 0
    @Published var currentBet: Int = 0
    @Published var minRaise: Int = 20
    @Published var dealerIsPlayer: Bool = true // dealer posts SB heads-up

    // Track how much each has put in *this street*
    private var contribPlayer: Int = 0
    private var contribComputer: Int = 0
    private var someoneRaisedThisStreet = false
    private var handOver = false

    init() {
        self.player   = Player(name: "You",      stack: startingStack)
        self.computer = Player(name: "Computer", stack: startingStack)
        startNewHand()
    }

    // MARK: - Hand Lifecycle

    func startNewHand() {
        // Rotate dealer
        dealerIsPlayer.toggle()

        // Reset state
        deck = Deck()
        communityCards = []
        pot = 0
        street = .preflop
        message = ""
        currentBet = 0
        minRaise = bigBlind
        contribPlayer = 0
        contribComputer = 0
        someoneRaisedThisStreet = false
        handOver = false

        // Deal
        player.hand = [deck.deal(), deck.deal()]
        computer.hand = [deck.deal(), deck.deal()]

        // Post blinds (dealer = SB in heads-up)
        if dealerIsPlayer {
            postBlind(actor: .player, amount: smallBlind)
            postBlind(actor: .computer, amount: bigBlind)
            currentBet = bigBlind
            // In heads-up, dealer acts first preflop
            actorToAct = .player
        } else {
            postBlind(actor: .computer, amount: smallBlind)
            postBlind(actor: .player, amount: bigBlind)
            currentBet = bigBlind
            actorToAct = .computer
        }

        updateToCalls()
        message = "New hand. \(dealerIsPlayer ? "You" : "Computer") are the dealer (SB)."
        // If it's computer's action preflop, let it act
        if actorToAct == .computer { computerAutoAct() }
    }

    private func postBlind(actor: Actor, amount: Int) {
        let bet = amount
        switch actor {
        case .player:
            pot += player.bet(amount: bet)
            contribPlayer += bet
        case .computer:
            pot += computer.bet(amount: bet)
            contribComputer += bet
        }
    }

    // MARK: - Player Actions

    func playerCheckOrCall() {
        guard !handOver, actorToAct == .player else { return }
        let toCall = toCallPlayer

        if toCall == 0 {
            // Check
            message = "You check."
            nextActorAfterPassiveAction(from: .player)
        } else {
            // Call
            let callAmt = min(toCall, player.stack)
            pot += player.bet(amount: callAmt)
            contribPlayer += callAmt
            message = "You call \(callAmt)."
            // If all-in, it's still fine; betting round may close if matched
            maybeCloseBettingRoundOrPassTurn()
        }
        updateToCalls()
        if actorToAct == .computer && !handOver { computerAutoAct() }
    }

    func playerFold() {
        guard !handOver, actorToAct == .player else { return }
        message = "You fold. Pot \(pot) goes to Computer."
        awardPot(to: .computer)
    }

    func playerBetOrRaise(amount: Int) {
        guard !handOver, actorToAct == .player else { return }

        // If no current bet to face, it's a bet; else it's a raise
        let myContrib = contribPlayer
        let oppContrib = contribComputer
        let facing = max(currentBet - myContrib, 0)

        // Enforce min raise: if facing == 0, min open is bigBlind; if facing > 0, min raise size is (currentBet - oppPrevBet)
        let minOpen = bigBlind
        let minRaiseSize = max(minRaise, bigBlind)

        var totalPutInThisAction = 0

        if facing == 0 {
            // Bet
            let legal = max(amount, minOpen)
            totalPutInThisAction = legal
            currentBet = myContrib + legal
            minRaise = legal // next min-raise size equals the bet size
            someoneRaisedThisStreet = true
            message = "You bet \(legal)."
        } else {
            // Raise
            let raiseSize = max(amount, minRaiseSize)
            totalPutInThisAction = facing + raiseSize
            currentBet = myContrib + totalPutInThisAction
            minRaise = raiseSize // next min-raise size becomes this raise size
            someoneRaisedThisStreet = true
            message = "You raise \(totalPutInThisAction) total."
        }

        // Cap by stack (all-in logic)
        totalPutInThisAction = min(totalPutInThisAction, player.stack + totalPutInThisAction)
        let actuallyPaid = player.bet(amount: totalPutInThisAction)
        contribPlayer += actuallyPaid
        pot += actuallyPaid

        updateToCalls()
        // After a bet/raise, turn passes
        actorToAct = .computer
        if !handOver { computerAutoAct() }
    }

    // MARK: - Computer AI (very simple for now)

    private func computerAutoAct() {
        guard !handOver, actorToAct == .computer else { return }

        let toCall = toCallComputer
        // Tiny heuristic: sometimes bluff, sometimes call, rarely fold small bets, fold big when weak
        let weak = handStrength(for: .computer) < handStrength(for: .player) // extremely naive
        let facingBig = toCall >= 4 * bigBlind
        let rng = Int.random(in: 0..<100)

        if toCall == 0 {
            // Check or bet small sometimes
            if rng < 15 {
                computerBetOrRaise(amount: bigBlind * 2) // probe bet
            } else {
                message = "Computer checks."
                nextActorAfterPassiveAction(from: .computer)
                updateToCalls()
            }
        } else {
            // Facing a bet
            if weak && facingBig && rng < 70 {
                computerFold()
            } else if rng < 15 && computer.stack > toCall + bigBlind * 2 {
                computerBetOrRaise(amount: bigBlind * 2) // light raise
            } else {
                computerCall()
            }
        }
    }

    private func computerFold() {
        guard !handOver else { return }
        message = "Computer folds. You win \(pot)."
        awardPot(to: .player)
    }

    private func computerCall() {
        guard !handOver else { return }
        let toCall = min(toCallComputer, computer.stack)
        let paid = computer.bet(amount: toCall)
        contribComputer += paid
        pot += paid
        message = "Computer calls \(paid)."
        maybeCloseBettingRoundOrPassTurn()
        updateToCalls()
    }

    private func computerBetOrRaise(amount: Int) {
        guard !handOver else { return }
        let myContrib = contribComputer
        let facing = max(currentBet - myContrib, 0)
        let minOpen = bigBlind
        let minRaiseSize = max(minRaise, bigBlind)

        var totalPutIn = 0
        if facing == 0 {
            let legal = max(amount, minOpen)
            totalPutIn = legal
            currentBet = myContrib + legal
            minRaise = legal
            someoneRaisedThisStreet = true
            message = "Computer bets \(legal)."
        } else {
            let raiseSize = max(amount, minRaiseSize)
            totalPutIn = facing + raiseSize
            currentBet = myContrib + totalPutIn
            minRaise = raiseSize
            someoneRaisedThisStreet = true
            message = "Computer raises \(totalPutIn) total."
        }

        let paid = computer.bet(amount: totalPutIn)
        contribComputer += paid
        pot += paid
        updateToCalls()
        actorToAct = .player
    }

    // MARK: - Round / Street transitions

    private func maybeCloseBettingRoundOrPassTurn() {
        // If both have matched currentBet (or one/all-in and the other matched), close the betting round.
        let bothMatched = contribPlayer == contribComputer && contribPlayer == currentBet
        let someoneAllIn = player.stack == 0 || computer.stack == 0
        if bothMatched || someoneAllIn {
            closeBettingRound()
        } else {
            // Pass turn to the other
            actorToAct = (actorToAct == .player) ? .computer : .player
        }
    }

    private func nextActorAfterPassiveAction(from: Actor) {
        // If both checked and no bet this street, close the round.
        // For heads-up: if second actor also checks, close the round.
        if someoneRaisedThisStreet {
            // There was aggression earlier; a check hands action to opp
            actorToAct = (from == .player) ? .computer : .player
            return
        }
        // If the other already checked this street and now another check -> close
        // Easy way: if currentBet == both contrib and they are equal AND no aggression -> close
        let bothEvenNoBet = (currentBet == 0) && (contribPlayer == contribComputer)
        if bothEvenNoBet && (from == .computer) {
            closeBettingRound()
        } else {
            actorToAct = (from == .player) ? .computer : .player
        }
    }

    private func closeBettingRound() {
        someoneRaisedThisStreet = false
        minRaise = bigBlind
        currentBet = 0
        contribPlayer = 0
        contribComputer = 0
        updateToCalls()

        switch street {
        case .preflop:
            burn(1); dealCommunity(count: 3) // flop
            street = .flop
            // Postflop, heads-up: dealer acts second; non-dealer acts first.
            actorToAct = dealerIsPlayer ? .computer : .player
            message = "Dealing the flop."
        case .flop:
            burn(1); dealCommunity(count: 1) // turn
            street = .turn
            actorToAct = dealerIsPlayer ? .computer : .player
            message = "Dealing the turn."
        case .turn:
            burn(1); dealCommunity(count: 1) // river
            street = .river
            actorToAct = dealerIsPlayer ? .computer : .player
            message = "Dealing the river."
        case .river:
            street = .showdown
            doShowdown()
            return
        case .showdown:
            return
        }

        if actorToAct == .computer && !handOver { computerAutoAct() }
    }

    private func burn(_ n: Int) {
        for _ in 0..<n { _ = deck.deal() }
    }

    private func dealCommunity(count: Int) {
        for _ in 0..<count { communityCards.append(deck.deal()) }
    }

    private func doShowdown() {
        guard !handOver else { return }
        let winner = compareHands()
        switch winner {
        case .player:
            message = "Showdown: you win \(pot)."
            awardPot(to: .player)
        case .computer:
            message = "Showdown: computer wins \(pot)."
            awardPot(to: .computer)
        }
    }

    private func awardPot(to: Actor) {
        if to == .player { player.stack += pot } else { computer.stack += pot }
        pot = 0
        handOver = true

        // If someone is broke, match over; else auto-start a new hand after a tiny delay in UI-land if you want.
        if player.stack == 0 || computer.stack == 0 {
            message += " Match over."
        } else {
            // Start next hand right away (or trigger from UI button)
            // startNewHand()
        }
    }

    private func updateToCalls() {
        toCallPlayer   = max(currentBet - contribPlayer, 0)
        toCallComputer = max(currentBet - contribComputer, 0)
    }

    // MARK: - Super naive hand compare (stub)
    // Replace with a real evaluator later.
    private func compareHands() -> Actor {
        let p = handStrength(for: .player)
        let c = handStrength(for: .computer)
        if p == c {
            // simple split: return chips back evenly (real poker would chop pot)
            let half = pot / 2
            player.stack += half
            computer.stack += (pot - half)
            pot = 0
            handOver = true
            return .player // arbitrary for message flow
        }
        return (p > c) ? .player : .computer
    }

    private func handStrength(for actor: Actor) -> Int {
        // TEMP: high-card over 7-card set (hole + board) by rank index.
        let cards = (actor == .player ? player.hand : computer.hand) + communityCards
        let order: [Rank] = [.two,.three,.four,.five,.six,.seven,.eight,.nine,.ten,.jack,.queen,.king,.ace]
        return cards.map { order.firstIndex(of: $0.rank)! }.max() ?? 0
    }
}
