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
    var chunkWidth: CGFloat? = nil
    var minorTicks: Int? = nil
    let axisPath = UIBezierPath()
    let axisLayer = CAShapeLayer()
    
    func axisLayer (widthInScreenPoints: CGFloat, minorT: Int? = nil) -> CAShapeLayer {
        
        chunkWidth = widthInScreenPoints
        
        //minor tick
        if minorT != nil {
            minorTicks = minorT
            let tickInterval = chunkWidth! / CGFloat(minorTicks! + 1)
            
            for i in 1...minorTicks! {
                let tickPointInX = CGFloat(i) * tickInterval
                axisPath.move(to: CGPoint(x: tickPointInX, y: 0))
                axisPath.addLine(to: CGPoint(x: tickPointInX, y: 10))
            }
        }
        
        //axis
        axisPath.move(to: CGPoint(x:0, y:0))
        axisPath.addLine(to: CGPoint(x:chunkWidth!, y:0))
        
        //major tick
        axisPath.move(to: CGPoint(x:0, y:0))
        axisPath.addLine(to: CGPoint(x:0, y:20))

        axisLayer.path = axisPath.cgPath
        return axisLayer
    }
}
