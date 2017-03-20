//
//  Gaussian.swift
//  ISCAT
//
//  Created by Andrew on 03/03/2017.
//  Copyright © 2017 Andrew. All rights reserved.
//

import Foundation
import UIKit
import Accelerate

class GaussianFit {

    var filteredTopHat = [Float]()
    var kernel = [Float]()                  //the filter kernel
    
    init(filter: Float) {
        //filter is the filter corner frequency expressed as a fraction of the sample frequency (see Blue Book).
        kernel = dcGaussian(fc: filter)
    }

    func conv(x: [Float], k: [Float]) -> [Float] {
        let resultSize = x.count + k.count - 1
        var result = [Float](repeating: 0, count: resultSize)
        let kEnd = UnsafePointer<Float>(k).advanced(by: k.count - 1)
        let xPad: [Float] = [Float](repeating: 0.0, count: k.count-1)
        let xPadded = xPad + x + xPad
        vDSP_conv(xPadded, 1, kEnd, -1, &result, 1, vDSP_Length(resultSize), vDSP_Length(k.count))
        
        // result is bigger than input and I would prefer to slice out the input part...
        // not sure that it's any problem
        return result
    }
    
    func topHat (width: Int, height: Float) -> [Float] {
        let h = height
        let w = width
        return Array<Float>(repeating: h, count: w)
    }
    
    func gaussian (x: Float, a: Float, b: Float, c: Float) -> Float32 {
        // f(x) = a exp - [(x-b)^2 / 2c^2]
        return (a * exp (-pow(x-b, 2) / (2 * pow(c, 2))))
    }
    
    func dcGaussian (fc: Float) -> [Float] {
        //normalised digital Gaussian filter kernel - less than 0.5% error against Bessel
        
        let sigma = 0.132505 / fc           // equation A11 Chapter 19 Blue Book (Neher and Sakmann).
        let width = 2 * Int (4 * sigma)     // 2 * nc, Swift rounds down
        let k = [Int](0...width)            // zero bias in creation == +1
        let mu = Float(width) / 2.0
        let rawKernel : [Float] = k.map { k in gaussian (x: Float(k), a: 1, b: mu, c: sigma) }
        let sum = rawKernel.reduce(0, +)
        return rawKernel.map { kRaw in kRaw / sum }  //normalised coefficients to sum to one
    }

    /*
    typical values, now received from view controller and gesture:
    let firstTouch = CGPoint(x: 150, y:000)
    let currentTouch = CGPoint(x: 50, y:300)
    let window = CGPoint (x: 400.0, y: 400.0)
    */
    
    func buildGaussPath (pointsPSP: Float, firstTouch: CGPoint, currentTouch: CGPoint, window:CGPoint) -> CGPath {

        // **** window **** is not used
        // pointsPSP is the number of Screen points per data point - to keep filtering constant
        // float for maths later
        let leftExtreme = Float(min(firstTouch.x, currentTouch.x))
        let gWidth = (Float(max(firstTouch.x, currentTouch.x)) - leftExtreme) / pointsPSP
        let base = Float(firstTouch.y)
        let amp = Float(firstTouch.y - currentTouch.y)

        let iWidth = Int(gWidth)
        
        let topHatInput = topHat(width: iWidth, height: amp)
        filteredTopHat = conv(x: topHatInput, k: kernel)
        let xc = filteredTopHat.count
        let xf = Array(0...xc)
        let xfs = xf.map {x in Float(x) * pointsPSP}
        let gaussPath = UIBezierPath()

        let firstPoint = CGPoint (x: CGFloat(leftExtreme), y: CGFloat(base)) //draw left to right
        gaussPath.move(to: firstPoint)

        for (xp, yp) in zip(xfs, filteredTopHat) {
            let gaussPoint = CGPoint (x:Double(leftExtreme + xp), y:Double(base - yp))
            gaussPath.addLine(to: gaussPoint)
        }
        return gaussPath.cgPath
    }
    
    func buildGaussLayer (gPath: CGPath) -> CustomLayer {
        
        let gLayer = CustomLayer()
        //let bounds = gPath.boundingBoxOfPath
        gLayer.path = gPath
        //print (gLayer.bounds, bounds)
        //gLayer.bounds = bounds      //need to set bounds for detection later?
        //gLayer.position = CGPoint(x: bounds.width*0.5, y: bounds.height*0.5)
        gLayer.strokeColor = UIColor.red.cgColor //color later based on LSQ
        gLayer.fillColor = nil
        gLayer.lineWidth =  5
        return gLayer
    }
}

class CustomLayer: CAShapeLayer {
    var localID: Int?
  
}

func fitColor(worstSSD: Float, currentSSD: Float) -> UIColor {
    var current = currentSSD
    if current == 0 {current = 1.0}
    if current > worstSSD {current = worstSSD}
    let sensitivity : Float = 2.0           //typical value 2 or 3??
    
    var val = CGFloat( ( sensitivity * ( ( log(currentSSD) - log(worstSSD) ) / log(worstSSD) ) ) + 1.0)
    if val > 1.0 {val = 1.0}
    if val < 0.0 {val = 0.0}    //super safe - val must be between 0 and 1
    return UIColor(red: val, green: 1.0 - val, blue: 0.0, alpha: 1.0)
}

/*
 func createGaussianArray (mu: Float = 0.5) -> ([Float], [Float]) {
 //arbitrary choice of width.
 xf = x.map {x in Float(x) / 100}
 gaussArray = xf.map { xf in gaussian (x: xf, a: 1,b: mu,c: 10) }
 return (xf, gaussArray)
 }
 */
