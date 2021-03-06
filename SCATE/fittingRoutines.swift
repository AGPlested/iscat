//
//  fittingRoutines.swift
//  ISCAT
//
//  Created by Andrew on 28/03/2017.
//  Copyright © 2017 Andrew. All rights reserved.
//

import UIKit

enum PanGestures: String {
    case horizontalPan, verticalPan, downDiag, upDiag, notResolved
}


func fitTraceView(FitView: UIView, viewWidth: CGFloat, pointsToFit: [Int16], yOffset: CGFloat, traceHeight: CGFloat) {
    //draw a fixed data trace on the screen
    
    let screenPointsPerDataPoint = Float(viewWidth) / Float(pointsToFit.count)    //900
    print ("traceview: pointsTF, sPPDP", pointsToFit.count, screenPointsPerDataPoint)
    
    let firstDataPoint = CGPoint(x:0, y:yOffset)
    var drawnDataPoint : CGPoint
    
    FitView.backgroundColor = UIColor.white
    FitView.translatesAutoresizingMaskIntoConstraints = false
    
    //drawing trace
    let thickness: CGFloat = 2.0
    let tracePath = UIBezierPath()
    tracePath.move(to: firstDataPoint)
    
    for (index, point) in pointsToFit.enumerated() {
        let xPoint = CGFloat ( screenPointsPerDataPoint * Float (index) )
        drawnDataPoint = CGPoint(x: xPoint, y: yOffset + traceHeight * CGFloat(point) / 32536.0)
        tracePath.addLine(to: drawnDataPoint)
    }
    
    // render to layer
    let traceLayer = CAShapeLayer()
    traceLayer.path = tracePath.cgPath
    traceLayer.lineJoin = kCALineJoinRound
    traceLayer.strokeColor = UIColor.black.cgColor
    traceLayer.fillColor = nil
    traceLayer.lineWidth = thickness
    FitView.layer.addSublayer(traceLayer)

    return
}

//whilst pan is updating, make the new line
func pathOfFitLine(startPt: CGPoint, endPt: CGPoint) -> CGPath {
    let fitBezier = UIBezierPath()
    fitBezier.move(to: startPt)
    fitBezier.addLine(to: endPt)
    
    return fitBezier.cgPath
}

func extendLineFit(locationOfBeganTap: CGPoint, currentLocationOfTap: CGPoint, pointsToFit: [Int16], viewWidth: CGFloat, yPlotOffset: CGFloat, traceHeight: CGFloat, fitLine: CustomLayer , fitEventToStore: Event ){

    let screenPointsPerDataPoint = Float(viewWidth) / Float(pointsToFit.count)
    //allow the user to correct the Y-position whilst extending (line remains horizontal)
    let averageY = (locationOfBeganTap.y + currentLocationOfTap.y) / 2
    let startPoint = CGPoint(x: (locationOfBeganTap.x)  , y: averageY)
    let endPoint = CGPoint(x: (currentLocationOfTap.x) , y: averageY)

    //no filter so no kernel
    let targetDataPoints = getSliceExtending(firstTouch: locationOfBeganTap, currentTouch: currentLocationOfTap, viewPoints: pointsToFit, viewW: Float(viewWidth), kernelWidth: 0)
    let target : [Float] = targetDataPoints.map { t in Float(yPlotOffset + traceHeight * CGFloat(t) / 32536.0 )} //to get screen point amplitudes

    // produce an array of screen points representing the fitting Line.
    let SSD_size = target.count
    let fitLineArray = Array(repeating: Float(averageY), count: SSD_size)
    let xf = Array(0...SSD_size)
    //ugly. This logic is performed in the getDataFittingSlice too.
    let xfs = xf.map {x in Float(x) * screenPointsPerDataPoint + Float(min(locationOfBeganTap.x, currentLocationOfTap.x))}

    //store these points in the CustomLayer data structure for the next iteration
    var drawnPath = [CGPoint]()
    for (xp, yp) in zip (xfs, fitLineArray) {
        let fitLinePoint = CGPoint (x: CGFloat(xp), y: CGFloat(yp))
        drawnPath.append(fitLinePoint)
    }
    fitLine.drawnPathPoints = drawnPath

    let normalisedSSD = calculateSSD (A: fitLineArray, B: target) / Float(SSD_size)
    // bad fit is red, good fit is green
    let color = fitColor(worstSSD : 1e6, currentSSD: normalisedSSD)
    //print (normalisedSSD, color)
    fitEventToStore.fitSSD = normalisedSSD
    fitEventToStore.colorFitSSD = color

    //no animations
    //https://github.com/iamdoron/panABallAttachedToALine/blob/master/panLineRotation/ViewController.swift
    CATransaction.begin()
    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
    fitLine.path = pathOfFitLine(startPt: startPoint, endPt: endPoint)
    fitLine.strokeColor = color.cgColor
    CATransaction.commit()

    //make a copy of the current line with thick path for touch detection later
    fitLine.outlinePath = fitLine.path!.copy(strokingWithWidth: 50,
                                             lineCap: CGLineCap(rawValue: 0)!,
                                             lineJoin: CGLineJoin(rawValue: 0)!,
                                             miterLimit: 1) as! CGMutablePath
}


func extendStepEvent(locationOfBeganTap: CGPoint, currentLocationOfTap: CGPoint, pointsToFit: [Int16], viewWidth: CGFloat, yPlotOffset: CGFloat, traceHeight: CGFloat, gfit: GaussianFit, gaussianLayer: CustomLayer, fitEventToStore: Event ) {
    let gaussianKernelWidth = gfit.kernel.count
    
    let  screenPointsPerDataPoint = Float(viewWidth) / Float(pointsToFit.count)
    
    //get the step slice using the width of the filtered step?
    let targetDataPoints = getSliceExtendingTransition(firstTouch: locationOfBeganTap, currentTouch: currentLocationOfTap, viewPoints: pointsToFit, viewW: Float(viewWidth), kernelWidth: gaussianKernelWidth)
    
    let lastDrawnFilteredStep = gfit.filteredStep
    let screenStep = lastDrawnFilteredStep.map {th in Float(locationOfBeganTap.y) - th}
    
    let target : [Float] = targetDataPoints.map { t in Float(yPlotOffset + traceHeight * CGFloat(t) / 32536.0 )} //to get screen point amplitudes
    
    print (screenStep.count, target.count) //should really assert here and make a fatal error if arrays are not the same size
    
    let SSD_size = Float(target.count)
    let normalisedSSD = calculateSSD (A: screenStep, B: target) / SSD_size
    // bad fit is red, good fit is green
    let color = fitColor(worstSSD : 1e6, currentSSD: normalisedSSD)
    print (normalisedSSD, color)
    fitEventToStore.fitSSD = normalisedSSD
    fitEventToStore.colorFitSSD = color
    
    // write out SSD and event length (in samples - convert easily later).
    
    // draw the latest curve, colored to previous SSD.
    CATransaction.begin()
    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
    gaussianLayer.path = gfit.buildGaussStepPath(screenPPDP: screenPointsPerDataPoint, firstTouch: locationOfBeganTap, currentTouch: currentLocationOfTap)
    gaussianLayer.drawnPathPoints = gfit.drawnPath
    gaussianLayer.strokeColor = color.cgColor
    CATransaction.commit()
    
    //will be checked for hits
    gaussianLayer.outlinePath = gaussianLayer.path!.copy(strokingWithWidth: 60,
                                                         lineCap: CGLineCap(rawValue: 0)!,
                                                         lineJoin: CGLineJoin(rawValue: 0)!,
                                                         miterLimit: 1) as! CGMutablePath
    return
}

func extendTopHatEvent(locationOfBeganTap: CGPoint, currentLocationOfTap: CGPoint, pointsToFit: [Int16], viewWidth: CGFloat, yPlotOffset: CGFloat, traceHeight: CGFloat, gfit: GaussianFit, gaussianLayer: CustomLayer , fitEventToStore: Event   ) {
    let gaussianKernelWidth = gfit.kernel.count
    
    let  screenPointsPerDataPoint = Float(viewWidth) / Float(pointsToFit.count)
    
    //why not just take the slice to be the width of the last filteredTopHat?
    
    let targetDataPoints = getSliceExtending(firstTouch: locationOfBeganTap, currentTouch: currentLocationOfTap, viewPoints: pointsToFit, viewW: Float(viewWidth), kernelWidth: gaussianKernelWidth)
    
    let lastDrawnFilteredTopHat = gfit.filteredTopHat
    let screenTopHat = lastDrawnFilteredTopHat.map {th in Float(locationOfBeganTap.y) - th}
    
    let target : [Float] = targetDataPoints.map { t in Float(yPlotOffset + traceHeight * CGFloat(t) / 32536.0 )} //to get screen point amplitudes
    
    let SSD_size = Float(target.count)
    let normalisedSSD = calculateSSD (A: screenTopHat, B: target) / SSD_size
    // bad fit is red, good fit is green
    let color = fitColor(worstSSD : 1e6, currentSSD: normalisedSSD)
    print (normalisedSSD, color)
    fitEventToStore.fitSSD = normalisedSSD
    fitEventToStore.colorFitSSD = color
    
    // write out SSD and event length (in samples - convert easily later).
    
    // draw the latest curve, colored to previous SSD.
    CATransaction.begin()
    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
    gaussianLayer.path = gfit.buildTopHatGaussPath(screenPPDP: screenPointsPerDataPoint, firstTouch: locationOfBeganTap, currentTouch: currentLocationOfTap)
    gaussianLayer.drawnPathPoints = gfit.drawnPath
    gaussianLayer.strokeColor = color.cgColor
    CATransaction.commit()
    
    //will be checked for hits
    gaussianLayer.outlinePath = gaussianLayer.path!.copy(strokingWithWidth: 60,
                                                         lineCap: CGLineCap(rawValue: 0)!,
                                                         lineJoin: CGLineJoin(rawValue: 0)!,
                                                         miterLimit: 1) as! CGMutablePath
    return
}


func didEscapePanDecisionLimit (first: CGPoint, current: CGPoint, radius: Float) -> Bool {
    
    let dx = Float(first.x - current.x)
    let dy = Float(first.y - current.y)
    let distanceFromFirstTouch = pow((pow(dx, 2) + pow(dy,2)),0.5)
    print (dx, dy, distanceFromFirstTouch, radius)
    guard distanceFromFirstTouch < radius else {return true}
    return false
}

//wrapper for the panArcGesture decision logic, to give back right event
func panArcEntry (first: CGPoint, current: CGPoint, arc: Float, openingsDown: Bool) -> (Entries) {
    var e : Entries = .unclassified
    let g = panArcGesture(first: first, current: current, arc: arc)
    
    switch g {
        case .downDiag: if openingsDown {e = .opening} else {e = .shutting}
             //downward movement on screen
            
        case .upDiag: if openingsDown {e = .shutting} else {e = .opening}
            //upward movement on screen
            
        case .horizontalPan: e = .sojourn
            
        case .verticalPan: e = .transition
            
        default: print ("not resolved therefore event not classified")
    }
    print ("pan Arc entry", g, e)
    return e
}


func panArcGesture (first: CGPoint, current: CGPoint, arc: Float) -> (PanGestures) {
    //arc is the fraction of Pi/4
    var g : PanGestures = .notResolved
    let dx = Float(current.x - first.x)
    let dy = Float(current.y - first.y)
    
    let angle = abs(atan(dy / dx))
    
    let topHatArcLowBound = Float(.pi / 4.0 * ( 1 - arc ))
    let topHatArcHighBound = Float (.pi / 4.0 * ( 1 + arc ))
    
    if dy > 0 {
        g = .downDiag
    } else if dy < 0 {
        g = .upDiag
    }
    
    if angle < topHatArcLowBound {
        g = .horizontalPan
    } else if angle > topHatArcHighBound {
        g = .verticalPan
    }
   
    print ("panArcGesture", g)
    return g
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


func getSliceExtending (firstTouch: CGPoint, currentTouch: CGPoint, viewPoints: [Int16], viewW: Float, kernelWidth: Int) -> [Int16] {
    
    //indices are extended by the width of the Gaussian filtering kernel.
    //Zero if it's just a line.
    //let ears = Int(kernelHalfWidth * 2)
    
    //the event we are extending has some width based on the x-position of the initial and current touches
    let leftTap = min (Float(firstTouch.x), Float(currentTouch.x))
    let rightTap = max (Float(firstTouch.x), Float(currentTouch.x))
    
    //normalizing by view width (viewW) removes the need to scale
    let dataPointsPerScreenPoint = Float(viewPoints.count) / viewW
    
    var leftIndex   = Int(Float(leftTap) * dataPointsPerScreenPoint) - kernelWidth
    var rightIndex   = Int(Float(rightTap) * dataPointsPerScreenPoint) + kernelWidth
    
    //check for edge here -protect against illegal indices
    (leftIndex, rightIndex) = checkIndices (left: leftIndex, right: rightIndex, leftEdge: 0, rightEdge: viewPoints.count)
    
    let fittingSlice = Array(viewPoints[leftIndex..<rightIndex])
    return fittingSlice
}

 
func getSliceExtendingTransition (firstTouch: CGPoint, currentTouch: CGPoint, viewPoints: [Int16], viewW: Float, kernelWidth: Int) -> [Int16] {

    //normalizing by view width (viewW) removes the need to scale
    let dataPointsPerScreenPoint = Float(viewPoints.count) / viewW
    
    //let ears = kernelHalfWidth * 2
    
    //indices are extended by the width of the Gaussian filtering kernel in each direction.
    var leftIndex   = Int(Float(firstTouch.x) * dataPointsPerScreenPoint) - kernelWidth
    var rightIndex   = Int(Float(firstTouch.x) * dataPointsPerScreenPoint) + kernelWidth
    
    //check for edge here -protect against illegal indices
    (leftIndex, rightIndex) = checkIndices (left: leftIndex, right: rightIndex, leftEdge: 0, rightEdge: viewPoints.count)
    
    let fittingSlice = Array(viewPoints[leftIndex..<rightIndex])
    return fittingSlice
}

func getSliceDuringDrag (firstTouch: CGPoint, currentTouch: CGPoint, e: StoredEvent, viewPoints: [Int16], viewW: Float, kernelWidth: Int) -> [Int16] {
    //slice refers to the raw data used for live SSD comparison
    
    //x is all that matters for getting data slice dragging
    let startDragX = Float(firstTouch.x)
    let currentDragX = Float(currentTouch.x)
    let pPSP = Float(viewPoints.count) / viewW
    let shiftInDataPoints = Int((currentDragX - startDragX) * pPSP ) //will be +ve if drag is to the right, screen points scaled to data points
    
    //stored values from the original event are in local screen points.
    let startTime = e.timePt
    let originalLeftIndex = Int(startTime * pPSP)
    let originalRightIndex = Int((startTime + e.duration!) * pPSP)
    
    //default for the case of a line layer being dragged.
    var brim = 0
    
    //if we have a filtered event, need to add the filter kernel brim.
    if kernelWidth != 0 {
        brim = kernelWidth
    }
    
    print ("sIDP, pPSP, brim, kW, OLI, ORI", shiftInDataPoints, pPSP , brim, kernelWidth, originalLeftIndex, originalRightIndex)
    
    var leftIndex   = originalLeftIndex + shiftInDataPoints - brim
    var rightIndex  = originalRightIndex + shiftInDataPoints + brim 
    
    //check for edge here -protect against illegal indices
    (leftIndex, rightIndex) = checkIndices (left: leftIndex, right: rightIndex, leftEdge: 0, rightEdge: viewPoints.count)
    
    //print ("lIndex, rIndex: ", leftIndex, rightIndex)
    let slice = Array(viewPoints[leftIndex..<rightIndex])
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

//called when user starts a horizontal pan gesture
func createHorizontalLine (startTap: CGPoint!, endTap: CGPoint!) -> CustomLayer {
    
    print ("Drawing sojourn line:", startTap!, endTap!)
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

/*
 //check for snapping
 
 //if snapping {
 //  originLevel = nearestLevel(originPoint.y)
 //  currentLevel = nearestLevel(currentPoint.y)
 //}
 //else
 //{
 
 //if currentPoint.y < originPoint.y {
 //    **downward
 //    currentLevel.y = currentPoint.y
 //    originLevel.y = originPoint.y
 //    let size.y = ///PIXELS!!! depends on zoom need to think about real units
 
 // }
 //else {
 //     leftExtent.x = originPoint.x
 //     rightExtent.x = currentPoint.x
 //}
 */
