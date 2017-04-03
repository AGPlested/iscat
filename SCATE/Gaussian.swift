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

    var drawnPath = [CGPoint]()
    var filteredTopHat = [Float]()
    var filteredStep = [Float]()
    var kernel = [Float]()                  //the filter kernel
    
    init(filter: Float) {
        //filter is the filter corner frequency expressed 
        //as a fraction of the sample frequency (see Blue Book).
        kernel = dcGaussian(fc: filter)
    }

    func filterConvolution(x: [Float], k: [Float]) -> [Float] {
        //nice fast convolution using Accelerate
        let resultSize = x.count + k.count - 1
        var result = [Float](repeating: 0, count: resultSize)
        let kEnd = UnsafePointer<Float>(k).advanced(by: k.count - 1)
        let xPad: [Float] = [Float](repeating: 0.0, count: k.count-1)
        let xPadded = xPad + x + xPad
        vDSP_conv(xPadded, 1, kEnd, -1, &result, 1, vDSP_Length(resultSize), vDSP_Length(k.count))
        return result
    }
    
    func step (height: Float, back: Bool) -> [Float] {
        //let h = height
        //with these strange parameters, the dragged out step looks good.
        let ears = max ((Int(pow (abs(height), 0.7))), 25) //always draw something, even at small heights
        print ("ears \(ears)")
        let stepTo = Array<Float>(repeating: height, count: ears)
        let stepBase = Array<Float>(repeating: 0, count: ears)
        
        if back == true {
            return stepTo + stepBase
        } else {
            return stepBase + stepTo
        }
    }
    
    func topHat (width: Int, height: Float) -> [Float] {
        let h = height
        let w = width
        let brimW = Int(width / 5)
        
        var hat = Array<Float>(repeating: h, count: w)
        if brimW > 0 {
            let brim = Array<Float>(repeating: 0.0, count: brimW)
            hat = brim + hat + brim
        }
        return hat
    }
    
    func gaussian (x: Float, a: Float, b: Float, c: Float) -> Float32 {
        // f(x) = a exp - [(x-b)^2 / 2c^2]
        return (a * exp (-pow(x-b, 2) / (2 * pow(c, 2))))
    }
    
    func dcGaussian (fc: Float) -> [Float] {
        //normalised digital Gaussian filter kernel - less than 0.5% error against Bessel
        
        let sigma = 0.132505 / fc           // equation A11 Chapter 19 Blue Book (Neher and Sakmann).
        let width = 2 * Int (4 * sigma)     // 2 * nc, Swift rounds down
        let k = [Int](0...width)            // zero bias in creation => +1
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
    
    func buildGaussStepPath (screenPPDP: Float, firstTouch: CGPoint, currentTouch: CGPoint) -> CGPath {
        
        // screenPPDP is the number of screen points per data point - to keep filtering constant
        // float for maths later
        let position = Float(firstTouch.x)
        let base = Float(firstTouch.y)
        let amp = Float(firstTouch.y - currentTouch.y)
        var back = false

        if firstTouch.x > currentTouch.x {
            back = true
        }
        
        let stepInput = step(height: amp, back: back)
        
        filteredStep = filterConvolution(x: stepInput, k: kernel)
        
        //trim step
        //var filteredStepTrimmed = [Float]()
        
        //narrow step default
        var leftTrimPoint = Int(Float(filteredStep.count) * 0.4)
        var rightTrimPoint = Int(Float(filteredStep.count) * 0.6)
        
        //wide step limit (adding a couple of points beyond the kernel
        if filteredStep.count > 2 * kernel.count {
            leftTrimPoint = filteredStep.count / 2 - kernel.count / 2 - 10
            rightTrimPoint = filteredStep.count / 2 + kernel.count / 2 + 10
        }
        
        let filteredStepTrimmed = filteredStep[leftTrimPoint...rightTrimPoint]
        
        let fringe =  Float(filteredStepTrimmed.count) * screenPPDP / 2
        //need to move drawn curve left in x by this much^^^ way too much
        let xc = filteredStepTrimmed.count
        let xf = Array(0...xc)
        let xfs = xf.map {x in Float(x) * screenPPDP}
        let gaussPath = UIBezierPath()
        
        let firstPoint = CGPoint (x: CGFloat(position - fringe), y: CGFloat(base))
        //draw left to right
        gaussPath.move(to: firstPoint)
        
        drawnPath = []
        for (xp, yp) in zip(xfs, filteredStepTrimmed) {
            let gaussPoint = CGPoint (x:Double(position - fringe + xp), y:Double(base - yp))
            gaussPath.addLine(to: gaussPoint)
            drawnPath.append(gaussPoint)
        }
        
        print ("drawnPath", drawnPath)
        return gaussPath.cgPath
    }
    
    
    func buildGaussPath (screenPPDP: Float, firstTouch: CGPoint, currentTouch: CGPoint) -> CGPath {

        // screenPPDP is the number of screen points per data point - to keep filtering constant
        // float for maths later
        let leftExtreme = Float(min(firstTouch.x, currentTouch.x))
        let gWidth = (Float(max(firstTouch.x, currentTouch.x)) - leftExtreme) / screenPPDP
        let base = Float(firstTouch.y)
        let amp = Float(firstTouch.y - currentTouch.y)

        let iWidth = Int(gWidth)        //in data points
        let topHatInput = topHat(width: iWidth, height: amp)
        
        filteredTopHat = filterConvolution(x: topHatInput, k: kernel)
        
        let fringe =  Float(filteredTopHat.count - iWidth) * screenPPDP / 2
        //need to move drawn curve left in x by this much.
        let xc = filteredTopHat.count
        let xf = Array(0...xc)
        let xfs = xf.map {x in Float(x) * screenPPDP}
        let gaussPath = UIBezierPath()

        let firstPoint = CGPoint (x: CGFloat(leftExtreme - fringe), y: CGFloat(base))
        //draw left to right
        gaussPath.move(to: firstPoint)
        
        drawnPath = []
        for (xp, yp) in zip(xfs, filteredTopHat) {
            let gaussPoint = CGPoint (x:Double(leftExtreme - fringe + xp), y:Double(base - yp))
            gaussPath.addLine(to: gaussPoint)
            drawnPath.append(gaussPoint)
        }
        
        //print ("drawnPath", drawnPath)
        return gaussPath.cgPath
    }
    
    func buildGaussLayer (gPath: CGPath) -> CustomLayer {
        
        let gLayer = CustomLayer()
        gLayer.path = gPath
        gLayer.outlinePath = gPath.copy(strokingWithWidth: 15,
                            lineCap: CGLineCap(rawValue: 0)!,
                            lineJoin: CGLineJoin(rawValue: 0)!,
                            miterLimit: 1) as! CGMutablePath
        
        gLayer.drawnPathPoints = drawnPath
        //rearrange to perform these actions more consistently?
        //print ("glayer", gLayer.drawnPathPoints)
        gLayer.strokeColor = UIColor.red.cgColor //color later based on LSQ
        gLayer.fillColor = nil
        gLayer.lineWidth =  5
        return gLayer
    }
}




