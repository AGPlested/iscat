//
//  TraceIO.swift
//  ISCAT
//
//  Created by Andrew on 30/07/2016.
//  Copyright © 2016 Andrew. All rights reserved.
//

import Foundation

struct FilesItem {
    var filename : String
    var size : String
}

class TraceIO {
    /*
    func prepareForTrace() {
        
    }
    
    func loadBinaryDataFromDropbox() -> [Int16] {
        
    }
    */
    
    var dataFilename: String
    init () {
        dataFilename = ""
    }
    
    func loadData(dataFilename: String) -> [Int16] {
        // select data type?
        
        //*read binary data from disk
        // get path to data

        
        let bundle = Bundle.main
        let dataPath :String = bundle.path(forResource: dataFilename, ofType: "bin")!
        let readData = NSData (contentsOfFile: dataPath)
        print("Read the data \(dataFilename) in TraceIO")
        
        let count = readData!.length / MemoryLayout<Int16>.size //assume data format
        
        var arrayTrace = [Int16](repeating: 0, count: count)
        
        readData!.getBytes(&arrayTrace, length:count * MemoryLayout<Int16>.size)
        
        return arrayTrace

    }
    
}

class TextIO {
    
    func trial() {
        let trialOutputText = "If you like you can marry me, and if you like, you can buy the ring"
        let fileManager = FileManager.default
        let documentsURL = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let fileURL = documentsURL.appendingPathComponent("williamItWasReallyNothing.txt")
        
        do {
            try trialOutputText.write(to: fileURL, atomically: false, encoding: .utf8)
            print ("Wrote the following Smiths lyrics to \(fileURL): \(trialOutputText)")
        } catch {
            print("Failed writing to URL: \(fileURL), Error: " + error.localizedDescription)
        }
        var inString = ""
        do {
            inString = try String(contentsOf: fileURL)
        } catch {
            print("Failed reading from URL: \(fileURL), Error: " + error.localizedDescription)
        }
        print("Read the following Smiths lyrics from \(fileURL): \(inString)")
        
    }
}
