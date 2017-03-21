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
    var panCount : Int = 0          //not used
    var swipeCount : Int = 0        //never used
    var fitLine: CAShapeLayer!
    var gaussianLayer: CustomLayer!
    var gaussianPath: CGPath!
    var localCreationID = 0
   
    
    let gfit = GaussianFit(filter: 0.05)    //default fc as a function of sample frequency - should be a setting
    
    var fitData = eventList()               //from Event.swift
    var selected = eventList()
    var selectedTransforms = [Int: CATransform3D]()
    var selectedFitPoints = [Int: [CGPoint]]()
    
    var worstSSD : Float = 1e5              //per point
    
    //would be nice just to take the coordinates from the previous layout but couldn't work out how to do it.
    let yPlotOffset = CGFloat(200)
    let traceHeight = CGFloat(400)
    let fitWindow = CGPoint (x: 900, y: 600)
    let viewWidth = CGFloat(900)
    var screenPointsPerDataPoint : Float?
    
    // need a container to hold all data from fitData DONE
    // input to fit algorithm
    // run fitting command
    // store fit command to reproduce
    // need to be selectable to move
    // live RMSD? DONE
    // snap?
    // draw grid?
    // live amplitude histogram, markable
    
    //need to remember BeganTap
    var locationOfBeganTap: CGPoint?
    var currentLocationOfTap: CGPoint?
    var locationOfEndTap: CGPoint?
    
    //transformed points (as drawn) to be used for calcs
    var firstTapAsDrawn: CGPoint?
    var currentTapAsDrawn: CGPoint?
    var finalTapAsDrawn: CGPoint?
    
    var averageY: CGFloat = 0.0
    //want to store this for some events later (Could calculate at the time?)
    
    @IBOutlet weak var console: UITableView!        //console is not used yet
    @IBOutlet weak var FitView: UIView!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var BackButton: UIButton!
    @IBOutlet weak var selectedLabel: UILabel!
    
        
    func fitTraceView() {
        //draw a fixed data trace on the screen
        
        screenPointsPerDataPoint = Float(viewWidth) / Float(pointsToFit.count)    //900
        print ("traceview", pointsToFit.count, screenPointsPerDataPoint!)
        
        let firstDataPoint = CGPoint(x:0, y:yPlotOffset)
        var drawnDataPoint = CGPoint(x:0, y:yPlotOffset)
        
        FitView.backgroundColor = UIColor.white
        FitView.translatesAutoresizingMaskIntoConstraints = false
            
        //drawing trace
        let thickness: CGFloat = 2.0
        let tracePath = UIBezierPath()
        tracePath.move(to: firstDataPoint)
        
        for (index, point) in pointsToFit.enumerated() {
            drawnDataPoint = CGPoint(x: viewWidth * CGFloat(index) / CGFloat(pointsToFit.count) , y: yPlotOffset + traceHeight * CGFloat(point) / 32536.0)
            tracePath.addLine(to: drawnDataPoint)
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
    func createHorizontalLine (startTap: CGPoint!, endTap: CGPoint!) -> CustomLayer {
        
        print ("drawing line:", startTap!, endTap!)
        //rough conversion of y value
        averageY = (startTap.y + endTap.y) / 2 - 50
        
        let startPoint = CGPoint(x: (startTap.x - 50), y: averageY)     //-50 here for feel
        let endPoint = CGPoint(x: (endTap.x - 50), y: averageY)         //as above
        
        let thickness: CGFloat = 9.0

        let fitLayer = CustomLayer()        //subclass of CAShapeLayer with ID
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
    
    
    func calculateSSD (A: [Float], B:[Float]) -> Float {
        var ssd :Float = 0.0
        for (e, f)  in zip (A, B) {
            ssd += pow ((e - f), 2)
        }
        //print ("\(ssd)")
        return ssd
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fitTraceView()
        positionLabel.text = "Position in trace \(progressCounter) %"
        selectedLabel.text = "Nothing selected"
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func drawnFitTap(_ sender: UITapGestureRecognizer) {
        print ("Single tap.")
        let view = sender.view
        let loc = sender.location(in: view)
        
        if let hitting = view?.layer.hitTest(loc) {
            if hitting.sublayers != nil {
                for hitt in hitting.sublayers! {
                    if let hitCustom = hitt as? CustomLayer {
                        //this fails following a translation - need to convert 'loc'
                        //select/deselect still works if you tap the original location
                        if (hitCustom.path?.contains(loc))!  {
                            print ("You hit \(hitCustom.localID!) at \(loc)")
                            let tappedEvent = fitData.list.first(where: {$0.localID == hitCustom.localID!})
                            
                            if selected.hasEventWithID(ID: hitCustom.localID!) {
                                selected.removeEventByLocalID(ID: hitCustom.localID!)
                                //animated
                                CATransaction.begin()
                                hitCustom.lineWidth = 5.0
                                CATransaction.commit()
                                print ("Deselected event \(hitCustom.localID!)")
                            } else {
                                selected.eventAppend(e: tappedEvent!)
                                CATransaction.begin()
                                hitCustom.lineWidth = 10.0
                                CATransaction.commit()
                                print ("Selected event \(hitCustom.localID!)")
                            }
                            
                            //should be a function to update labels/console
                            selectedLabel.text = selected.consolePrintable(title: "Selected")
                            
                            
                
                            
                            //selectDONE, deselectDONE, delete, move, show....

                            
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func fit2Pan(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == UIGestureRecognizerState.began {
            
            locationOfBeganTap = gesture.location(in: self.view)
            if selected.list.isEmpty {
            // create event
                print ("Began one finger pan.", locationOfBeganTap!)
                localCreationID += 1
                
                // console.dataSource()
                gaussianPath = gfit.buildGaussPath(pointsPSP: screenPointsPerDataPoint!, firstTouch: locationOfBeganTap!, currentTouch: locationOfBeganTap!, window: fitWindow)
                gaussianLayer = gfit.buildGaussLayer(gPath: gaussianPath)
                gaussianLayer.localID = localCreationID
                // event created is linked to layer for later
                FitView.layer.addSublayer(gaussianLayer)
            }
            else {
            //move selected
                print ("Began one finger drag of \(selected).", locationOfBeganTap!)
                //should store current selected layer transforms
                selectedTransforms = [:]
                for event in selected.list {
                    for layer in (gesture.view?.layer.sublayers!)! {
                        if let cLayer = layer as? CustomLayer {
                            if cLayer.localID == event.localID {
                                selectedTransforms[cLayer.localID!] = cLayer.transform
                                selectedFitPoints[cLayer.localID!] = cLayer.drawnPathPoints
                                //use a dictionary to make sure we get the right transform back later!
                            }
                        }
                    }
                }
            }
                
        } else if gesture.state == UIGestureRecognizerState.changed {
            currentLocationOfTap = gesture.location(in: self.view)
            let gaussianKernelHalfWidth = Int (0.5 * Float(gfit.kernel.count) )
            
            if selected.list.isEmpty {
            // expand event with pan
                
                let targetDataPoints = getFittingDataSlice(firstTouch: locationOfBeganTap!, currentTouch: currentLocationOfTap!, viewPoints: pointsToFit, viewW: Float(viewWidth), kernelHalfWidth: gaussianKernelHalfWidth)
                
                let lastDrawnFilteredTopHat = gfit.filteredTopHat
                let screenTopHat = lastDrawnFilteredTopHat.map {th in Float(locationOfBeganTap!.y) - th}
                
                let target : [Float] = targetDataPoints.map { t in Float(yPlotOffset + traceHeight * CGFloat(t) / 32536.0 )} //to get screen point amplitudes
        
                let SSD_size = Float(target.count)
                let normalisedSSD = calculateSSD (A: screenTopHat, B: target) / SSD_size
                // bad fit is red, good fit is green
                let color = fitColor(worstSSD : worstSSD, currentSSD: normalisedSSD)
                print (normalisedSSD, color)
                // would be good to save the best SSD with the fit so it can be
                // recovered by the user.
                // write out SSD and event length (in samples - convert easily later).
                
                // put the latest curve, colored to previous SSD.
                CATransaction.begin()
                CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                gaussianLayer.path = gfit.buildGaussPath(pointsPSP: screenPointsPerDataPoint!, firstTouch: locationOfBeganTap!, currentTouch: currentLocationOfTap!, window: fitWindow)
                gaussianLayer.drawnPathPoints = gfit.drawnPath
                gaussianLayer.strokeColor = color.cgColor
                CATransaction.commit()
            
            } else {
                // move paths around with live SSD
                // assuming all events are chEvents
                
                for event in selected.list {
                    //screen coordinates so no conversion needed
    
                    let targetDataPoints = getSliceDuringDrag(firstTouch: locationOfBeganTap!, currentTouch: currentLocationOfTap!, e: event as! chEvent, viewPoints: pointsToFit, viewW: Float(viewWidth), kernelHalfWidth: gaussianKernelHalfWidth)
                    
                    let target : [Float] = targetDataPoints.map { t in Float(yPlotOffset + traceHeight * CGFloat(t) / 32536.0 )} //to get screen point amplitudes
                    for layer in (gesture.view?.layer.sublayers!)! {
                        if let cLayer = layer as? CustomLayer {
                            
                            if cLayer.localID == event.localID {
                                
                                print ("dragging \(cLayer.localID)")
                                
                                //populate array with y-points from Path for SSD
                                var fitPoints = [Float]()
                                for point in selectedFitPoints[cLayer.localID!]! {
                                    fitPoints.append(Float(point.y))
                                }
                                
                                //calculate SSD 
                                let SSD_size = Float(target.count)
                                print (fitPoints, target)
                                let normalisedSSD = calculateSSD (A: fitPoints, B: target) / SSD_size
                                // bad fit is red, good fit is green
                                let color = fitColor(worstSSD : worstSSD, currentSSD: normalisedSSD)
                                print (normalisedSSD, color)

                                //translate the path
                                let originalTransform = selectedTransforms[cLayer.localID!]
                                // original transform is the layer's transform at the start of the drag
                                // taps are within the layer so relative calculations not needed.
                                let tx = (currentLocationOfTap!.x - locationOfBeganTap!.x + originalTransform!.m41)
                                let ty = (currentLocationOfTap!.y - locationOfBeganTap!.y + originalTransform!.m42)
                                //print (tx,ty,cLayer.transform.m41, cLayer.transform.m42)
                                let newTransform = CATransform3DMakeTranslation(tx, ty, 0)
                                
                                CATransaction.begin()
                                CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                                cLayer.transform = newTransform
                                print ("ctn \(cLayer.transform.m41, cLayer.transform.m42)")
                                gaussianLayer.strokeColor = color.cgColor
                                CATransaction.commit()
                                
                                //update the points stored in the CustomLayer
                                //subtracting the original transform because included.
                                var updatedFitPoints = [CGPoint]()
                                let incrementalTransformX = tx - originalTransform!.m41
                                let incrementalTransformY = ty - originalTransform!.m42
                                
                                for point in selectedFitPoints[cLayer.localID!]! {
                                    let newPoint = CGPoint(x: point.x + incrementalTransformX, y: point.y + incrementalTransformY)
                                    updatedFitPoints.append(newPoint)
                                
                                cLayer.drawnPathPoints = updatedFitPoints
                                    
                                    
                                }
                            }
                        }
                    }
                    
                    
                   
                    
                    
                }//drag event(s) around
            }
            
        } else if gesture.state == UIGestureRecognizerState.ended {
            if selected.list.isEmpty {
            // store event details
                
            locationOfEndTap = gesture.location(in: self.view)
            print ("end one finger pan", locationOfEndTap!)
            
            //provide a choice here to get rid of the fit.
            //but what gesture?
            //what about resolving/overwriting?
            
            let graphicalAmplitude = Float((locationOfEndTap?.y)! - (locationOfBeganTap?.y)!)       //no conversion into real world units yet
            var fitEventToStore : chEvent?
            
            if graphicalAmplitude > 0 {
                fitEventToStore = chEvent(eKind: .opening)
            } else {
                fitEventToStore = chEvent(eKind: .shutting)         //this idea doesn't work because shuttings are not negative amp events!
            }
            // to retrieve event information from list later
            fitEventToStore!.localID = localCreationID
            // acccount for reverse (R -> L pan) fits with min and max
            let fittedStart = min (Float((locationOfBeganTap?.x)!), Float((locationOfEndTap?.x)!))
            let fittedEnd = max (Float((locationOfBeganTap?.x)!), Float((locationOfEndTap?.x)!))
            
            //storing screen coordinates right now, will adapt to real world coordinates later
            fitEventToStore!.timePt = fittedStart
            fitEventToStore!.amplitude = Double(graphicalAmplitude)
            fitEventToStore!.length = fittedEnd - fittedStart
            
            panCount += 1               //not sure if this is useful now.
           
            print (fitEventToStore!.printable())
            fitData.eventAppend(e: fitEventToStore!)
            //store information in that links this layer to this event and vice versa
            print (fitEventToStore!.registered, gaussianLayer.localID!)
            } else {
                
                //finish up with event dragging
                for event in selected.list {
                    for layer in (gesture.view?.layer.sublayers!)! {
                        if let cLayer = layer as? CustomLayer {
                            if cLayer.localID == event.localID {
                                let translation = cLayer.transform
                                //should do something about baseline/amplitude too
                                //length did not change
                                event.timePt += Float(translation.m41)
                            }
                        }
                    }
                    selected.removeEventByLocalID(ID: event.localID!)
                    selected.eventAppend(e: event)
                }
            }
        }
    }
   
    @IBAction func fitPan(_ gesture: UIPanGestureRecognizer) {
        
        // recognize pan and get coords
        if gesture.state == UIGestureRecognizerState.began {
            
            locationOfBeganTap = gesture.location(in: self.view)
            print ("began two finger pan", locationOfBeganTap!)
            localCreationID += 1
            
            averageY = (locationOfBeganTap?.y)!
            //print (String(format:"averageY: %@", averageY))
            
            fitLine = createHorizontalLine(startTap: locationOfBeganTap, endTap: locationOfBeganTap)
            // would be nice to color by SSD too.
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
                fitEventToStore.localID = localCreationID
                // to retrieve event information from list later
                fitEventToStore.localID = localCreationID
                // acccount for reverse (R -> L pan) fits with min and max
                let fittedStart = min (Float((locationOfBeganTap?.x)!), Float((locationOfEndTap?.x)!))
                let fittedEnd = max (Float((locationOfBeganTap?.x)!), Float((locationOfEndTap?.x)!))
                
                //storing screen coordinates right now, will adapt to real world coordinates later
                fitEventToStore.timePt = fittedStart
                fitEventToStore.amplitude = Double(averageY)
                fitEventToStore.length = fittedEnd - fittedStart
                
                panCount += 1
                print (fitEventToStore.printable(), fitEventToStore.localID)
                fitData.eventAppend(e: fitEventToStore)
                
            }
            
            //saveFitLine?
            
        }
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
    
    


    @IBAction func goBack(_ sender: Any) {
        print ("button")
        //pan count is not used any more.
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
