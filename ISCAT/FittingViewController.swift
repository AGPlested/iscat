//
//  FittingViewController.swift
//  ISCAT
//
//  Created by Andrew on 24/08/2016.
//  Copyright © 2016 Andrew. All rights reserved.
//

import UIKit

protocol FitViewControllerDelegate {
    func FitVCDidFinish(controller: FittingViewController, touches:Int, fit:eventList)
    }

class FittingViewController: UIViewController {

    var progressCounter : Float = 0
    var pointsToFit : [Int16] = []
    var delegate: FitViewControllerDelegate? = nil
    var panCount : Int = 0
    var swipeCount : Int = 0
    var fitLine: CAShapeLayer!
    var gaussianLayer: CAShapeLayer!
    var gaussianPath: CGPath!
    let gfit = GaussianFit()
    var fitData = eventList() //from Event.swift
    let fitWindow = CGPoint (x: 900, y: 400)
    
    
    
    // need a container to hold all data from fitData DONE
    // input to fit algorithm
    // store fit command to reproduce
    //
    
    //need to remember BeganTap
    var locationOfBeganTap: CGPoint?
    var currentLocationOfTap: CGPoint?
    var locationOfEndTap: CGPoint?
    var averageY: CGFloat = 0.0          //want to store this for each event later
    var screenPointsPerDataPoint : Float?
    
    @IBOutlet weak var console: UITableView!
    @IBOutlet weak var FitView: UIView!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var BackButton: UIButton!
    
    func fitTraceView(arr: [Int16]) {
        //draw a fixed data trace on the screen
        //assuming a window of around 1000*500
        //would be nice just to take the coordinates from the previous layout but couldn't work out how to do it.
        let yPlotOffset = CGFloat(200)
        let viewWidth = CGFloat(900)
        let traceHeight = CGFloat(400)
        let firstPoint = CGPoint(x:0, y:yPlotOffset)
        var drawnPoint = CGPoint(x:0, y:yPlotOffset)
        
        FitView.backgroundColor = UIColor.white
        FitView.translatesAutoresizingMaskIntoConstraints = false
            
        //drawing trace
        let thickness: CGFloat = 2.0
        let tracePath = UIBezierPath()
        tracePath.move(to: firstPoint)
        
        screenPointsPerDataPoint = 900.0 / Float(pointsToFit.count)
        
        print ("traceview", pointsToFit.count, screenPointsPerDataPoint)
        for (index,point) in pointsToFit.enumerated() {
        
            drawnPoint = CGPoint(x: viewWidth * CGFloat(index) / CGFloat(pointsToFit.count) , y: yPlotOffset + traceHeight * CGFloat(point) / 32536.0)
            tracePath.addLine(to: drawnPoint)
            
        }
        
        // render to layer
        let traceLayer = CAShapeLayer()
        traceLayer.path = tracePath.cgPath
        traceLayer.strokeColor = UIColor.black.cgColor
        traceLayer.fillColor = nil
        traceLayer.lineWidth = thickness
        FitView.layer.addSublayer(traceLayer)
    
    }
    
    func optimiseFit() -> [Int]{
        print ("Fitting subroutine")
        return [0]
    }
    
    //called when user starts a pan
    func createHorizontalLine (startTap: CGPoint!, endTap: CGPoint!) -> CAShapeLayer {
        
        print ("drawing line:", startTap!, endTap!)
        //rough conversion of y value
        let averageY = (startTap.y + endTap.y) / 2 - 50
        
        let startPoint = CGPoint(x: (startTap.x - 50), y: averageY)     //-50 here for feel
        let endPoint = CGPoint(x: (endTap.x - 50), y: averageY)         //as above
        
        let thickness: CGFloat = 9.0

        let fitLayer = CAShapeLayer()
        fitLayer.path = pathOfFitLine(startPt: startPoint, endPt: endPoint)     //get path for line
        fitLayer.strokeColor = UIColor.red.cgColor
        fitLayer.fillColor = nil
        fitLayer.lineWidth = thickness
        
        
        return fitLayer
    }
  
    //whilst pan is updating, make the new line
    func pathOfFitLine(startPt: CGPoint, endPt: CGPoint) -> CGPath {
        let fitBezier = UIBezierPath()
        fitBezier.move(to: startPt)
        fitBezier.addLine(to: endPt)
        return fitBezier.cgPath
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fitTraceView(arr: pointsToFit)
        positionLabel.text = "Position in trace \(progressCounter) %"
        
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
 
    @IBAction func fit2Pan(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == UIGestureRecognizerState.began {
            
            locationOfBeganTap = gesture.location(in: self.view)
            //should be dynamic
            
            print ("began two finger pan", locationOfBeganTap!)
            //console.dataSource()
            gaussianPath = gfit.buildGaussPath(pointsPSP: screenPointsPerDataPoint!, firstTouch: locationOfBeganTap!, currentTouch: locationOfBeganTap!, window: fitWindow)
            gaussianLayer = gfit.buildGaussLayer(gPath: gaussianPath)
            FitView.layer.addSublayer(gaussianLayer)
            
        } else if gesture.state == UIGestureRecognizerState.changed {
            currentLocationOfTap = gesture.location(in: self.view)
        
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            gaussianLayer.path = gfit.buildGaussPath(pointsPSP: screenPointsPerDataPoint!, firstTouch: locationOfBeganTap!, currentTouch: currentLocationOfTap!, window: fitWindow)
            CATransaction.commit()
            //FitView.layer.addSublayer(gaussianLayer)
            
        } else if gesture.state == UIGestureRecognizerState.ended {
            
            locationOfEndTap = gesture.location(in: self.view)
            print ("end two finger pan", locationOfEndTap!)
            
    }
    }
   
    @IBAction func fitPan(_ gesture: UIPanGestureRecognizer) {
        
        // recognize pan and get coords
        
        
        if gesture.state == UIGestureRecognizerState.began {
            
            locationOfBeganTap = gesture.location(in: self.view)
            print ("began one finger pan", locationOfBeganTap!)
            
            averageY = (locationOfBeganTap?.y)!
            //print (String(format:"averageY: %@", averageY))
            
            fitLine = createHorizontalLine(startTap: locationOfBeganTap, endTap: locationOfBeganTap)
            FitView.layer.addSublayer(fitLine)
            
        } else if gesture.state == UIGestureRecognizerState.changed {
            currentLocationOfTap = gesture.location(in: self.view)
            
            //allow the user to correct the Y-position (line remains horizontal
            // -50 to adjust to finger position in L->R fashion
            
            averageY = ((locationOfBeganTap?.y)! + (currentLocationOfTap?.y)!) / 2 - 50  //inferring number types here
            let startPoint = CGPoint(x: ((locationOfBeganTap?.x)! - 50)  , y: averageY)
            let endPoint = CGPoint(x: ((currentLocationOfTap?.x)! - 50) , y: averageY)

            //no animations
            //https://github.com/iamdoron/panABallAttachedToALine/blob/master/panLineRotation/ViewController.swift
            //
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            fitLine.path = pathOfFitLine(startPt: startPoint, endPt: endPoint)
            CATransaction.commit()
            
        }
        
        else if gesture.state == UIGestureRecognizerState.ended {
            
            // defensive code - Tap must have begun
            if (locationOfBeganTap != nil) {
                locationOfEndTap = gesture.location(in: self.view)
                print ("end pan", locationOfEndTap!, averageY)
                let fitEventToStore = chEvent(eKind: .sojourn)
                
                // acccount for reverse (R -> L pan) fits with min and max
                let fittedStart = min (Float((locationOfBeganTap?.x)!), Float((locationOfEndTap?.x)!))
                let fittedEnd = max (Float((locationOfBeganTap?.x)!), Float((locationOfEndTap?.x)!))
                
                //storing screen coordinates right now, will adapt to real world coordinates later
                fitEventToStore.timePt = fittedStart
                fitEventToStore.amplitude = Double(averageY)
                fitEventToStore.length = fittedEnd - fittedStart
                
                panCount += 1
                print (fitEventToStore.printable())
                //crashes here
                fitData.eventAppend(e: fitEventToStore)
                
            }
            
            
            //saveFitLine
            
        }

        
        //an action for a more interactive kind of fit
        //dragging out a gaussian filtered rectangle?
        //need to draw on the fly so that can adjust
        
        //extent of drag gives opposed corners
        //if halfExpanding {
        //  if currentPoint.x < originPoint.x {
            //    leftExtent.x = currentPoint.x
            //    rightExtent.x = 2 * originPoint.x - currentPoint.x
            // }
            //else {
            //     leftExtent.x = originPoint.x - currentPoint.x
            //     rightExtent.x = currentPoint.x
            // ##do it here to get the sign right
            //      let size.x = 2 * (
            //    }
            //
        //else {
        //if currentPoint.x < originPoint.x {
        //    leftExtent.x = currentPoint.x
        //    rightExtent.x = originPoint.x
        // }
        //else {
        //     leftExtent.x = originPoint.x
        //     rightExtent.x = currentPoint.x
        //}
        //}
        
        //no half-expland option for vertical component - dragging from one level to another
        //check for snapping
        
        //if snapping {
        //  originLevel = nearestLevel(originPoint.y)
        //  currentLevel = nearestLevel(currentPoint.y)
        //}
        //else
        //{
        
        //if currentPoint.y < originPoint.y {
        //    **downward
        //    currentLevel.y = currentPoint.y
        //    originLevel.y = originPoint.y
        //    let size.y = ///PIXELS!!! depends on zoom need to think about real units
        
        // }
        //else {
        //     leftExtent.x = originPoint.x
        //     rightExtent.x = currentPoint.x
        //}
    
        
        
        
        
        //need to be selectable to move
        
        //live RMSD?
        
        //snap? 
        
        //draw grid?
        
        //draw amplitude lines
        
        //
        
    
        
        
        
        
        
        
    
        
    }
    
    
    
    // run fitting command

    @IBAction func goBack(_ sender: Any) {
        print ("button")
        delegate?.FitVCDidFinish(controller: self, touches: panCount, fit: fitData)
        
    }
  

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */


}
