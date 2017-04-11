//
//  TraceDisplay.swift
//  ISCAT
//
//  Created by Andrew on 30/07/2016.
//  Copyright © 2016 Andrew. All rights reserved.
//

import UIKit

struct Segment {
    var start : CGFloat
    var end : CGFloat
    var color : UIColor
    var kindOfEvent : Entries
    let thickness : CGFloat = 5
    
}

class TraceDisplay: UIView {
    
    var compression : CGFloat = 0.5 {
        didSet {
            setNeedsDisplay()
            print("set")
        }
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
    }
    */

}

// make classes for the x and y axes here, so they can be zoomed independently!


class completionView: UIView {
    
    var yPosition : CGFloat?
    var eventsToDraw = [Event]()
    var screenPtsPerMs : Float?
    var tOffset : Float?                     //in case we are using in a fixed view
    
    func getSegments() -> [Segment] {
        var segments = [Segment]()
        print ("offset:", tOffset!)
        for event in eventsToDraw {
            let start = CGFloat((event.timePt - tOffset!) * screenPtsPerMs!)
            let end = CGFloat((event.timePt + event.duration! - tOffset!) * screenPtsPerMs!)
            let color = event.colorFitSSD!
            let kind = event.kindOfEntry
            let seg = Segment (start: start, end: end, color: color, kindOfEvent: kind)
            print ("start, end: ", start, end)
            segments.append(seg)
        }
    return segments
    }

    
    func collectSegmentLayers () {
        for segment in getSegments() {
            let segmentLayer = drawSegmentLayer (seg: segment, yPos: yPosition!)
            self.layer.addSublayer (segmentLayer)
        }
    }
    
    //each segment could be a different color so need a layer for each
    func drawSegmentLayer (seg: Segment, yPos: CGFloat) -> CAShapeLayer {
    
        //drawing segment
        let segmentPath = UIBezierPath()
        var segmentStart = CGPoint(x: seg.start, y: yPos)
        var segmentEnd = CGPoint(x: seg.end, y: yPos)
        var thickness = seg.thickness                   //modulate on event type
        var segColor = seg.color                        //modulate on event type

        
        switch seg.kindOfEvent {
            case .transition :
                segmentPath.addArc(withCenter: segmentStart, radius: 8, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true) //radians
                thickness = 2
            
            case .opening :
                segmentPath.addArc(withCenter: segmentStart, radius: 8, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true) //radians
                segmentPath.move(to: CGPoint(x: segmentEnd.x + 8, y: segmentEnd.y)) //avoid drawing little radius
                segmentPath.addArc(withCenter: segmentEnd, radius: 8, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true) //radians
                thickness = 2
                segmentStart.y += 8
                segmentEnd.y += 8
                segmentPath.move(to: segmentStart)
                segmentPath.addLine(to: segmentEnd)
            
            case .shutting :
                segmentPath.addArc(withCenter: segmentStart, radius: 8, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true) //radians
                segmentPath.move(to: CGPoint(x: segmentEnd.x + 8, y: segmentEnd.y)) //avoid drawing little radius
                segmentPath.addArc(withCenter: segmentEnd, radius: 8, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true) //radians
                thickness = 2
                segmentStart.y -= 8
                segmentEnd.y -= 8
                segmentPath.move(to: segmentStart)
                segmentPath.addLine(to: segmentEnd)

            case .mark:
                let markTop = CGPoint(x: segmentStart.x, y: segmentStart.y - 10)
                let markBottom = CGPoint(x: segmentStart.x, y: segmentStart.y + 10)
                segmentPath.move(to: markTop)
                segmentPath.addLine(to: markBottom)
                segColor = UIColor.blue
                thickness = 8
            
            default :           //for sojourns
                segmentPath.move(to: segmentStart)
                segmentPath.addLine(to: segmentEnd)
        }
        
        // render to layer
        let segmentLayer = CAShapeLayer()
        segmentLayer.path = segmentPath.cgPath
        //segmentLayer.lineJoin = kCALineJoinRound
        
        segmentLayer.strokeColor = segColor.cgColor
        
        segmentLayer.fillColor = nil
        segmentLayer.lineWidth = thickness
        
        return segmentLayer
    }
    
    func updateSegments (eventL: eventList, y: Float, samplePerMs: Float, offset: Float) {
        tOffset = offset
        yPosition = CGFloat(y)
        screenPtsPerMs = samplePerMs
        //clean out
        eventsToDraw = []
        
        if self.layer.sublayers != nil {
            for segLayer in self.layer.sublayers! {
                print ("removing seglayer", segLayer)
                segLayer.removeFromSuperlayer()
            }
        }
        
        let allEvents = eventL.list
        
        for event in allEvents {
            switch event.kindOfEntry {
                case .opening, .shutting, .transition, .sojourn, .mark :
                    eventsToDraw.append (event)
         
                default :
                    print ("skipped", event)
         
            }
        }
        collectSegmentLayers()
    }
}



