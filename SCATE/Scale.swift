//
//  Scale.swift
//  ISCAT
//
//  Created by Andrew on 27/03/2017.
//  Copyright © 2017 Andrew. All rights reserved.
//

import UIKit

class xRuler {
    //draws the ticks and axis for a trace view
    var calibratorWidth: CGFloat? = nil
    var minorTicks: Int? = nil
    var axisY : CGFloat = 30
    var topMajorY : CGFloat = 0
    var topMinorY : CGFloat = 15
    
    let axisPath = UIBezierPath()
    let axisLayer = CAShapeLayer()
    
    func axisLayer (widthInScreenPoints: CGFloat, minorT: Int? = nil) -> CAShapeLayer {
        
        calibratorWidth = widthInScreenPoints
        
        //minor tick
        if minorT != nil {
            minorTicks = minorT
            let tickInterval = calibratorWidth! / CGFloat(minorTicks! + 1)
            
            for i in 1...minorTicks! {
                let tickPointInX = CGFloat(i) * tickInterval
                axisPath.move(to: CGPoint(x: tickPointInX, y: axisY))
                axisPath.addLine(to: CGPoint(x: tickPointInX, y: topMinorY))
            }
        }
        
        //axis
        axisPath.move(to: CGPoint(x:0, y:axisY))
        axisPath.addLine(to: CGPoint(x:calibratorWidth!, y:axisY))
        
        //major tick
        axisPath.move(to: CGPoint(x:0, y:axisY))
        axisPath.addLine(to: CGPoint(x:0, y:topMajorY))

        axisLayer.path = axisPath.cgPath
        return axisLayer
    }
}

class yRuler {
    //draws the ticks and y axis for a trace view
    var blockHeight: CGFloat? = nil
    var minorTicks: Int? = nil
    let axisPath = UIBezierPath()
    let axisLayer = CAShapeLayer()
    
    func axisLayer (heightInScreenPoints: CGFloat, minorT: Int? = nil) -> CAShapeLayer {
        
        blockHeight = heightInScreenPoints
        
        //minor tick
        if minorT != nil {
            minorTicks = minorT
            let tickInterval = blockHeight! / CGFloat(minorTicks! + 1)
            
            for i in 1...minorTicks! {
                let tickPointInY = CGFloat(i) * tickInterval
                axisPath.move(to: CGPoint(x: 0, y: tickPointInY))
                axisPath.addLine(to: CGPoint(x:5, y: tickPointInY))
            }
        }
        
        //axis
        axisPath.move(to: CGPoint(x:0, y:0))
        axisPath.addLine(to: CGPoint(x:0, y:blockHeight!))
        
        //major tick
        axisPath.move(to: CGPoint(x:0, y:0))
        axisPath.addLine(to: CGPoint(x:20, y:0))
        
        axisLayer.path = axisPath.cgPath
        return axisLayer
    }
}
