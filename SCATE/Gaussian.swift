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
        //with these strange parameters, the dragged out step looks good.
        //but only because the gaussian kernel is a certain width
        //let ears = max ((Int(pow (abs(height), 0.7))), kernel.count)
        let ears  = kernel.count * 2
        //print ("step ears \(ears)")
        let stepTo = Array<Float>(repeating: height, count: ears)
        let stepBase = Array<Float>(repeating: 0, count: ears)
        
        if back == true {
            return stepTo + stepBase
        } else {
            return stepBase + stepTo
        }
    }
    
    func topHat (width: Int, height: Float) -> [Float] {
        let brimW = max ((Int(pow (abs(height), 0.7))), kernel.count) //always draw something, even at small heights
        let hat = Array<Float>(repeating: height, count: width)
        let brim = Array<Float>(repeating: 0.0, count: brimW)
        return brim + hat + brim
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
        
        // need to unify, and clarify.
        //this trimming should also be applied for the top hat
        
        //narrow step default
        //this never happens any more? 
        var leftTrimPoint = Int(Float(filteredStep.count) * 0.4)
        var rightTrimPoint = Int(Float(filteredStep.count) * 0.6)
        
        //wide step limit
        //centred on filtered step, adding a window of a filter kernel each way
        if filteredStep.count > 2 * kernel.count {
            leftTrimPoint = filteredStep.count  / 2 - kernel.count
            rightTrimPoint = filteredStep.count / 2 + kernel.count
        }
        
        filteredStep = Array(filteredStep[leftTrimPoint..<rightTrimPoint])
        
        let fringe =  Float(filteredStep.count) * screenPPDP / 2
        //need to move drawn curve left in x by this much
        let xc = filteredStep.count
        let xf = Array(0...xc)
        let xfs = xf.map {x in Float(x) * screenPPDP} //could subtract fringe here
        let gaussPath = UIBezierPath()
        
        //draw left to right
        var firstPoint = CGPoint()
        
        if back == true {
            // if it's a right to left pan, drawing left to right means
            // drawing from the end to the beginning - in terms of y...
            // otherwise we draw |/ or |\ rather than just / or \
            
            firstPoint = CGPoint (x: CGFloat(position - fringe), y: CGFloat(base - amp))
        } else {
            firstPoint = CGPoint (x: CGFloat(position - fringe), y: CGFloat(base))
        }
        
        gaussPath.move(to: firstPoint)
        
        drawnPath = []
        for (xp, yp) in zip(xfs, filteredStep) {
            let gaussPoint = CGPoint (x:Double(position - fringe + xp), y:Double(base - yp))
            gaussPath.addLine(to: gaussPoint)
            drawnPath.append(gaussPoint)
        }
        
        //print ("drawnPath", drawnPath)
        return gaussPath.cgPath
    }
    
    //why not unify this path parameterisation with above and pull out path construction?
    func buildTopHatGaussPath (screenPPDP: Float, firstTouch: CGPoint, currentTouch: CGPoint) -> CGPath {

        // screenPPDP is the number of screen points per data point - to keep filtering constant
        // float for maths later
        let leftExtreme = Float(min(firstTouch.x, currentTouch.x))
        let gWidth = (Float(max(firstTouch.x, currentTouch.x)) - leftExtreme) / screenPPDP
        let base = Float(firstTouch.y)
        let amp = Float(firstTouch.y - currentTouch.y)

        let iWidth = Int(gWidth)        //in data points
        let topHatInput = topHat(width: iWidth, height: amp)
        
        filteredTopHat = filterConvolution(x: topHatInput, k: kernel)
        
        //this trimming should also be applied for the top hat
        
        //narrow top hat default
        var leftTrimPoint = Int(Float(filteredTopHat.count) * 0.4)
        var rightTrimPoint = Int(Float(filteredTopHat.count) * 0.6)
        
        //wide top hat limit
        //centred on filtered top hat, adding a kernel window each way
        if filteredTopHat.count > 2 * kernel.count {
            leftTrimPoint = (filteredTopHat.count - iWidth ) / 2 - kernel.count
            rightTrimPoint = (filteredTopHat.count + iWidth ) / 2  + kernel.count
        }
        
        //trimmed slice
        filteredTopHat = Array(filteredTopHat[leftTrimPoint...rightTrimPoint])
        
        let xc = filteredTopHat.count
        let fringe =  Float(xc - iWidth) * screenPPDP / 2
        //need to move drawn curve left in x by this much.
        
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




