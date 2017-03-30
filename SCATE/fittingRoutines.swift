//
//  fittingRoutines.swift
//  ISCAT
//
//  Created by Andrew on 28/03/2017.
//  Copyright © 2017 Andrew. All rights reserved.
//

import UIKit

//whilst pan is updating, make the new line
func pathOfFitLine(startPt: CGPoint, endPt: CGPoint) -> CGPath {
    let fitBezier = UIBezierPath()
    fitBezier.move(to: startPt)
    fitBezier.addLine(to: endPt)
    
    return fitBezier.cgPath
}

func checkIndices (left: Int, right: Int, leftEdge: Int = 0, rightEdge: Int) -> (Int, Int) {
    var legalLeft = leftEdge
    var legalRight = rightEdge
    let legalRange = leftEdge...rightEdge
    
    if legalRange.contains(left) {legalLeft = left}
    else if left > rightEdge {legalLeft = rightEdge}
    
    if legalRange.contains(right) {legalRight = right}
    else if right < leftEdge {legalRight = leftEdge}
    
    return (legalLeft, legalRight)
}


func getFittingDataSlice (firstTouch: CGPoint, currentTouch: CGPoint, viewPoints: [Int16], viewW: Float, kernelHalfWidth: Int) -> [Int16] {
    let leftTap = min (Float(firstTouch.x), Float(currentTouch.x))
    let rightTap = max (Float(firstTouch.x), Float(currentTouch.x))
    
    //normalizing by view width (viewW) removes the need to scale
    //indices are extended by the half-width of the Gaussian filtering kernel.
    //Zero if it's just a line.
    
    let dataPointsPerScreenPoint = Float(viewPoints.count) / viewW
    
    var leftIndex   = Int(Float(leftTap) * dataPointsPerScreenPoint) - kernelHalfWidth
    var rightIndex   = Int(Float(rightTap) * dataPointsPerScreenPoint) + kernelHalfWidth
    
    //check for edge here -protect against illegal indices
    
    (leftIndex, rightIndex) = checkIndices (left: leftIndex, right: rightIndex, leftEdge: 0, rightEdge: viewPoints.count)
    
    let fittingSlice = Array(viewPoints[leftIndex..<rightIndex])
    //shorter than the filtered top hat? Fixed?
    return fittingSlice
}

func getSliceDuringDrag (firstTouch: CGPoint, currentTouch: CGPoint, e: StoredEvent, viewPoints: [Int16], viewW: Float, kernelHalfWidth: Int) -> [Int16] {
    
    //event should be the original stored event from the start of the drag
    //not the one being updated on the fly
    let startDragX = Float(firstTouch.x)
    let currentDragX = Float(currentTouch.x)
    let pPSP = Float(viewPoints.count) / viewW
    
    let startTime = e.timePt
    let originalLeftIndex = Int(startTime * pPSP)       //no proper conversion here yet - stored values are in screen points.
    ///why is this getting crazy? still falling out sometimes and failing to update - giving negative indices
    let originalRightIndex = Int((startTime + e.duration!) * pPSP)      //no proper conversion here yet - stored values are in screen points.
    
    var brim = 0                                   //for the case of a line layer being dragged.
    
    //if we have a filtered event, need to add the auto-generated brim.
    if kernelHalfWidth != 0 {
        brim = Int(e.duration! * pPSP / 5)        //brim of the top hat function is 1/5 of its hat width. should really call back to original function to check this.
    }
    
    let shiftInDataPoints = Int((currentDragX - startDragX) * pPSP ) //will be +ve if drag is to the right, screen points scaled to data points
    print ("sIDP, pPSP, brim, kHW, OLI, ORI", shiftInDataPoints, pPSP , brim, kernelHalfWidth, originalLeftIndex, originalRightIndex)
    var leftIndex   = originalLeftIndex + shiftInDataPoints - brim - kernelHalfWidth
    var rightIndex  = originalRightIndex + shiftInDataPoints + brim + kernelHalfWidth
    
    //check for edge here -protect against illegal indices
    (leftIndex, rightIndex) = checkIndices (left: leftIndex, right: rightIndex, leftEdge: 0, rightEdge: viewPoints.count)
    
    print ("lIndex, rIndex: ", leftIndex, rightIndex)
    let slice = Array(viewPoints[leftIndex..<rightIndex])
    //shorter than the filtered top hat? Fixed?
    return slice
    
}



func calculateSSD (A: [Float], B:[Float]) -> Float {
    //doesn't fail if arrays are different lengths
    var ssd :Float = 0.0
    for (e, f)  in zip (A, B) {
        ssd += pow ((e - f), 2)
    }
    //print ("\(ssd)")
    return ssd
}

func optimiseFit() -> [Int]{
    print ("Fitting subroutine")
    return [0]
}

//called when user starts a pan
func createHorizontalLine (startTap: CGPoint!, endTap: CGPoint!) -> CustomLayer {
    
    print ("Drawing sojourn line:", startTap!, endTap!)
    //rough conversion of y value
    let averageY = (startTap.y + endTap.y) / 2
    
    let startPoint = CGPoint(x: (startTap.x), y: averageY)
    let endPoint = CGPoint(x: (endTap.x), y: averageY)
    
    let thickness: CGFloat = 5.0
    
    let fitLayer = CustomLayer()        //subclass of CAShapeLayer with ID
    let fitLinePath = pathOfFitLine(startPt: startPoint, endPt: endPoint)
    
    fitLayer.path = fitLinePath
    
    
    fitLayer.strokeColor = UIColor.red.cgColor
    fitLayer.fillColor = nil
    fitLayer.lineWidth = thickness
    return fitLayer
}

class CustomLayer: CAShapeLayer {
    var localID: Int?
    var drawnPathPoints = [CGPoint]() ///Needs to be stored each time!
    var outlinePath = CGMutablePath()
}

func fitColor(worstSSD: Float, currentSSD: Float) -> UIColor {
    var current = currentSSD
    if current == 0 {current = 1.0}
    if current > worstSSD {current = worstSSD}
    let sensitivity : Float = 1.5           //typical value 2 or 3??
    
    var val = CGFloat( ( sensitivity * ( ( log(currentSSD) - log(worstSSD) ) / log(worstSSD) ) ) + 1.0)
    if val > 1.0 {val = 1.0}
    if val < 0.0 {val = 0.0}    //super safe - val must be between 0 and 1
    return UIColor(red: val, green: 1.0 - val, blue: 0.0, alpha: 1.0)
}
