//
//  dataSelecting.swift
//  ISCAT
//
//  Created by Andrew on 21/03/2017.
//  Copyright © 2017 Andrew. All rights reserved.
//

import UIKit

func getFittingDataSlice (firstTouch: CGPoint, currentTouch: CGPoint, viewPoints: [Int16], viewW: Float, kernelHalfWidth: Int) -> [Int16] {
    let leftTapIndex = min (Float(firstTouch.x), Float(currentTouch.x))
    let rightTapIndex = max (Float(firstTouch.x), Float(currentTouch.x))
    
    //normalizing by view width (viewW) removes the need to scale
    //indices are extended by the half-width of the Gaussian filtering kernel.
    
    var leftIndex   = Int(Float(viewPoints.count) * leftTapIndex / viewW ) - kernelHalfWidth
    var rightIndex   = Int(Float(viewPoints.count) * rightTapIndex / viewW ) + kernelHalfWidth
    
    //check for edge here -protect against illegal indices
    if leftIndex < 0 {leftIndex = 0}
    if leftIndex > viewPoints.count {
        leftIndex = viewPoints.count
        rightIndex = viewPoints.count
    }
    
    if rightIndex > viewPoints.count {rightIndex = viewPoints.count}
    
    let fittingSlice = Array(viewPoints[leftIndex..<rightIndex])
    //shorter than the filtered top hat? Fixed?
    return fittingSlice
}

func getSliceDuringDrag (firstTouch: CGPoint, currentTouch: CGPoint, e: chEvent, viewPoints: [Int16], viewW: Float, kernelHalfWidth: Int) -> [Int16] {
    let startDragX = Float(firstTouch.x)
    let currentDragX = Float(currentTouch.x)
    let startTime = e.timePt
    let originalLeftIndex = Int(startTime)       //no conversion here yet
    ///why is this getting crazy?
    let originalRightIndex = Int(startTime + e.length!)      //no conversion here yet
    // should these indices be stored in the event?
    
    //normalizing by screen width removes the need to scale
    //indices are extended by the half-width of the Gaussian filtering kernel.
    let shiftInDataPoints = Int(Float(viewPoints.count) * (currentDragX - startDragX) / viewW ) //will be +ve if drag is to the right
    var leftIndex   = originalLeftIndex + shiftInDataPoints
    var rightIndex  = originalRightIndex + shiftInDataPoints

    //check for edge here -protect against illegal indices
    if leftIndex < 0 {leftIndex = 0}
    if leftIndex > viewPoints.count {
        leftIndex = viewPoints.count
        rightIndex = viewPoints.count
    }
    
    if rightIndex > viewPoints.count {rightIndex = viewPoints.count}
    
    let slice = Array(viewPoints[leftIndex..<rightIndex])
    //shorter than the filtered top hat? Fixed?
    return slice

}

