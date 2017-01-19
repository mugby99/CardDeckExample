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

typealias Listener = ([Card]) -> Void

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
    fileprivate var listener: Listener!
    var mergeProcessCounter = [Int:Int]()
    var threadSleep: UInt32 = 1
    var currentSubArray:[Card]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initListener()
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
    
    func initListener() {
        listener = { [weak self] sortedSubArray in
            self?.currentSubArray = sortedSubArray
            guard let levelCounter = self?.mergeProcessCounter[sortedSubArray.count] as Int? else {
                self?.mergeProcessCounter[sortedSubArray.count] = 1
                self?.scrambledDeckCollectionView.reloadData()
                self?.scrambledDeck.replaceSubrange(0..<sortedSubArray.count, with: sortedSubArray)
                self?.scrambledDeckCollectionView.reloadData()
                return
            }
            let startIndex = levelCounter*sortedSubArray.count
            if (startIndex + sortedSubArray.count) <= self?.scrambledDeck.count ?? 0 {
                self?.mergeProcessCounter[sortedSubArray.count] = levelCounter + 1
                self?.scrambledDeckCollectionView.reloadData()
                self?.scrambledDeck.replaceSubrange(startIndex..<(startIndex + sortedSubArray.count), with: sortedSubArray)
                self?.scrambledDeckCollectionView.reloadData()
            }
        }
    }

    @IBAction func reorderDecks(_ sender: Any) {
        reorderDecks()
    }
    
    @IBAction func scrambleDecks(_ sender: Any) {
        listener = nil
        initListener()
        mergeProcessCounter.removeAll()
        scrambledDeck.shuffle()
        scrambledDeckCollectionView.reloadData()
        scrambledDeckCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .left, animated: true)
    }
    
    func reorderDecks() {
        mergeProcessCounter.removeAll()
        listener = nil
        initListener()
        DispatchQueue.global(qos: .background).async {
            let deck = self.scrambledDeck
            self.scrambledDeck = deck.mergeSortWithListener(listener: self.listener, threadSleep: self.threadSleep)
        }
    }
    
    func threadSleepStringForRow(row: Int) -> String {
        switch row {
        case 0:
            return "0"
        case 1:
            return "0.5"
        case 2:
            return "1"
        case 3:
            return "1.5"
        default:
            return "0"
        }
    }
    
    func threadSleepIntForRow(row: Int) -> useconds_t {
        let second: Double = 1000000
        return UInt32(Double(threadSleepStringForRow(row: row))! * second)
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
        cell.alpha = 1
        if mergeProcessCounter.count > 0 && currentSubArray != nil {
            if currentSubArray!.contains(scrambledDeck[indexPath.row]) {
                cell.alpha = 0.5
            }
        }
        
        return cell
    }
}

extension ViewController: UICollectionViewDelegate {
    
}

extension ViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return component == 0 ? 1 : 4
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return "Thread Sleep:"
        }
        else {
            return threadSleepStringForRow(row: row)
        }
    }
}

extension ViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        threadSleep = threadSleepIntForRow(row: row)
    }
}
