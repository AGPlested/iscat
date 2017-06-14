//
//  TraceIO.swift
//  ISCAT
//
//  Created by Andrew on 30/07/2016.
//  Copyright © 2016 Andrew. All rights reserved.
//

import Foundation
import SwiftyDropbox

struct FilesItem {
    var filename : String
    var size : String
    var date : String
}

enum BinaryFormats: String {
    case axographBinary, axonBinary, consamBinary, sixteenBitBinary
}

//Dropbox file utilities
func getDropboxFiles() -> [FilesItem] {
    var DBFiles = [FilesItem]()
    if let client = DropboxClientsManager.authorizedClient {
        let r = client.files.listFolder(path: "").response { response, error in
            if let result = response {
                
                print("Dropbox folder contents:")
                for entry in result.entries {
                    print(entry.name)
                    //self.filenames?.append(entry.name)
                    
                    var fileDisplay : FilesItem?
                    if let file = entry as? Files.FileMetadata {
                        print("\tThis is a file with path: \(String(describing: file.pathLower)) and size: \(file.size)")
                        fileDisplay = FilesItem(filename: file.name, size: file.size.description, date: file.clientModified.description)
                    } else if let folder = entry as? Files.FolderMetadata {
                        print("\tThis is a folder with path: \(String(describing: folder.pathLower))")
                        fileDisplay = FilesItem(filename: folder.name, size: "", date: folder.id)
                    }
                    DBFiles.append(fileDisplay!)
                    
                }
                print ("innerloop: \(DBFiles)")
                
            }
            print ("innerloop2: \(DBFiles)")
        }
        print ("innerloop3: \(DBFiles)")
    }
    print (DBFiles)
    return DBFiles
}


class TraceIO {
    
    var arrayTrace = [Int16]()
    var dataFilename: String
    var fileFormat : BinaryFormats
    
    init () {
        dataFilename = ""
        fileFormat = BinaryFormats.axographBinary
    }
    
    func loadBinaryDataFromDropbox(dataPath: String, fileFormat: BinaryFormats) -> ([Int16], URL) {
       
        var fileDestinationURL : URL?
        //load trace
        // Download a file
        //from http://stackoverflow.com/documentation/dropbox-api/408/downloading-a-file#t=201704301437468475351
        
        let destination : (URL, HTTPURLResponse) -> URL = { temporaryURL, response in
            let fileManager = FileManager.default
            let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            // generate a unique name for this file in case we've seen it before
            let UUID = NSUUID().uuidString
            let pathComponent = "\(UUID)-\(response.suggestedFilename!)"
            
            fileDestinationURL = directoryURL.appendingPathComponent(pathComponent)
            return fileDestinationURL! //as URL
        }
        
        if let client = DropboxClientsManager.authorizedClient {
            _ = client.files.download(path: dataPath, destination: destination)
            
                .progress { progressdata in
                    print (progressdata)
                    //pop up something in the UI - but how?!
                    /*print("bytesRead: \(progrssRead)")
                    print("totalBytesRead: \(totalBytesRead)")
                    print("totalBytesExpectedToRead: \(totalBytesExpectedToRead)")
                    */
                }
                
                .response { response, error in
                    
                    if let (metadata, url) = response {
                        print("*** Download file ***")
                        print("Downloaded file name: \(metadata.name)")
                        print("Downloaded file url: \(url)")
                    } else {
                        print(error!)
                    }
            }
        }
        
        let readData = NSData (contentsOf: fileDestinationURL!)
        extractTraceToArray(dataFile: readData!)
        
        //pass back the place where the file is temporarily stored, to be helpful
        return (arrayTrace, fileDestinationURL!)
    }
    
    func loadData(dataFilename: String) -> [Int16] {
        // select data type?
        
        //*read binary data from disk
        // get path to data

        //need to wrap all this to protect it
        let bundle = Bundle.main
        let dataPath :String = bundle.path(forResource: dataFilename, ofType: "bin")!
        let readData = NSData (contentsOfFile: dataPath)
        print("Read the data \(dataFilename) in TraceIO")
        extractTraceToArray(dataFile: readData!)
        return arrayTrace
    }
        
    func extractTraceToArray (dataFile: NSData) {
        let count = dataFile.length / MemoryLayout<Int16>.size //assume data format
        arrayTrace = [Int16](repeating: 0, count: count)
        dataFile.getBytes(&arrayTrace, length:count * MemoryLayout<Int16>.size)
    }
    
}


class Storage {
    // Get the document directory URL
    let localDocumentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    func getFilesInDocumemtsDirectory() -> [FilesItem] {
        var fileList = [FilesItem]()
        
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: localDocumentsUrl, includingPropertiesForKeys: nil, options: [])
            print(directoryContents)
            
            for file in directoryContents {
                let fileName = file.lastPathComponent
                let attributes = try FileManager.default.attributesOfItem(atPath:file.path)
                let fileSize = String (describing: attributes[FileAttributeKey.size]!)
                let fileDate = String (describing: attributes[FileAttributeKey.modificationDate]!)
                print ("local file with name ")
                
                fileList.append(FilesItem(filename: fileName, size: fileSize, date: fileDate))
            }
            return fileList
        }
        catch let error as NSError {
            print(error.localizedDescription)
            return fileList
        }

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
