//
//  TraceViewController.swift
//  ISCAT
//
//  Created by Andrew on 30/07/2016.
//  Copyright © 2016 Andrew Plested. All rights reserved.
//

import UIKit
import SwiftyDropbox

class TraceViewController: UIViewController, UIScrollViewDelegate, FitViewControllerDelegate, SettingsViewControllerDelegate, EventsViewControllerDelegate {

    @IBOutlet weak var sv: UIScrollView!
    @IBOutlet weak var zoomButton: UIButton!
    @IBOutlet weak var zoomLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!


    let v = TraceDisplay() //content view
    let ld = TraceIO()     //file retrieval
    var s = SettingsList()
    var masterEventList = eventList()
    
    var pointIndex : Int = 0
    
    
    var traceLength : Int?
    var traceArray = [Int16]() //  this array will hold the trace data
    
    let tStart = 0
    var xp : CGFloat = 0    //the xposn of the trace
    
    var originalContentSize = CGSize()
    var progress = Float()
    var offset = CGPoint() //view offset
    var viewSize = CGRect()
    
    var originalZoom = CGFloat(1)
    
    
    func updateLabels () {
        zoomLabel.text = String(format:"%.1f", sv.zoomScale)
        progress = 100 * Float(sv.contentOffset.x) / Float(sv.contentSize.width)
        if (progress < 0) {
            progress = 0
        }
        progressLabel.text = String(format:"%.1f%%", progress)
        
    }

    
    func traceView(arr: [Int16]) {
        traceLength = arr.count
        
        var firstPoint = CGPoint(x:xp, y:200)
        var drawnPoint = CGPoint(x:xp, y:200)
        
        let bChunk = s.basicChunk.getIntValue()
        
        let headerSize = s.header.getIntValue()
        
        let chunk = Int (Float(bChunk) / Float(v.tDrawScale ))
        let chunkN = Int ((traceLength! - headerSize) / chunk )        // the number of chunks to display
        
        let step = ceil(1 / Double(v.tDrawScale))
        
        print (step, chunkN, chunkN * chunk, traceLength!)
        
        sv.backgroundColor = UIColor.white
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.minimumZoomScale = 0.1
        sv.maximumZoomScale = 10
        
        if sv != nil {
            sv.delegate = self
        }
        
        sv.addSubview(v)        //UIView
        
        for i in 0..<chunkN {
            
            //chunk label
            let lab = UILabel()
            lab.text = "C\(i+1)"
            lab.sizeToFit()
            lab.frame.origin = CGPoint(x:xp, y:100)
            v.addSubview(lab)
            
            //drawing trace
            let thickness: CGFloat = 2.0
            let tracePath = UIBezierPath()
            tracePath.move(to: firstPoint)
            
            for index in stride(from:0, to: chunk, by: Int(step))  {
                
                pointIndex = index + headerSize + tStart + i * chunk
                
                //xp is separately scaled by tDrawScale
                drawnPoint = CGPoint(x: xp + v.tDrawScale * CGFloat(index), y: CGFloat(200) * (1.0 + CGFloat(arr[pointIndex]) / 32536.0))
                
                tracePath.addLine(to: drawnPoint)
                
            }
            
            //grab the last plotted point for next iteration
            firstPoint = drawnPoint
            print (i, firstPoint)
            
            // render to layer
            let traceLayer = CAShapeLayer()
            traceLayer.path = tracePath.cgPath
            traceLayer.strokeColor = UIColor.black.cgColor
            traceLayer.lineJoin = kCALineJoinRound
            traceLayer.fillColor = nil
            traceLayer.lineWidth = thickness
            v.layer.addSublayer(traceLayer)             //accumulate a bunch of anonymous layers.
            
            xp += CGFloat(chunk) * v.tDrawScale
        }
        
        var sz = sv.bounds.size     //Not sure what these three lines do any more.
        sz.width = xp
        sv.contentSize = sz     //change size to

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //get settings?
        
        
        //Load the trace
        traceArray = ld.loadData()
        //print (trace[0])
        traceView(arr: traceArray)
        sv.bouncesZoom = false
        statusLabel.text = "No fit yet."
        updateLabels()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return v
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //print ("scrolled", sv.contentOffset)
        updateLabels()
        sv.isUserInteractionEnabled = true
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {

        var sz = sv.bounds.size
        sz.width = xp * scale
        sz.height *= scale //reset size of view
        sv.contentSize = sz
        
        updateLabels()
        
        print ("content size after resize", sv.contentSize.width, "offset after resize" , sv.contentOffset.x)
        sv.isUserInteractionEnabled = true
    }
    
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
   
        self.offset = sv.contentOffset
        self.originalZoom = sv.zoomScale //needed to keep the view centred
        self.originalContentSize = sv.contentSize
        
        print ("begin zoom", self.offset, self.originalZoom)
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        //print("scrollViewDidZoom")
        
        let zoomFactor = (sv.zoomScale / self.originalZoom)   // relative to original zoom during transition
        //sv.contentOffset = CGPoint(x:self.offset.x * zoomFactor + sv.bounds.width / 2 * (zoomFactor - 1), y:self.offset.y * zoomFactor + sv.bounds.height / 2 * (zoomFactor - 1))
        
        //affine transform was updated on view to make only x-zooming
        sv.contentOffset = CGPoint(x:self.offset.x * zoomFactor + sv.bounds.width / 2 * (zoomFactor - 1), y:sv.contentOffset.y)
        //update progress counter but with special values
        
        //to get the progress meter correct, the
        //original content size must be scaled by the zoom factor during the zoom
        progress = 100 * Float(sv.contentOffset.x) / Float(self.originalContentSize.width * zoomFactor)
        updateLabels()
        
    }

    //mark actions
    
    func EventsVCDidFinish(controller: EventsViewController, updatedEvents: eventList) {
        print ("Events returned", updatedEvents)
        masterEventList = updatedEvents
        controller.dismiss(animated: true, completion: {})
    }
    
    func FitVCDidFinish(controller: FittingViewController, touches: Int, fit:eventList) {
        print ("Touches", touches)
        print ("Fit", fit)
        
        //by doing it this way, lose timestamps and event order
        //need a helper function to append list to list
        //look at creation time of list to get overall order of old and new events
        //for example....
        
        //reject fit returns an empty list
        guard fit.count() > 0 else {
            statusLabel.text = String(format:"No fit or fit rejected. Nothing stored ")
            controller.dismiss(animated: true, completion: {})
            return
        }
        for event in fit.list {
            masterEventList.eventAppend(e: event)
        statusLabel.text = String(format:"Stored fit: %@",fit.consolePrintable())
        controller.dismiss(animated: true, completion: {})
        }
    }
    
    func SettingsVCDidFinish(controller: SettingsViewController, updatedS: SettingsList) {
        print ("Settings updated", updatedS)
        s = updatedS
        controller.dismiss(animated: true, completion: {})
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FitViewSegue"
        {
            print ("FitViewSegue triggered.")
            if let destinationVC = segue.destination as? FittingViewController {
                destinationVC.progressCounter = self.progress           //progress excludes the header
                let dataLength = Float(traceLength! - 3000)             // this is not scaled
                let leftPoint = s.header.getIntValue() + Int(self.progress / 100 * dataLength)
                let rightPoint = leftPoint + Int(dataLength * Float(sv.bounds.width / sv.contentSize.width))
                print (leftPoint, rightPoint, rightPoint-leftPoint, traceArray.count, sv.bounds.width, sv.contentSize.width) //these points are all wrong compared to whats on the screen but getting there. tooMUCH!
                
                //let pointRange = (leftPoint, rightPoint)
                let fitSlice = Array(self.traceArray[leftPoint..<rightPoint]) //still seems like it takes too much but why???
                print (fitSlice.count, sv.bounds.width / sv.contentSize.width, dataLength * Float(sv.bounds.width / sv.contentSize.width) )
                destinationVC.pointsToFit = fitSlice
                destinationVC.delegate = self
                
            }
        }
        else if segue.identifier == "SettingsViewSegue"
            {
            print ("SettingsViewSegue triggered.")
            if let destinationVC = segue.destination as? SettingsViewController {
                
                //preparation for segue to settings goes here
                //local settings object is passed and returned
                destinationVC.localSettings = s
                destinationVC.delegate = self
            }
        }
        else if segue.identifier == "EventsViewSegue"
            //must set this in segue!!!
            {
            print ("EventsViewSegue triggered.")
            if let destinationVC = segue.destination as? EventsViewController {
                    
                    //preparation for segue to settings goes here
                    //reference to event object is passed and returned
                
                destinationVC.localEventsList = masterEventList
                destinationVC.delegate = self
                
            }
        }
    }
    
    
    //add vertical zoom?

    
    //if this code executes, trace display disappears but otherwise app still runs
    @IBAction func zoomIn(_ sender: UIButton) {
    
        //need to put a defensive limit in here to avoid overshoot
        self.offset = sv.contentOffset
        print ("hard zooming", self.offset)
        v.tDrawScale *= 2       //increase the horizontal zoom factor
        v.layer.sublayers = nil //kill all the existing layers (ALL!!!)
        
        
         //add display of zoom factor
        
        //redraw the view
        traceView(arr: traceArray)
        
        print ("redrawn", sv.contentOffset)
        sv.contentOffset = CGPoint (x: self.offset.x * v.tDrawScale, y: self.offset.y)
    }

    //if this code executes, trace display disappears but otherwise app still runs
    
    @IBAction func zoomOut(_ sender: UIButton) {
        //need to put a defensive limit in here to avoid undershoot (data disappears!)
        
        v.tDrawScale /= 2           //reduce the horizontal zoom factor
        v.layer.sublayers = nil     //kill all the existing layes (ALL!!!)
        
        //add display of zoom factor
        
        //redraw the view
        traceView(arr: traceArray)
    }
  


}

