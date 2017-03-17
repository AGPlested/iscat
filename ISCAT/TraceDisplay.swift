//
//  TraceDisplay.swift
//  ISCAT
//
//  Created by Andrew on 30/07/2016.
//  Copyright © 2016 Andrew. All rights reserved.
//

import UIKit

class TraceDisplay: UIView {
    
    var tDrawScale : CGFloat = 0.5 {
        didSet {
            setNeedsDisplay()
            print("set")
        }
    }
    
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
           }
    

}
