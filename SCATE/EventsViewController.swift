//
//  EventsViewController.swift
//  ISCAT
//
//  Created by Andrew on 22/03/2017.
//  Copyright © 2017 Andrew. All rights reserved.
//

import UIKit
import SwiftyDropbox

protocol EventsViewControllerDelegate {
    func EventsVCDidFinish(controller: EventsViewController, updatedEvents: eventList)
    
    //add stuff to pass here
}

class EventsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    @IBOutlet weak var eventView: UIView!
    @IBOutlet weak var backButton: UIButton!    
    @IBOutlet weak var eventTable: UITableView!
    
    
    let cellReuseIdentifier = "eventCell"
    
    var localEventsList = eventList()
    var eventTableRows = [eventTableItem]()
    var delegate: EventsViewControllerDelegate? = nil
    var filenames: Array<String>?
  
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        eventTable.dataSource = self
        eventTable.delegate = self
        
        
        if let client = DropboxClientsManager.authorizedClient {
            _ = client.files.listFolder(path: "").response { response, error in
                if let result = response {
                    print("Dropbox folder contents:")
                    for entry in result.entries {
                        print(entry.name)
                        self.filenames?.append(entry.name)
                        }
                    }
            }
        }
        
        //print (localSettings!.basicChunk.textLabel)
        print ("Unpacking contents of eventList to table rows")
        for event in localEventsList.list {
            let eventCellContents = eventTableItem(e: event)
            eventTableRows.append (eventCellContents)
        
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    //this code taken from the example Dropbox Swift app integration.
    @IBAction func loginDropbox(_ sender: UIButton) {
        
        DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: self, openURL: {(url: URL) -> Void in UIApplication.shared.openURL(url)})
    }
   
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventTableRows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cCell: CustomEventCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! CustomEventCell
        let item = eventTableRows[indexPath.row]
        cCell.timePt.text =  item.timePt
        cCell.duration.text =  item.duration
        cCell.amplitude.text =  item.amplitude
        cCell.kindOfEvent.text =  item.kOE
        cCell.SSD.text = item.SSD
        cCell.backgroundColor = item.color
        // handle the different types of setting value case-by-case

        return cCell
    }
    

    @IBAction func backFromEvents(_ sender: Any) {
        print ("Back button events")
        delegate?.EventsVCDidFinish(controller: self, updatedEvents: localEventsList)
    }
    
}
