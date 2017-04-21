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

let chEvents = [
    Entries.sojourn, Entries.transition, Entries.opening, Entries.shutting, Entries.artifact
]

let otherEvents = [
    Entries.begin, Entries.end, Entries.misc, Entries.mark, Entries.comment, Entries.unclassified
]


struct StoredEvent {
    var kindOfEvent : Entries?
    var timePt: Float = 0
    var duration: Float?
    var amplitude: Float?
    var localID: Int?
    var registered: String?
}

class Event {
    
    var timePt: Float = 0      //event at 0 ms by default
    var order: Int = 0         //default list position is 0
    var duration: Float?         //some types of event have no meaningful duration
    var amplitude: Double?     //some events don't have any amplitude (WHY DOUBLE?)
    
    //event metadata
    var kindOfEntry: Entries
    var colorFitSSD: UIColor?   //if event was fitted, save the color for later
    var fitSSD : Float?         //save SSD per data point from fit
    var isChannelEvent : Bool  //if false, it's an "other event" :
    //meaning an event or mark in the idealization that is not biophysical
    var text: String?
    var name: String?
    
    //local ID of the event in an active fit view.
    var localID: Int?
    
    //event will be date-stamped when registered to an event list
    //must be optional, can't be stored now.
    var registered: String?
    
    init(_ kOE : Entries = .unclassified) {
        kindOfEntry = kOE
        if kindOfEntry == .unclassified {
            text = "This event was unclassified by default."
        }
        
        if chEvents.contains(kindOfEntry)  {
            isChannelEvent = true
        } else {
            isChannelEvent = false
        }
    }
    
    func printable () -> String {
        switch kindOfEntry {
            
        case .begin:
            return String (format:"Start of analysis t. %.2f ms.", timePt)
            
        case .end:
            return String (format:"End of analysis t. %.2f ms.", timePt)
          
        //Ion channel events
        //Structure is only enforced on printable method.
        //Would it be good to use a protocol to check that events conform?
            
        //dwell period in unknown/not marked state, opening or shutting
        case .sojourn, .opening, .shutting:
            return String (format:"%@ t. %.1f ms, d. %.1f ms, a. %.1f pA, SSD %.0f", kindOfEntry.rawValue, timePt, duration!, amplitude!, fitSSD!)
        /*
        //now taken care of above; simpler
        // open sojourn
        case .opening:
            return String (format:"%@ t. %.1f ms, d. %.2f ms, a. %.2f pA, SSD %0f", kindOfEntry.rawValue, timePt, duration!, amplitude!, fitSSD!)
            
        //shut sojourn
        case .shutting:
            return String (format:"%@ t. %.1f ms, d. %.1f ms, a. %.1f pA, SSD %0f", kindOfEntry.rawValue, timePt, duration!, amplitude!, fitSSD!)
        */
        case .transition:
            return String (format:"%@ t. %.2f ms, a. %.2f pA", kindOfEntry.rawValue, timePt, amplitude!)
            
        case .artifact:
            return String (format:"%@ t. %.2f ms, l. %.2f ms", kindOfEntry.rawValue, timePt, duration!)
    
        default:
            if let unwrappedlen = duration {
                return String(format:"%@ t. %.2f ms, d. %.2f ms", kindOfEntry.rawValue, timePt, unwrappedlen)
            } else {
                return String(format:"%@ t. %.2f ms", kindOfEntry.rawValue, timePt, text!)
            }
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
    
    func hasEventWithID (ID: Int) -> Bool   {
        if list.isEmpty {
            return false
        }
        else {
            for e in list {
                if e.localID == ID {
                    return true
                }
            }
        }
        //if no event with localID given is found
        return false
    }
    
    mutating func removeEventByLocalID (ID: Int) -> Bool {
        if list.isEmpty {
            return false
        } else {
            for i in 0 ..< list.count {
                if list[i].localID == ID {
                    list.remove(at: i)
                    return true
                }
            }
        }
        //if no event with localID given is found
        return false
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

    mutating func removeEventsBySSD (threshold : Float) -> Bool {
        // Two-pass approach to avoid mutating list during
        // surveillance loop
        
        var markForDeletion = [Int]()
        if list.isEmpty {
            return false
        } else {
            for i in 0 ..< list.count  {
                if list[i].fitSSD != nil {
                    if list[i].fitSSD! > threshold {
                        markForDeletion.append(i)
                    }
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
        sortType = "Reverse chronologically sorted"
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
    
    func listOfEventsInRange (startRange: Float, endRange: Float) -> [Event] {
        //range values are in ms
        let s = startRange
        let e = endRange
        return list.filter ({
            if s < $0.timePt && e > $0.timePt ||  s < $0.timePt + $0.duration! && e > $0.timePt + $0.duration! { return true }; return false })
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
    
    func tableListing (title: String = "") -> (String, [[String:String]]) {
        var cell = [String:String]()
        var cells = [[String:String]]()
        let formattedTitle = titleGenerator(title: title)
        for e in list {
            cell = ["timePt" : String(e.timePt), "duration" : String(describing: e.duration!), "amplitude" : String(describing: e.amplitude!), "kOE" : e.kindOfEntry.rawValue]
            cells.append(cell)
        }
        
        return (formattedTitle, cells)
    }
    
    func titleGenerator (title: String = "") -> String {
        var extendedTitle : String
        if title == "" {
            extendedTitle = String (format:"%@ list of %i events\n", sortType, list.count)
        } else {
            extendedTitle = String (format:"%@ %i events\n", title, list.count)
        }
        return extendedTitle
    }
    
    func consolePrintable (title: String = "") -> String{
        //compact list presentation for displaying in console boxes
        var printableList : String
        //header
        
        //jog on
        if list.isEmpty {
            if title == "Selected" {
                return "Nothing selected"
            } else {
                return "No events"
            }
        }
        
        if list.count == 1 {
            printableList = "1 event\n" //singleton can't have any kind of sorting!!!
        }   else {
            printableList = titleGenerator(title: title)
        }
            
        for e in list {
            printableList += (String(format:"%i %@\n", e.order, e.printable()))
            //skip timestamp (look at the clock!)
        }
            
        return printableList
    }
}

class recentEventTableItem: NSObject {
    // A text description of this recent fit for UITableView.
    
    var info : String?
    var rank : String?
    var events : String?

    //provides strings to display the recent fit values
    
    init(eL: eventList, position: Int) {
        //when table is first shown, there have been no fits (signalled with -1)
        if position == -1 {
            rank = "  No fit yet"
            info = ""
            events = ""
        } else {
            rank = String (position)
            info = eL.creationStamp
            if eL.list.isEmpty  {
                events = "No events fitted"
            } else {
                events = eL.consolePrintable()
            }
        }
    }
}



class eventTableItem: NSObject {
    // A text description of this item for UITableView.
    var textLabel: String?
    
    // A Boolean value that determines the whether this control is active
    var active: Bool
    
    var amplitude : String?
    var timePt : String?
    var duration : String?
    var kOE : String?
    var SSD : String?
    var color : UIColor?
    //provides strings to display the event values
    
    init(e: Event) {
        active = true
        timePt = String (e.timePt)
        kOE = e.kindOfEntry.rawValue
        
        //might find nil during forced unwrap?
        if e.text != nil {
            textLabel = e.text
        } else {
            textLabel = ""
        }
    
        if e.fitSSD != nil {
            SSD = String (e.fitSSD!)
        } else {
            SSD = ""
        }
        
        if e.colorFitSSD != nil {
            color = e.colorFitSSD
        } else {
            color = UIColor.lightGray
        }
        
        
        if e.amplitude != nil  {
            amplitude = String (e.amplitude!)
            //print ("amp set")
        } else {
            amplitude = "-"
        }
 
        if e.duration != nil  {
            duration = String (e.duration!)
            //print ("duration set")
        } else {
            duration = "-"
        }
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

