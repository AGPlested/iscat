//
//  SettingsViewController.swift
//  ISCAT
//
//  Created by Andrew on 09/03/2017.
//  Copyright © 2017 Andrew. All rights reserved.
//

import UIKit
import SwiftyDropbox

protocol SettingsViewControllerDelegate {
    func SettingsVCDidFinish(controller: SettingsViewController, updatedS: SettingsList)
    //add stuff to pass here
}

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var BackButton: UIButton!
    @IBOutlet weak var SettingsView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var localSettings : SettingsList?
    var settingsList = [SettingsItem]()
    var delegate: SettingsViewControllerDelegate? = nil
    var filenames: Array<String>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let client = DropboxClientsManager.authorizedClient {
            _ = client.files.listFolder(path: "").response { response, error in
                if let result = response {
                    print("Folder contents:")
                    for entry in result.entries {
                        print(entry.name)
                        self.filenames?.append(entry.name)
                        }
                    }

            }
        }
        
        print (localSettings!.basicChunk)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        if settingsList.count > 0 {
            return
        }
        
        let mirrorSettings = Mirror(reflecting: localSettings!)
        for attrib in mirrorSettings.children {
            print (attrib.label!,attrib.value)
            switch attrib.value {
                default:
                    print ("crap")
                    //settingsList.append(SettingsItem(text: String(format:"%@ : %@", attrib.label!, String(describing: attrib.value ))))
            }
            
            
           
        // Do any additional setup after loading the view.
    
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
        return settingsList.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell",
                                                 for: indexPath as IndexPath)
        let item = settingsList[indexPath.row]
        //cell.textLabel?.textLabel = item.text
        return cell
    }
    
    @IBAction func backToMain(_ sender: Any) {
        print ("Back button")
        delegate?.SettingsVCDidFinish(controller: self, updatedS: localSettings!)
    }
}
