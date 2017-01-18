//
//  MergeSort.swift
//  CardDeckExample
//
//  Created by Uribe, Martin on 1/17/17.
//  Copyright © 2017 MUGBY. All rights reserved.
//

import Foundation

extension Card {
    
    func isHigherThanCard(card: Card) -> Bool {
        if deck == card.deck {
            if (card.suit.rank() == suit.rank()) {
                return Card.intFromRank(rank:rank) > Card.intFromRank(rank: card.rank)
            }
            else {
                return card.suit.rank() > suit.rank()
            }
        }
        else {
            return deck == .Red
        }
    }
}

extension MutableCollection where Self.Iterator.Element == Card {
    
    func mergeSortWithListener(listener: Listener?, threadSleep: useconds_t) -> [Card] {
        if count <= 1 || listener == nil { // O(1)
            return self as! [Card]
        }
        let length = distance(from: startIndex, to:endIndex) as! Int // O(n)
        var middle = Int(floor(Double(length/2))) // O(1)
        var leftItems: [Card] = Array(prefix(middle) as! ArraySlice<Card>) // O(n)
        middle = length % 2 == 0 ? middle : middle + 1
        var rightItems: [Card] = Array(suffix(middle) as! ArraySlice<Card>) // O(n)
        var evaluatingLeftIndex = 0 // O(1)
        var evaluatingRightIndex = 0 // O(1)
        var mergedArray = [Card]() // O(1)
        leftItems = leftItems.mergeSortWithListener(listener: listener, threadSleep: threadSleep) // O(nlog(n))
        rightItems = rightItems.mergeSortWithListener(listener: listener, threadSleep: threadSleep) // O(nlog(n))
        
        var mergeIndex = 0
        while mergeIndex < length { // O(n)
            //            mergedArray.insert(leftItems[evaluatingLeftIndex], at: evaluatingLeftIndex)
            if evaluatingLeftIndex == leftItems.count { // O(1)
                // Add remaining right array items to mergedArray
                mergedArray.insert(rightItems[evaluatingRightIndex], at: mergeIndex) // O(n) !!!
                evaluatingRightIndex += 1 // O(1)
            }
            else if evaluatingRightIndex == rightItems.count { // O(1)
                // Add remaining left array items to mergedArray
                mergedArray.insert(leftItems[evaluatingLeftIndex], at: mergeIndex) // O(n) !!!
                evaluatingLeftIndex += 1 // O(1)
            }
            else if leftItems[evaluatingLeftIndex].isHigherThanCard(card: rightItems[evaluatingRightIndex]) { // O(1)
                mergedArray.insert(rightItems[evaluatingRightIndex], at: mergeIndex) // O(n) !!!
                evaluatingRightIndex += 1 // O(1)
            }
            else { // O(1)
                mergedArray.insert(leftItems[evaluatingLeftIndex], at: mergeIndex) // O(n) !!!
                evaluatingLeftIndex += 1 // O(1)
            }
            mergeIndex += 1 // O(1)
        }
        DispatchQueue.main.async {
            listener?(mergedArray)
        }
        
        usleep(threadSleep)
        
        return mergedArray
    }
}
