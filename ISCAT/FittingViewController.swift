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
   
    var fitEventToStore : Event?
    //a default container for information picked up a different stages of fitting gestures
    
    let gfit = GaussianFit(filter: 0.05)    //default fc as a function of sample frequency - should be a setting
    
    var fitData = eventList()               //from Event.swift
    var selected = eventList()
    
    //storage at the start of a dragging event
    var selectedTransforms = [Int: CATransform3D]()
    var selectedFitPoints = [Int: [CGPoint]]()
    var selectedEvents = [Int: StoredEvent]()       //stored event is a struct that stores values from Event classes
    
    var worstSSD : Float = 600 * 600               //per point, missing by entire screen
    
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
    
    @IBOutlet weak var storeFit: UIButton!
    @IBOutlet weak var selectedLabel: UILabel!
    
    @IBOutlet weak var rejectFit: UIButton!

    @IBOutlet weak var PopUpControl: UISegmentedControl!
        
    func fitTraceView() {
        //draw a fixed data trace on the screen
        
        screenPointsPerDataPoint = Float(viewWidth) / Float(pointsToFit.count)    //900
        print ("traceview: pointsTF, sPPDP", pointsToFit.count, screenPointsPerDataPoint!)
        
        let firstDataPoint = CGPoint(x:0, y:yPlotOffset)
        var drawnDataPoint : CGPoint
        
        FitView.backgroundColor = UIColor.white
        FitView.translatesAutoresizingMaskIntoConstraints = false
            
        //drawing trace
        let thickness: CGFloat = 2.0
        let tracePath = UIBezierPath()
        tracePath.move(to: firstDataPoint)
        
        for (index, point) in pointsToFit.enumerated() {
            let xPoint = CGFloat ( screenPointsPerDataPoint! * Float (index) )
            drawnDataPoint = CGPoint(x: xPoint, y: yPlotOffset + traceHeight * CGFloat(point) / 32536.0)
            tracePath.addLine(to: drawnDataPoint)
        }
        
        // render to layer
        let traceLayer = CAShapeLayer()
        traceLayer.path = tracePath.cgPath
        traceLayer.lineJoin = kCALineJoinRound
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
        var loc = sender.location(in: view)
        
        if let hitting = view?.layer.hitTest(loc) {
            if hitting.sublayers != nil {
                for hitt in hitting.sublayers! {
                    if let hitCustom = hitt as? CustomLayer {
                    
                        //print ("Loc before", loc)
                        //this gets flaky and mixed up after awhile
                        loc = hitCustom.convert(loc, from: hitCustom.superlayer) // try ? NO? move select/deselect detections to right place
                        //print ("Loc after", loc)
                        //print ("hC.sl,\(hitCustom.superlayer)")
                        if (hitCustom.path?.contains(loc))!  {
                            print ("You hit event \(hitCustom.localID!) at \(loc)")
                            let tappedEvent = fitData.list.first(where: {$0.localID == hitCustom.localID!})
                            
                            if selected.hasEventWithID(ID: hitCustom.localID!) {
                                selected.removeEventByLocalID(ID: hitCustom.localID!)
                                //animated
                                CATransaction.begin()
                                hitCustom.lineWidth = 5.0
                                hitCustom.opacity = 1
                                CATransaction.commit()
                                print ("Deselected event \(hitCustom.localID!)")
                            } else {
                                selected.eventAppend(e: tappedEvent!)
                                CATransaction.begin()
                                hitCustom.lineWidth = 10.0
                                hitCustom.opacity = 0.5
                                CATransaction.commit()
                                print ("Selected event \(hitCustom.localID!)")
                            }
                            
                            //should be a function to update labels/console
                            selectedLabel.text = selected.consolePrintable(title: "Selected")
                            
                            
                
                            
                            //selectDONE, deselectDONE, delete, move DONE, show DONE....

                            
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func longPress(_ sender: UILongPressGestureRecognizer) {
        PopUpControl.isHidden = false
        PopUpControl.layer.zPosition = 1000
        
    }
    
    //disappears too fast
    @IBAction func popUpWasChanged(_ sender: UISegmentedControl, forEvent event: UIEvent) {
        print ("popup changed")
        PopUpControl.isHidden = true
        PopUpControl.selectedSegmentIndex = -1
    }

    //this doesn't do a thing, yet need to frame popup and ask for
    @IBAction func touchOutsidePopUpControl(_ sender: Any)  {
        PopUpControl.isHidden = true
    }
    
    
    @IBAction func pinchEvent(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == UIGestureRecognizerState.began {
            if selected.list.isEmpty  {
                print ("pinch but nothing selected")
            } else {
                print ("pinch selected began")
            }
        } else if gesture.state == UIGestureRecognizerState.changed {
            if selected.list.isEmpty {
                print ("nothing selected to pinch")
            } else {
                print ("pinch selected underway")
            }
        }   else if gesture.state == UIGestureRecognizerState.ended {
            if selected.list.isEmpty {
                print ("pinch finished - no action")
            } else {
                print ("pinch selected finished")
            }
        }
    }
    
    @IBAction func fit2Pan(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == UIGestureRecognizerState.began {
            fitEventToStore = Event()
            //unclassified at this point
            //created now so SSD and color can be stored during gesture
            
            locationOfBeganTap = gesture.location(in: self.view)
            if selected.list.isEmpty {
            // create event
                print ("Began one finger pan.", locationOfBeganTap!)
                localCreationID += 1
                
                // console.dataSource()
                gaussianPath = gfit.buildGaussPath(screenPPDP: screenPointsPerDataPoint!, firstTouch: locationOfBeganTap!, currentTouch: locationOfBeganTap!, window: fitWindow)
                gaussianLayer = gfit.buildGaussLayer(gPath: gaussianPath)
                gaussianLayer.localID = localCreationID
                // event created is linked to layer for later
                FitView.layer.addSublayer(gaussianLayer)
            }
            else {
            //move selected
                print ("Began one finger drag of \(selected).", locationOfBeganTap!)
                
                //store initial selected layer transforms
                //store initial coordinates of selected events
                //store x, y points of initial fits as drawn on the screen
                
                //provide empty dictionaries for the start of the drag.
                selectedEvents = [:]
                selectedTransforms = [:]
                selectedFitPoints = [:]
                
                for event in selected.list {
                    for layer in (gesture.view?.layer.sublayers!)! {
                        if let cLayer = layer as? CustomLayer {
                            if cLayer.localID == event.localID {
                                var stored = StoredEvent()          //struct not class
                                stored.timePt = event.timePt
                                stored.duration = event.duration
                                //stored.amplitude = event.amplitude ///will need to change this later
                                stored.localID = cLayer.localID!
                                
                                selectedEvents[cLayer.localID!] = stored
                                selectedTransforms[cLayer.localID!] = cLayer.transform
                                selectedFitPoints[cLayer.localID!] = cLayer.drawnPathPoints
                            }
                        }
                    }
                }
            }
                
        } else if gesture.state == UIGestureRecognizerState.changed {
            currentLocationOfTap = gesture.location(in: self.view)
            //globally transform to be relative to trace window?
            
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
                fitEventToStore!.fitSSD = normalisedSSD
                fitEventToStore!.colorFitSSD = color
                
                // write out SSD and event length (in samples - convert easily later).
                
                // draw the latest curve, colored to previous SSD.
                CATransaction.begin()
                CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                gaussianLayer.path = gfit.buildGaussPath(screenPPDP: screenPointsPerDataPoint!, firstTouch: locationOfBeganTap!, currentTouch: currentLocationOfTap!, window: fitWindow)
                gaussianLayer.drawnPathPoints = gfit.drawnPath
                gaussianLayer.strokeColor = color.cgColor
                CATransaction.commit()
                
                
            
            } else {
                // some events are selected
                // move paths around with live SSD
                // all events are chEvents - therefore references to classes.
                
                for (eNum, event) in selected.list.enumerated() {
                    for layer in (gesture.view?.layer.sublayers!)! {
                        if let cLayer = layer as? CustomLayer {
                            if cLayer.localID == event.localID {
                                print ("dragging custom layer \(cLayer.localID!)")
                                
                                //pass initial event to get start of event at start of drag, not the updating event
                                let targetDataPoints = getSliceDuringDrag(firstTouch: locationOfBeganTap!, currentTouch: currentLocationOfTap!, e: selectedEvents[cLayer.localID!]!, viewPoints: pointsToFit, viewW: Float(viewWidth), kernelHalfWidth: gaussianKernelHalfWidth)
                                
                                let target : [Float] = targetDataPoints.map { t in Float(yPlotOffset + traceHeight * CGFloat(t) / 32536.0 )} //to get screen point amplitudes
                                
                                //populate array with current y-points from Path for SSD
                                var fitPoints = [Float]()
                                for point in cLayer.drawnPathPoints {
                                    fitPoints.append(Float(point.y))
                                }
                                print ("dPPx0: ", cLayer.drawnPathPoints[0])
                                print ("event start x:", event.timePt - event.duration! / 5 - Float(gaussianKernelHalfWidth) * screenPointsPerDataPoint!)
                                //calculate SSD 
                                let SSD_size = Float(target.count)
                                //print (fitPoints, target) //target is off in x but fitpoints is disastrous in y (much too large!!!)
                                let normalisedSSD = calculateSSD (A: fitPoints, B: target) / SSD_size
                                // bad fit is red, good fit is green
                                let color = fitColor(worstSSD : worstSSD, currentSSD: normalisedSSD)
                                print ("SSD, col, fitLen, targLen: ", normalisedSSD, color, fitPoints.count, target.count)

                                //translate the path
                                let originalTransform = selectedTransforms[cLayer.localID!]
                                // original transform is the layer's transform at the start of the drag
                                // taps are within the layer so relative calculations not needed.
                                let tx = (currentLocationOfTap!.x - locationOfBeganTap!.x + originalTransform!.m41)
                                let ty = (currentLocationOfTap!.y - locationOfBeganTap!.y + originalTransform!.m42)
                                print ("ctn \(tx,ty,originalTransform!.m41, originalTransform!.m42)")
                                let newTransform = CATransform3DMakeTranslation(tx, ty, 0)
                                
                                CATransaction.begin()
                                CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                                cLayer.transform = newTransform
                                cLayer.strokeColor = color.cgColor
                                CATransaction.commit()
                                
                                //subtracting the original transform because its included.
                                let incrementalTransformX = tx - originalTransform!.m41
                                let incrementalTransformY = ty - originalTransform!.m42
                                
                                //update with current transform from points (in screen coordinates) at the start of the drag.
                                var updatedFitPoints = [CGPoint]()
                                for point in selectedFitPoints[cLayer.localID!]! {
                                    let newPoint = CGPoint(x: point.x + incrementalTransformX, y: point.y + incrementalTransformY)
                                    updatedFitPoints.append(newPoint)
                                
                                cLayer.drawnPathPoints = updatedFitPoints   //the current points for the next round of SSD
                                
                                //update with current transform from timePt at the start of the drag.
                                let savedEvent = selectedEvents[cLayer.localID!]
                                event.timePt = (savedEvent?.timePt)! + Float(incrementalTransformX)
                                
                                //update SSD and color for event
                                event.fitSSD = normalisedSSD
                                event.colorFitSSD = color
                            
                                }
                            }
                        }
                    }
                }
            }
            
        } else if gesture.state == UIGestureRecognizerState.ended {
            if selected.list.isEmpty {
            // store new event details
                
            locationOfEndTap = gesture.location(in: self.view)
            print ("end one finger pan", locationOfEndTap!)
            
            //provide a choice here to get rid of the fit?
            //but what gesture?
            //what about resolving/overwriting?
            
            let graphicalAmplitude = Float((locationOfEndTap?.y)! - (locationOfBeganTap?.y)!)       //no conversion into real world units yet
            
            if graphicalAmplitude > 0 {
                fitEventToStore!.kindOfEntry = Entries.opening
            } else {
                fitEventToStore!.kindOfEntry = Entries.shutting
                //this idea doesn't work because shuttings are not negative amp events!
            }
            // to retrieve event information from list later
            fitEventToStore!.localID = localCreationID
            // acccount for reverse (R -> L pan) fits with min and max
            let fittedStart = min (Float((locationOfBeganTap?.x)!), Float((locationOfEndTap?.x)!))
            let fittedEnd = max (Float((locationOfBeganTap?.x)!), Float((locationOfEndTap?.x)!))
            
            //storing screen coordinates right now, will adapt to real world coordinates later
            fitEventToStore!.timePt = fittedStart
            fitEventToStore!.amplitude = Double(graphicalAmplitude)
            fitEventToStore!.duration = fittedEnd - fittedStart
            //SSD and color are already stored during drag
            
            //panCount += 1               //not sure if this is useful now.
           
            print (fitEventToStore!.printable())
            fitData.eventAppend(e: fitEventToStore!)
            //store information in that links this layer to this event and vice versa
            print (fitEventToStore!.registered!, gaussianLayer.localID!)
            } else {
                
                //finish up with event dragging
                for event in selected.list {
                    for layer in (gesture.view?.layer.sublayers!)! {
                        if let cLayer = layer as? CustomLayer {
                            if cLayer.localID == event.localID {
                                print ("Finished dragging event \(cLayer.localID)")
                                //each event was updated in place during the drag
                            }
                        }
                    }
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
                let fitEventToStore = Event(.sojourn)
                fitEventToStore.localID = localCreationID
                // to retrieve event information from list later
                // acccount for reverse (R -> L pan) fits with min and max
                let fittedStart = min (Float((locationOfBeganTap?.x)!), Float((locationOfEndTap?.x)!))
                let fittedEnd = max (Float((locationOfBeganTap?.x)!), Float((locationOfEndTap?.x)!))
                
                //storing screen coordinates right now, will adapt to real world coordinates later
                fitEventToStore.timePt = fittedStart
                fitEventToStore.amplitude = Double(averageY)
                fitEventToStore.duration = fittedEnd - fittedStart
                
                panCount += 1
                print (fitEventToStore.printable(), fitEventToStore.localID!)
                fitData.eventAppend(e: fitEventToStore)
                
            }
            
            //saveFitLine?
            
        }
    }
        

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
    
    
    @IBAction func rejectFit(_ sender: Any) {
        print ("reject button")
        delegate?.FitVCDidFinish(controller: self, touches: panCount, fit: eventList())
    }


    @IBAction func goBack(_ sender: Any) {
        print ("store button")
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
