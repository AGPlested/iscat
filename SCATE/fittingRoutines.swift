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
