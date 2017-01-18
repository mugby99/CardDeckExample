//
//  ViewController.swift
//  CardDeckExample
//
//  Created by Uribe, Martin on 1/16/17.
//  Copyright © 2017 MUGBY. All rights reserved.
//

import UIKit

extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}

public enum CardSuit {
    case Clubs, Diamonds, Hearts, Spades
    
    func stringRepresentation() -> String {
        switch self {
        case .Clubs:
            return "\u{2663}"
        case .Diamonds:
            return "\u{2666}"
        case .Hearts:
            return "\u{2665}"
        case .Spades:
            return "\u{2660}"
        }
    }
    
    func rank() -> Int {
        switch self {
        case .Clubs:
            return 0
        case .Diamonds:
            return 1
        case .Hearts:
            return 2
        case .Spades:
            return 3
        }
    }
}

public enum CardDeck {
    case Red, Blue
    
    func reuseIdentifier() -> String {
        switch self {
        case .Red:
            return "RedDeckCard"
        case .Blue:
            return "BlueDeckCard"
        }
    }
}

public struct Card {
    let suit: CardSuit!
    let rank: String!
    let deck: CardDeck!
    
    func stringRepresentation() -> String {
        return "\(suit.stringRepresentation()) " + rank
    }
    
    static func intFromRank(rank: String) -> Int {
        switch rank {
        case "A":
            return 1
        case "J":
            return 11
        case "Q":
            return 12
        case "K":
            return 13
        default:
            return Int(rank) ?? -1
        }
    }
    
    static func rankFromInt(rank: Int) -> String {
        switch rank {
        case 1:
            return "A"
        case 11:
            return "J"
        case 12:
            return "Q"
        case 13:
            return "K"
        default:
            return String(rank)
        }
    }
}

public struct Deck {
    var clubsDeck = [Card]()
    var diamondsDeck = [Card]()
    var heartsDeck = [Card]()
    var spadesDeck = [Card]()
    
    func deckForSection(section: Int) -> [Card] {
        switch section {
        case 0:
            return clubsDeck
        case 1:
            return diamondsDeck
        case 2:
            return heartsDeck
        case 3:
            return spadesDeck
        default:
            return []
        }
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var redDeckCollectionView: UICollectionView!
    @IBOutlet weak var blueDeckCollectionView: UICollectionView!
    @IBOutlet weak var scrambledDeckCollectionView: UICollectionView!
    
    
    
    var redDeck = Deck()
    var blueDeck = Deck()
    var scrambledDeck = [Card]()
    let standard52DeckRanks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let suits: [CardSuit] = [.Clubs, .Diamonds, .Hearts, .Spades]
        let decks: [CardDeck] = [.Red, .Blue]
        for deck in decks {
            for suit in suits {
                for rank in 1...13 {
                    scrambledDeck.append(Card(suit: suit, rank: Card.rankFromInt(rank: rank), deck: deck))
                }
            }
        }
        
        scrambledDeck.shuffle()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func reorderDecks(_ sender: Any) {
        scrambledDeck = scrambledDeck.mergeSort()
        scrambledDeckCollectionView.reloadData()
    }
    
    @IBAction func scrambleDecks(_ sender: Any) {
        scrambledDeck.shuffle()
        scrambledDeckCollectionView.reloadData()
    }
    
}

extension ViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == scrambledDeckCollectionView {
            return 1
        }
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case scrambledDeckCollectionView:
            return scrambledDeck.count
        case redDeckCollectionView:
            return redDeck.deckForSection(section: section).count
        case blueDeckCollectionView:
            return blueDeck.deckForSection(section: section).count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var card: Card!
        switch collectionView {
        case scrambledDeckCollectionView:
            card = scrambledDeck[indexPath.item]
        case redDeckCollectionView:
            card = redDeck.deckForSection(section: indexPath.section)[indexPath.item]
        case blueDeckCollectionView:
            card = blueDeck.deckForSection(section: indexPath.section)[indexPath.item]
        default:
            return UICollectionViewCell()
        }
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: card.deck.reuseIdentifier(), for: indexPath) as? CardCell else {
            return UICollectionViewCell()
        }
        cell.cardLabel.text = card.stringRepresentation()
        
        return cell
    }
}

extension ViewController: UICollectionViewDelegate {
    
}
