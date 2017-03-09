//
//  TraceIO.swift
//  ISCAT
//
//  Created by Andrew on 30/07/2016.
//  Copyright © 2016 Andrew. All rights reserved.
//

import Foundation

class TraceIO {
    /*
    func prepareForTrace() {
        
    }
    
    func loadBinaryDataFromDropbox() -> [Int16] {
        
    }
    */
    
    func loadData() -> [Int16] {
        // select data type
        
        //*read binary data from disk
        // get path to data

        
        let bundle = Bundle.main
        let dataPath :String = bundle.path(forResource: "sim1600", ofType: "bin")!
        let readData = NSData (contentsOfFile: dataPath)
        print("Read the data in TraceIO")
        
        let count = readData!.length / MemoryLayout<Int16>.size //assume data format
        
        var arrayTrace = [Int16](repeating: 0, count: count)
        
        readData!.getBytes(&arrayTrace, length:count * MemoryLayout<Int16>.size)
        
        return arrayTrace

    }
    
}
