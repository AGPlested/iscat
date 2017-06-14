//  FittingViewController.swift
//  ISCAT
//
//  Created by Andrew on 24/08/2016.
//  Copyright © 2016 Andrew Plested. All rights reserved.
//
// input to fit algorithm
// run fitting command
// store fit command to reproduce
// snap?
// draw grid?
// live amplitude histogram, markable

import UIKit

protocol FitViewControllerDelegate {
    func FitVCDidFinish(controller: FittingViewController, leftEdge:Float, fit:eventList)
    }

class FittingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var delegate: FitViewControllerDelegate? = nil
    
    var screenPointsPerPicoA : CGFloat?
    var leftEdgeTime : Float?
    var progressCounter : Float = 0
    var pointsToFit = [Int16]()
    
    var settings : SettingsList!
    
    var fitLine: CustomLayer!               //sojourns
    
    var gaussianLayer: CustomLayer!         //gaussian filtered events
    var gaussianPath: CGPath!
    let gfit = GaussianFit(filter: 0.05)    //default fc as a function of sample frequency - should be a setting
    
    var localCreationID = 0
    var fitData = eventList()               //from Event.swift
    var selected = eventList()
    //a default container for information picked up a different stages of fitting gestures
    var fitEventToStore : Event?
    
    var previousEvents = eventList()
    var previous = completionView()
    
    //storage at the start of a dragging event
    var selectedTransforms = [Int: CATransform3D]()
    var selectedFitPoints = [Int: [CGPoint]]()
    var selectedEvents = [Int: StoredEvent]()       //stored event is a struct that stores values from Event classes
    
    var worstSSD : Float = 600 * 600               //per point, missing by entire screen
    
    //would be nice just to take the coordinates from the previous layout but couldn't work out how to do it.
    
    //screen and gesture parameters
    let yPlotOffset = CGFloat(200)
    let traceHeight = CGFloat(400)
    let fitWindow = CGPoint (x: 900, y: 600)
    let viewWidth = CGFloat(900)
    var screenPointsPerDataPoint : Float?
    var screenPointsPerMillisecond : Float?
    let openingsDown : Bool = true
    var gestureDecision : Bool = false
    let decisionRadius : CGFloat = 10   //10 pt movement during pan before deciding what gesture it is.
    var panEntry: Entries = .unclassified   //if updated during a pan, we know what event we created
    var decision: Bool = false
    var g : PanGestures = .notResolved
    var averageY: CGFloat = 0.0 //store for some events (Could calculate at the time?)
    
    //need to remember BeganTap
    var locationOfBeganTap: CGPoint?
    var currentLocationOfTap: CGPoint?
    var locationOfEndTap: CGPoint?
    
    //transformed points (as drawn) to be used for calcs
    var firstTapAsDrawn: CGPoint?
    var currentTapAsDrawn: CGPoint?
    var finalTapAsDrawn: CGPoint?
    
    
    @IBOutlet weak var console: UITableView!        //console is not used yet
    let cellReuseIdentifier = "eventCell"
    var consoleTableRows = [eventTableItem]()
    
    @IBOutlet weak var FitView: UIView!
    @IBOutlet weak var positionLabel: UILabel!
    
    @IBOutlet weak var storeFit: UIButton!
    @IBOutlet weak var selectedLabel: UILabel!
    
    @IBOutlet weak var rejectFit: UIButton!

    @IBOutlet weak var PopUpControl: UISegmentedControl!
    @IBOutlet weak var popUpControlLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var popUpControlBottomConstraint: NSLayoutConstraint!

    
    // these functions convert real world time (in ms) to screen points in this view, and back
    func timeToScreenPt (t: Float) -> Float {
        return (t - leftEdgeTime!) * screenPointsPerMillisecond!
    }
    
    func screenPtToTime (t: Float) -> Float {
        return t / screenPointsPerMillisecond! + leftEdgeTime!
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        fitTraceView(FitView: FitView, viewWidth: viewWidth, pointsToFit: pointsToFit, yOffset: yPlotOffset, traceHeight: traceHeight)
        
        //draw axes
        
        screenPointsPerDataPoint = Float(viewWidth) / Float(pointsToFit.count)
        screenPointsPerMillisecond = screenPointsPerDataPoint! * Float(settings.sampleRate.getFloatValue()) / 1000.0
        positionLabel.text = "Position in trace \(progressCounter) %"
        selectedLabel.text = "Nothing selected"
        console.dataSource = self
        console.delegate = self
        
        print ("Unpacking contents of eventList to console table rows")
        for event in fitData.list {
            let eventCellContents = eventTableItem(e: event)
            consoleTableRows.append (eventCellContents)
        }
        
        print (previousEvents.consolePrintable())
        print ("lET",leftEdgeTime!)
        previous.updateSegments(eventL: previousEvents, y: 50, samplePerMs: screenPointsPerMillisecond!, offset: leftEdgeTime!)
        previous.layer.opacity = 0.3
        FitView.addSubview(previous)
        
        
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // console - more or less same code as in EventsViewController
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return consoleTableRows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cCell: CustomEventCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! CustomEventCell
        let item = consoleTableRows[indexPath.row]
        cCell.timePt.text =  item.timePt
        cCell.duration.text =  item.duration
        cCell.amplitude.text =  item.amplitude
        cCell.kindOfEvent.text =  item.kOE
        cCell.SSD.text = item.SSD
        //cCell.backgroundColor = item.color
        
        cCell.backgroundColor = item.color?.withAlphaComponent(0.50)
        
        return cCell
    }

    
    @IBAction func drawnFitTap(_ sender: UITapGestureRecognizer) {
        
        let view = sender.view
        let loc = sender.location(in: view)
        print ("Single tap at \(loc).")
        var eventTapped: Bool = false
        if let hitting = view?.layer.hitTest(loc) {
            if hitting.sublayers != nil {
                for hitt in hitting.sublayers! {
                    if let hitCustom = hitt as? CustomLayer {
                    
                        //print ("Loc before", loc)
                        //this gets flaky and mixed up after awhile
                        let locConverted = hitCustom.convert(loc, from: hitCustom.superlayer) // try ? NO? move select/deselect detections to right place
                        //print ("Loc after", loc)
                        //print ("hC.sl,\(hitCustom.superlayer)")
                        //better for using the thick, invisible outline path
                        if (hitCustom.outlinePath.contains(loc)) || (hitCustom.outlinePath.contains(locConverted))   {
                            print ("You hit event \(hitCustom.localID!) at \(loc)")
                            eventTapped = true  //flag indicating something was hit
                            let tappedEvent = fitData.list.first(where: {$0.localID == hitCustom.localID!})
                            
                            if selected.hasEventWithID(ID: hitCustom.localID!) {
                                guard selected.removeEventByLocalID(ID: hitCustom.localID!) else {return}
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
                            
                            //still seems to be selecting below and confusedly???

                        }
                    }
                }
           
                if eventTapped != true {
                    //tapped on empty space so clear selection
                    for event in selected.list {
                        let eventID = event.localID
                        
                        //search through all possible layers for the one with eventID
                        for layer in hitting.sublayers!{
                            if let missedCustom = layer as? CustomLayer {
                                if missedCustom.localID == eventID {
                            //find relevant layer and fix thick/opacity
                                    CATransaction.begin()
                                    missedCustom.lineWidth = 5.0
                                    missedCustom.opacity = 1
                                    CATransaction.commit()
                                }
                            }
                        }
                        //remove from the selected list
                        guard selected.removeEventByLocalID(ID: eventID!) else {return}
                        print ("Deselected event \(eventID!)")
                    }
                }
            }
            selectedLabel.text = selected.consolePrintable(title: "Selected")
        }
    }
    
    @IBAction func longPress(_ gesture: UILongPressGestureRecognizer) {
        let longPressLocation = gesture.location(in: gesture.view)
        PopUpControl.isHidden = false
        PopUpControl.layer.zPosition = 1000
        popUpControlBottomConstraint.constant = 650.0 - longPressLocation.y
        popUpControlLeadingConstraint.constant = longPressLocation.x
    }
    
    @IBAction func popUpWasChanged(_ sender: UISegmentedControl, forEvent event: UIEvent) {
        print ("popup changed - delete triggered in this simple case")
        
        //deleting all selected events from the selected list and the list of fitData
        for selectedEvent in selected.list {
            //print (selectedEvent)
            let eventToDelete = selectedEvent.localID!
            let rmSelected = selected.removeEventByLocalID(ID: eventToDelete)
            if rmSelected == true {
                print ("Removed \(eventToDelete) from selected list.")
            }
            
            let rmFit = fitData.removeEventByLocalID(ID: eventToDelete)
            if rmFit == true {
                print ("Removed \(eventToDelete) from fitData list.")
            }
            
            for cLayer in FitView.layer.sublayers! {
                print (cLayer)
                if let customLayer = cLayer as? CustomLayer {
                    if customLayer.localID == eventToDelete {
                        customLayer.removeFromSuperlayer()
                        }
                    }
                }
            }
        
        //update console for fitted events - flat repopulation: no animation
        consoleTableRows = []
        for event in fitData.list {
            let eventForConsole = eventTableItem(e: event)
            consoleTableRows.append (eventForConsole)
        }
        console.reloadData()
        
        //update labels
        selectedLabel.text = selected.consolePrintable() //show empty
        //place a 250 ms delay on the disappearance of the pop-up control
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.PopUpControl.isHidden = true
            self.PopUpControl.selectedSegmentIndex = -1
        }
        
    }

    //this doesn't do a thing, yet need to frame popup and ask for touch outside of that
    @IBAction func touchOutsidePopUpControl(_ sender: Any)  {
        PopUpControl.isHidden = true
    }
    
    
    @IBAction func pinchEvent(_ gesture: UIPinchGestureRecognizer) {
        // if events are selected, this gesture will shrink or grow them.
        
        let pinchView = gesture.view
        if gesture.state == UIGestureRecognizerState.began {
            if selected.list.isEmpty  {
                print ("Pinch detected but nothing selected.")
            } else {
                let t0 = gesture.location(in: pinchView)
                let t1_start = gesture.location(ofTouch: 0, in: pinchView)
                let t2_start = gesture.location(ofTouch: 1, in: pinchView)
                //position is the average of the two touches
                //should probably store the initial positions and alter on difference
                //also store selected stats for live modifcation 
                //as in drag
                print ("pinch selected began", t0)
            }
        } else if gesture.state == UIGestureRecognizerState.changed {
            if selected.list.isEmpty {
                print ("nothing selected to pinch")
            } else {
                let t1_current = gesture.location(ofTouch: 0, in: pinchView)
                let t2_current = gesture.location(ofTouch: 1, in: pinchView)
                if gesture.velocity < 0 {
                    print ("I'm shrinking!")
                    //if event gets so small that it is gone, throw a popup event that asks 
                    //discard event or reset to original?
                
                } else {
                    print ("I'm growing awful fast.")
                }
                
                print ("pinch selected underway", t1_current, t2_current)
            }
        }   else if gesture.state == UIGestureRecognizerState.ended {
            if selected.list.isEmpty {
                print ("pinch finished - no action")
            } else {
                let t3 = gesture.location(in: pinchView)
                print ("pinch selected finished", t3)
                
                //if SSD got worse, ask?
                //SSD got worse, discard changes and reset or keep new event
            }
        }
    }
    
    @IBAction func fit2Pan(_ gesture: UIPanGestureRecognizer) {
        
        if gesture.state == UIGestureRecognizerState.began {
            
            locationOfBeganTap = gesture.location(in: gesture.view)

            if selected.list.isEmpty {
                print ("Began one finger pan at ", locationOfBeganTap!)
                //create event, unclassified at this point
                localCreationID += 1
                gestureDecision = false
                panEntry = .unclassified
                //wait to specify kind of event but allow SSD and color to update during gesture
                fitEventToStore = Event()
                fitEventToStore?.fitSSD = worstSSD
                fitEventToStore?.colorFitSSD = UIColor.red
                
                
            }
            else {
            //move selected items
                print ("Began one finger drag of item(s) \(selected) at ", locationOfBeganTap!)
                
                //containters to store selected events, layer transforms, and original x,y screen points
                selectedEvents = [:]
                selectedTransforms = [:]
                selectedFitPoints = [:]
                
                for event in selected.list {
                    for layer in (gesture.view?.layer.sublayers!)! {
                        if let cLayer = layer as? CustomLayer {
                            if cLayer.localID == event.localID {
                                
                                var stored = StoredEvent()    //struct not class, events not references to events, store in screen points local to this fit window
                                stored.timePt = timeToScreenPt(t: event.timePt)
                                stored.duration = event.duration! * screenPointsPerMillisecond!
                                //stored.amplitude = event.amplitude ///will need to include this later
                                stored.localID = cLayer.localID!
                                stored.kindOfEvent = event.kindOfEntry
                                stored.amplitude = Float(event.amplitude!) * Float(screenPointsPerPicoA!)      //in screen points
                                
                                selectedEvents[cLayer.localID!] = stored
                                selectedTransforms[cLayer.localID!] = cLayer.transform
                                selectedFitPoints[cLayer.localID!] = cLayer.drawnPathPoints
                            }
                        }
                    }
                }
            }
                
        } else if gesture.state == UIGestureRecognizerState.changed {
            //gesture is proceeding
            currentLocationOfTap = gesture.location(in: gesture.view)
            //globally transform to be relative to trace window to improve touch?
            
            if selected.list.isEmpty {
                //logic between lines (horizontal), events and transitions (vertical)
                
                //see if we decided already what event it is
                guard gestureDecision else {
                    //decision flag is set once, even if the gesture reverts within circle
                    gestureDecision = didEscapePanDecisionLimit(first: locationOfBeganTap!, current: currentLocationOfTap!, radius: Float(decisionRadius))
                    return
                }
                
                //if decision was made, we have to set what kind of event it is
                if panEntry == .unclassified {
                    
                        // arc value between 0 (diagonal pan off) and 1 (only diag pan)
                        let arc = Float(settings.panAngleSensitivity.getFloatValue())
                        panEntry = panArcEntry(first: locationOfBeganTap!, current: currentLocationOfTap!, arc: arc, openingsDown: true)
                    
                        fitEventToStore?.kindOfEntry = panEntry
                        // to retrieve event information from list later, layer gets same ID below
                        fitEventToStore!.localID = localCreationID
                    
                        switch panEntry {
                            
                            case .opening, .shutting :
                                //create filtered tophat event layer
                                gaussianPath = gfit.buildTopHatGaussPath(screenPPDP: screenPointsPerDataPoint!, firstTouch: locationOfBeganTap!, currentTouch: currentLocationOfTap!)
                                gaussianLayer = gfit.buildGaussLayer(gPath: gaussianPath)
                                gaussianLayer.localID = localCreationID
                                FitView.layer.addSublayer(gaussianLayer)
                            
                            case .sojourn   :
                                //create line fit to sojourn layer
                                averageY = (locationOfBeganTap?.y)!
                                //print (String(format:"averageY: %@", averageY))
                                fitLine = createHorizontalLine(startTap: locationOfBeganTap, endTap: currentLocationOfTap!)
                                fitLine.localID = localCreationID
                                FitView.layer.addSublayer(fitLine)
                            
                            case .transition:
                                //create filtered step transition
                                fitEventToStore?.duration = 0       // no duration
                                gaussianPath = gfit.buildGaussStepPath(screenPPDP: screenPointsPerDataPoint!, firstTouch: locationOfBeganTap!, currentTouch: currentLocationOfTap!)
                                gaussianLayer = gfit.buildGaussLayer(gPath: gaussianPath)
                                gaussianLayer.localID = localCreationID
                                FitView.layer.addSublayer(gaussianLayer)
                            
                            default: print("no logic for making an undefined event")
                        }
                } else {
                    //event was already created, we are now extending it
                    switch panEntry {
                        
                        //color is wrong here.
                        case .opening, .shutting : extendTopHatEvent(locationOfBeganTap: locationOfBeganTap!, currentLocationOfTap: currentLocationOfTap!, pointsToFit: pointsToFit, viewWidth: viewWidth, yPlotOffset: yPlotOffset, traceHeight: traceHeight, gfit: gfit, gaussianLayer: gaussianLayer , fitEventToStore: fitEventToStore!)
                            
                        case .sojourn : extendLineFit(locationOfBeganTap: locationOfBeganTap!, currentLocationOfTap: currentLocationOfTap!, pointsToFit: pointsToFit, viewWidth: viewWidth, yPlotOffset: yPlotOffset, traceHeight: traceHeight, fitLine: fitLine, fitEventToStore: fitEventToStore!)
                        
                        case .transition: extendStepEvent(locationOfBeganTap: locationOfBeganTap!, currentLocationOfTap: currentLocationOfTap!, pointsToFit: pointsToFit, viewWidth: viewWidth, yPlotOffset: yPlotOffset, traceHeight: traceHeight, gfit: gfit, gaussianLayer: gaussianLayer , fitEventToStore: fitEventToStore!)
                            
                        default: print("no logic for making an undefined event")
                    }
                }
            
            } else {
                // some events are selected so move paths around with live SSD
                // all events are references to classes.
                // has to handle all kinds of events (sojourn, top hat, transition)
                
                for (_, event) in selected.list.enumerated() {
                    for layer in (gesture.view?.layer.sublayers!)! {
                        if let cLayer = layer as? CustomLayer {
                            if cLayer.localID == event.localID {
                                print ("dragging custom layer \(cLayer.localID!)")
                                var targetDataPoints = [Int16]()
                                
                                var gaussianKernelWidth = gfit.kernel.count
                                
                                if event.kindOfEntry == .sojourn {
                                    gaussianKernelWidth = 0
                                }
                                
                                //pass initial event to get start of event at start of drag, not the updating event
                                targetDataPoints = getSliceDuringDrag(firstTouch: locationOfBeganTap!, currentTouch: currentLocationOfTap!, e: selectedEvents[cLayer.localID!]!, viewPoints: pointsToFit, viewW: Float(viewWidth), kernelWidth: gaussianKernelWidth)
                               
                                let target : [Float] = targetDataPoints.map { t in Float(yPlotOffset + traceHeight * CGFloat(t) / 32536.0 )} //to get screen point amplitudes
                                
                                //populate array with current y-points from path, for SSD
                                var fitPoints = [Float]()
                                for point in cLayer.drawnPathPoints {
                                    fitPoints.append(Float(point.y))
                                }
                                //print ("dPPx0: ", cLayer.drawnPathPoints[0])
                                //print ("event start x:", event.timePt - event.duration! / 5 - Float(gaussianKernelHalfWidth) * screenPointsPerDataPoint!)
                                
                                //calculate SSD
                                let SSD_size = Float(target.count)
                                //print (fitPoints, target)
                                let normalisedSSD = calculateSSD (A: fitPoints, B: target) / SSD_size
                                // bad fit is red, good fit is green
                                let color = fitColor(worstSSD : worstSSD, currentSSD: normalisedSSD)
                                //print ("SSD, col, fitLen, targLen: ", normalisedSSD, color, fitPoints.count, target.count)

                                //form translation for the path
                                let originalTransform = selectedTransforms[cLayer.localID!]
                                // original transform is the layer's transform at the start of the drag
                                // taps are within the layer so relative calculations not needed.
                                let tx = (currentLocationOfTap!.x - locationOfBeganTap!.x + originalTransform!.m41)
                                let ty = (currentLocationOfTap!.y - locationOfBeganTap!.y + originalTransform!.m42)
                                //print ("ctn \(tx,ty,originalTransform!.m41, originalTransform!.m42)")
                                let newTransform = CATransform3DMakeTranslation(tx, ty, 0)
                                
                                //translate and update SSD color code
                                CATransaction.begin()
                                CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                                cLayer.transform = newTransform
                                cLayer.strokeColor = color.cgColor
                                CATransaction.commit()
                                
                                //subtract the original transform because its included.
                                let incrementalTransformX = tx - originalTransform!.m41
                                let incrementalTransformY = ty - originalTransform!.m42
                                
                                //update with current transform from points (in screen coordinates) at the start of the drag.
                                var updatedFitPoints = [CGPoint]()
                                for point in selectedFitPoints[cLayer.localID!]! {
                                    let newPoint = CGPoint(x: point.x + incrementalTransformX, y: point.y + incrementalTransformY)
                                    updatedFitPoints.append(newPoint)
                                
                                cLayer.drawnPathPoints = updatedFitPoints   //the current points for the next round of SSD
                                
                                //moved outline drawing down to once only at the end because dragging complicated paths (tophats) was laggy
                                
                                //update with current transform from timePt at the start of the drag.
                                let savedEvent = selectedEvents[cLayer.localID!]
                                event.timePt = screenPtToTime(t: ((savedEvent?.timePt)! + Float(incrementalTransformX)) )
                                //only update the amplitude of a sojourn
                                //in a way it's nonsense. We need a baseline and amplitude for other events
                                if savedEvent?.kindOfEvent == .sojourn {
                                        event.amplitude =  Double(incrementalTransformY + CGFloat((savedEvent?.amplitude!)!) / screenPointsPerPicoA!)
                                    }
                                //update SSD and color for event
                                event.fitSSD! = normalisedSSD
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
                guard panEntry != .unclassified else {return}
                
                locationOfEndTap = gesture.location(in: gesture.view)
                print ("end one finger pan", locationOfEndTap!)
                
                //provide a choice here to get rid of the fit?
                //but what gesture?
                //what about resolving/overwriting?
                
                let graphicalAmplitude = Float((locationOfEndTap?.y)! - (locationOfBeganTap?.y)!)       //no conversion into real world units yet
                
 
                
                // acccount for reverse (R -> L pan) fits with min and max
                let fittedStart = min (Float((locationOfBeganTap?.x)!), Float((locationOfEndTap?.x)!))
                let fittedEnd = max (Float((locationOfBeganTap?.x)!), Float((locationOfEndTap?.x)!))
            
                //store times in ms
                if fitEventToStore?.kindOfEntry == .transition {
                    fitEventToStore!.timePt = screenPtToTime(t: Float((locationOfBeganTap?.x)!))
                } else {
                    fitEventToStore!.timePt = screenPtToTime(t: fittedStart)
                    fitEventToStore!.duration = (fittedEnd - fittedStart) / screenPointsPerMillisecond!
                }
                
                //screen points not real amplitude
                
                if fitEventToStore!.kindOfEntry == .sojourn {
                    fitEventToStore!.amplitude = Double(averageY / screenPointsPerPicoA!)
                } else {
                    fitEventToStore!.amplitude = Double(CGFloat(graphicalAmplitude) / screenPointsPerPicoA!)
                }
                
                //SSD and color are already stored during extending
                print (fitEventToStore!.printable())
                fitData.eventAppend(e: fitEventToStore!)
                //store information in that links this layer to this event and vice versa
                
                
            } else {
                
                //finish up with event dragging
                for event in selected.list {
                    for layer in (gesture.view?.layer.sublayers!)! {
                        if let cLayer = layer as? CustomLayer {
                            if cLayer.localID == event.localID {
                                print ("Finished dragging event \(String(describing: cLayer.localID))")
                                
                                //use the last drawn points to recreate the invisible fat outline layer
                                //for selection so must only be done once, at the end of the drag
                                //considerable lagginess when done at each step.
                                let finalFitPoints = cLayer.drawnPathPoints
                                let tempOutlinePath = UIBezierPath()
                                tempOutlinePath.move(to: finalFitPoints[0])
                                for i in 1 ..< finalFitPoints.count {
                                    tempOutlinePath.addLine(to: finalFitPoints[i])
                                }
                                //store the outline path
                                cLayer.outlinePath = tempOutlinePath.cgPath.copy( strokingWithWidth: 50,
                                                                                  lineCap: CGLineCap(rawValue: 0)!,
                                                                                  lineJoin: CGLineJoin(rawValue: 0)!,
                                                                                  miterLimit: 1) as! CGMutablePath

                            }
                        }
                    }
                }
            }
            //console update was here
        }
        //updating console with every step of the pan gesture??
        consoleTableRows = []
        for event in fitData.list {
            let eventForConsole = eventTableItem(e: event)
            consoleTableRows.append (eventForConsole)
        }
        console.reloadData() //nothing seems to happen yet...
    }
    
    @IBAction func rejectFit(_ sender: Any) {
        print ("Reject button")
        //return an empty list
        delegate?.FitVCDidFinish(controller: self, leftEdge: 0, fit: eventList())
    }

    @IBAction func goBack(_ sender: Any) {
        print ("Store and go back button")
        delegate?.FitVCDidFinish(controller: self, leftEdge: leftEdgeTime!, fit: fitData)
        
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
