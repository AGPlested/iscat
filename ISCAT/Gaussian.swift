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
    
    init() {
        //(xf, gaussArray) = createGaussianArray()
        kernel = dcGaussian(fc: 0.1)
    }

    
    func conv(x: [Float], k: [Float]) -> [Float] {
        let resultSize = x.count + k.count - 1
        var result = [Float](repeating: 0, count: resultSize)
        let kEnd = UnsafePointer<Float>(k).advanced(by: k.count - 1)
        let xPad: [Float] = [Float](repeating: 0.0, count: k.count-1)
        let xPadded = xPad + x + xPad
        vDSP_conv(xPadded, 1, kEnd, -1, &result, 1, vDSP_Length(resultSize), vDSP_Length(k.count))
        
        // result is bigger than input and I would prefer to slice out the input part...
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
        //normalised digital Gaussian filter  - less than 0.5% error against Bessel
        
        let sigma = 0.132505 / fc           //equation A11 Chapter 19 Blue Book (Neher and Sakmann).
        let width = 2 * Int (4 * sigma)  //2 * nc, Swift rounds down
        let k = [Int](0...width)        // zero bias in creation == +1
        let mu = Float(width) / 2.0
        let rawKernel : [Float] = k.map { k in gaussian (x: Float(k), a: 1, b: mu, c: sigma) }
        let sum = rawKernel.reduce(0,+)
        return rawKernel.map { kRaw in kRaw / sum }  //normalised coefficients to sum to one
    }

    /*
    func createGaussianArray (mu: Float = 0.5) -> ([Float], [Float]) {
        //makes two arrays: x points and Gaussian function
        
        xf = x.map {x in Float(x) / 100}
        gaussArray = xf.map { xf in gaussian (x: xf, a: 1,b: mu,c: 10) }

        return (xf, gaussArray)
    }
    */
    
    /*
    typical values, now received from view controller
    and gesture:
    let firstTouch = CGPoint(x: 150, y:000)
    let currentTouch = CGPoint(x: 50, y:300)
    let window = CGPoint (x: 400.0, y: 400.0)
    */
    
    func buildGaussPath (pointsPSP: Float, firstTouch: CGPoint, currentTouch: CGPoint, window:CGPoint) -> CGPath {

        // pointsPSP is the fraction of data points per Screen point - to keep filtering constant
        //float them for maths later
        let leftExtreme = Float(min(firstTouch.x, currentTouch.x))
        let gWidth = pointsPSP * (Float(max(firstTouch.x, currentTouch.x)) - leftExtreme)
        let base = Float(firstTouch.y)
        let amp = Float(firstTouch.y - currentTouch.y)

        let iWidth = Int(gWidth)
        
        let topHatInput = topHat(width: iWidth, height: amp)
        let filteredTopHat = conv(x: topHatInput, k: kernel)
        let xc = filteredTopHat.count
        let xf = Array(0...xc)
        //let cv = UIView(frame: CGRect(x: 0.0, y: 0.0, width: window.x, height: window.y))
        //cv.backgroundColor = UIColor.white

        let gaussPath = UIBezierPath()

        let firstPoint = CGPoint (x: CGFloat(leftExtreme), y: CGFloat(base)) //draw left to right, from
        gaussPath.move(to: firstPoint)

        for (xp, yp) in zip(xf, filteredTopHat) {
            
            let gaussPoint = CGPoint (x:Double(leftExtreme + Float(xp)), y:Double(base - yp))
            //print (xp,yp)
            //print (gaussPoint.x, gaussPoint.y)
            
            gaussPath.addLine(to: gaussPoint)
        }
        return gaussPath.cgPath
    }
    
    func buildGaussLayer (gPath: CGPath) -> CAShapeLayer {
        
        
        let gLayer = CAShapeLayer()
        gLayer.path = gPath
        gLayer.strokeColor = UIColor.green.cgColor
        gLayer.fillColor = nil
        gLayer.lineWidth =  3

        return gLayer
    }
}
//cv.layer.addSublayer(gLayer)  is what is done with that...
