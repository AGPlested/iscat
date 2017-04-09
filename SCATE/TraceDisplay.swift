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
    let thickness : CGFloat = 30
    
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

class completionView: UIView {
    
    var yPosition : CGFloat?
    var eventsToDraw = [Event]()
    var samplesPerMillisecond : Float?
    
    func getSegments() -> [Segment] {
        var segments = [Segment]()
        for event in eventsToDraw {
            let start = CGFloat(event.timePt * samplesPerMillisecond!)
            let end = CGFloat((event.timePt + event.duration!) * samplesPerMillisecond!)
            let color = event.colorFitSSD!
            let seg = Segment (start: start, end: end, color: color)
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
        let segmentStart = CGPoint(x: seg.start, y: yPos)
        let segmentEnd = CGPoint(x: seg.end, y: yPos)
        segmentPath.move(to: segmentStart)
        segmentPath.addLine(to: segmentEnd)
        
        // render to layer
        let segmentLayer = CAShapeLayer()
        segmentLayer.path = segmentPath.cgPath
        //segmentLayer.lineJoin = kCALineJoinRound
        
        segmentLayer.strokeColor = seg.color.cgColor
        
        segmentLayer.fillColor = nil
        segmentLayer.lineWidth = seg.thickness
        
        return segmentLayer
    }
    
    func updateSegments (eventL: eventList, y: Float, samplePerMs: Float) {

        yPosition = CGFloat(y)
        samplesPerMillisecond = samplePerMs
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
                case .opening, .shutting, .transition, .sojourn :
                    eventsToDraw.append (event)
         
                default :
                    print ("skipped", event)
         
            }
        }
        collectSegmentLayers()
    }
}



