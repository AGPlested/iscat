//
//  Event.swift
//  ISCAT
//
//  Created by Andrew on 06/03/2017.
//  Copyright © 2017 Andrew. All rights reserved.
//

// need these imports?
import Foundation
import UIKit

//the less essential of these entry types still to be defined
enum Entries: String {
    case sojourn, transition, opening, shutting, artifact, skipped, begin, end, misc, mark, comment, unclassified
}

class Event {
    var timePt: Float = 0      //event at 0 ms by default
    var order: Int = 0         //default list position is 0
    let kindOfEntry: Entries
    //local ID in a fit window. might be good to store the CALayer ID here??
    var localID: Int?
    //event will be date-stamped when registered to an event list
    var registered: String?
    
    init(_ kOE : Entries = .unclassified) {
        kindOfEntry = kOE
    }
    
    func printable () -> String {
        return "Undefined"
    }
}

class otherEvent: Event {
    //events and marks in the idealization that are not biophysical
    var length: Float?
    var text: String = ""
    var name: String?
    
    convenience init() {
        self.init(eKind: .unclassified)
        text = "This event was unclassified by default."
    }
    
    init (eKind:Entries) {
        super.init(eKind)
    }
    
    override func printable () -> String {
        switch kindOfEntry {
            
        case .begin:
            return String (format:"Start of analysis t. %.2f ms.", timePt)
            
        case .end:
            return String (format:"End of analysis t. %.2f ms.", timePt)
            
        default:
            if let unwrappedlen = length {
                return String(format:"%@ t. %.2f ms, d. %.2f ms", kindOfEntry.rawValue, timePt, unwrappedlen)
            } else {
                return String(format:"%@ t. %.2f ms", kindOfEntry.rawValue, timePt, text)
            }
        }
    }
}

class chEvent: Event {
    //Ion channel events
    //Structure is only enforced on printable method.
    //Would it be good to use a protocol to check that events conform?
    
    var amplitude: Double = 0     //zero by default (WHY DOUBLE?)
    var length: Float = 0
    //no length by default (e.g. transition)
    
    init (eKind:Entries) {
        super.init(eKind)
        //must initialise with a member of Entries
    }
    
    override func printable () -> String {
        switch kindOfEntry {
        
        //dwell period in unknown/not marked state
        case .sojourn:
            return String (format:"%@ t. %.2f ms, d. %.2f ms, a. %.2f pA", kindOfEntry.rawValue, timePt, length, amplitude)
        
        // open sojourn
        case .opening:
            return String (format:"%@ t. %.2f ms, d. %.2f ms, a. %.2f pA", kindOfEntry.rawValue, timePt, length, amplitude)
        
        //shut sojourn
        case .shutting:
            return String (format:"%@ t. %.2f ms, d. %.2f ms, a. %.2f pA", kindOfEntry.rawValue, timePt, length, amplitude)
            
        case .transition:
            return String (format:"%@ t. %.2f ms, a. %.2f pA", kindOfEntry.rawValue, timePt, amplitude)
            
        case .artifact:
            return String (format:"%@ t. %.2f ms, l. %.2f ms", kindOfEntry.rawValue, timePt, length)
            
        default:
            return String (format:"%@ , miscast as channel event", kindOfEntry.rawValue)
        }
    }
}

class timeStamp {
    let tdate = Date()
    let formatter = DateFormatter()
    
    func dateTimeString () -> String {
        formatter.dateFormat = "yyMMdd-HH:mm:ss"
        return formatter.string(from: tdate)
    }
}

struct eventList {
    // An array of 'Event' types with helper functions.
    // Envisage that such a list would be passed back from the
    // fitting window, could be input for an optimizer, but has
    // also has enough power to be the master list of events to be
    // stored for further analysis
    
    let creationStamp = timeStamp().dateTimeString()
    
    // a running counter of all the event addition events
    var eventsAdded : Int = 0
    var sortType = "Unsorted"
    var list = [Event]()            //empty
    
    mutating func eventAppend (e: Event) {
        eventsAdded += 1           //never decremented
        e.order = eventsAdded      //events can be reranked on order
        e.registered = timeStamp().dateTimeString()
        list.append(e)
    }
    
    mutating func eventRemove (i: Int) -> Bool  {
        if list.count >= i {
            list.remove(at: i)
            return true
        } else {
            return false
        }
    }
    
    mutating func removeEventsByKind (k : Entries) -> Bool {
        // Two-pass approach to avoid mutating list during
        // surveillance loop
        
        var markForDeletion = [Int]()
        if list.isEmpty {
            return false
        } else {
            for i in 0 ..< list.count  {
                if list[i].kindOfEntry ==  k {
                    markForDeletion.append(i)
                }
            }
            for e in markForDeletion {
                list.remove(at: e)
            }
            return true
        }
    }
    
    mutating func lastEventAddedRemove () -> Bool  {
        if list.isEmpty {
            return false
        } else {
            list.remove(at: list.count - 1)
            return true
        }
    }
    
    func count () -> Int {
        return list.count
    }
    
    mutating func sortByTimeStamp () {
        //  timestamp is zero by default
        list.sort(by: { (first: Event, second: Event) -> Bool in first.timePt < second.timePt})
        sortType = "Chronologically sorted"
    }
    
    mutating func sortByTimeStampReverse () {
        //  timestamp is zero by default
        list.sort(by: { (first: Event, second: Event) -> Bool in first.timePt > second.timePt})
        sortType = "Reversr chronologically sorted"
    }
    mutating func sortByAdded () {
        //  timestamp is zero by default
        list.sort(by: { (first: Event, second: Event) -> Bool in first.order < second.order})
        sortType = "Empirically sorted"
    }
    
    mutating func sortByAddedReverse () {
        //  timestamp is zero by default
        list.sort(by: { (first: Event, second: Event) -> Bool in first.order > second.order})
        sortType = "Reverse empirically sorted"
    }
    
    mutating func sortByAddedAndReRank () {
        sortByAdded()
        for i in 0 ..< list.count  {
            list[i].order = i + 1
        }
    }
    
    func listOfOpenings () -> [Event] {
        return list.filter ({
            if case .opening = $0.kindOfEntry { return true }; return false })
    }
    
    func listOfShuttings () -> [Event] {
        return list.filter ({
            if case .shutting = $0.kindOfEntry { return true }; return false })
    }
    
    func listOf (eType: Entries) -> [Event] {
        //eType will be in .syntax as above
        return list.filter ({
            if case eType = $0.kindOfEntry { return true }; return false })
    }
    
    func printable () -> String{
        //header
        var printableList = String (format:"%@ list of %i events, created %@\n-------------\n", sortType, list.count, creationStamp)
        
        if list.isEmpty {
            printableList = "No events"     //overwrite header
        } else {
            for e in list {
                printableList += (String(format:"%i %@ %@\n", e.order, e.registered!, e.printable()))
                //all events were registered with a timestamp when added to the list
            }
        }
        return printableList
    }
    
    func consolePrintable () -> String{
        //compact list presentation for displaying in console boxes
        //header
        var printableList = String (format:"%@ list of %i events\n", sortType, list.count)
        
        if list.isEmpty {
            printableList = "no events"     //overwrite header
        } else {
            for e in list {
                printableList += (String(format:"%i %@\n", e.order, e.printable()))
                //skip timestamp (look at the clock!)
            }
        }
        return printableList
    }
}
/*
//these are half-way to being unit tests
var event0 = otherEvent(eKind: Entries.begin)
event0.timePt = 0
event0.printable()

var event1 = chEvent(eKind: Entries.opening)
event1.amplitude = 2        //in pA
event1.timePt = 20          //in ms
event1.length = 10          //in ms
event1.printable()

var event2 = chEvent(eKind: Entries.shutting)
event2.timePt = 15
event2.length = 20
event2.printable()

var event3 = otherEvent(eKind: Entries.end)
event3.timePt = 100
event3.printable()

var event4 = chEvent(eKind: Entries.transition)
event4.timePt = 90
event4.amplitude = -2
event4.printable()

var event5 = otherEvent()
event5.printable()


var listOfEvents = eventList()
listOfEvents.eventAppend(e: event0)
listOfEvents.eventAppend(e: event1)
listOfEvents.eventAppend(e: event2)
listOfEvents.eventAppend(e: event3)
listOfEvents.eventAppend(e: event4)
listOfEvents.eventAppend(e: event5)

var emptyListOfEvents = eventList()

print (listOfEvents.printable())

print ("Empty list: ", emptyListOfEvents.printable())

for  e in listOfEvents.listOfOpenings() {
    print ("List of Openings")
    print (e.printable())
}

for  e in listOfEvents.listOfShuttings() {
    print ("List of Shuttings")
    print (e.printable())
}

for e in listOfEvents.listOf(eType: .begin) {
    print (e.printable())
}

print ("No. of events: " + String(listOfEvents.count()))
if listOfEvents.eventRemove(i: 3) { print("Event 3 removed")}
if listOfEvents.lastEventAddedRemove() { print("Last event added removed")}
print ("No. of events: " + String(listOfEvents.count()))
listOfEvents.sortByTimeStamp()
print (listOfEvents.printable())
listOfEvents.sortByAddedAndReRank()
listOfEvents.sortByAddedReverse()
print (listOfEvents.count())
print (listOfEvents.printable())
listOfEvents.removeEventsByKind(k: .opening)
print (listOfEvents.printable())
listOfEvents.sortByAddedAndReRank()
print (listOfEvents.printable())
*/

