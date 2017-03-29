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
    if rightIndex < 0 {rightIndex = 0}
    
    if leftIndex > viewPoints.count {
        leftIndex = viewPoints.count
        rightIndex = viewPoints.count
    }
    
    if rightIndex > viewPoints.count {rightIndex = viewPoints.count}
    
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
    let brim = Int(e.duration! * pPSP / 5)        //brim of the top hat function is 1/5 of its hat width.
    

    let shiftInDataPoints = Int((currentDragX - startDragX) * pPSP ) //will be +ve if drag is to the right, screen points scaled to data points
    print ("sIDP, pPSP, brim, kHW, OLI, ORI", shiftInDataPoints, pPSP , brim, kernelHalfWidth, originalLeftIndex, originalRightIndex)
    var leftIndex   = originalLeftIndex + shiftInDataPoints - brim - kernelHalfWidth
    var rightIndex  = originalRightIndex + shiftInDataPoints + brim + kernelHalfWidth

    //check for edge here -protect against illegal indices
    if leftIndex < 0 {leftIndex = 0}
    if rightIndex < 0 {rightIndex = 0; leftIndex = 0}
    
    if leftIndex > viewPoints.count {
        leftIndex = viewPoints.count
        rightIndex = viewPoints.count
    }
    if rightIndex > viewPoints.count {rightIndex = viewPoints.count}
    
    print ("lIndex, rIndex: ", leftIndex, rightIndex)
    let slice = Array(viewPoints[leftIndex..<rightIndex])
    //shorter than the filtered top hat? Fixed?
    return slice

}

