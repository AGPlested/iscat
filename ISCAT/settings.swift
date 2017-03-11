//
//  settings.swift
//  ISCAT
//
//  Created by Andrew on 10/03/2017.
//  Copyright © 2017 Andrew. All rights reserved.
//

import UIKit

//settings for the app as a whole at the moment
class Settings {
    
    var header : Int
    var basicChunk : CGFloat
    
    //working directory
    var workingPath : String?
    var idealizationFilename : String?
    
    //type of files
    
    init() {
        
        
        
        
        //related to a trace
        header = 3000
        basicChunk = 100
    }
    
    
}
