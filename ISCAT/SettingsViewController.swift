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
    
    
    
    @IBOutlet weak var settingsView: UIView!
    @IBOutlet weak var BackButton: UIButton!

    @IBOutlet weak var tableView: UITableView!
    
    let cellReuseIdentifier = "customCell1"
    
    var localSettings : SettingsList?
    var settingsTableRows = [SettingsItem]()
    var delegate: SettingsViewControllerDelegate? = nil
    var filenames: Array<String>?
  
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        tableView.dataSource = self
        tableView.delegate = self
        
        // must *NOT* register the custom cell here if using interface builder!!!!!!
        //tableView.register(CustomSettingCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
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
        
        if settingsTableRows.count > 0 {
            return
        }
        //expose all settings
        print ("Unpacking contents of settingsList to table rows")
        let localMirror = Mirror(reflecting:localSettings!)
        for (sName, sValue) in localMirror.children {
            settingsTableRows.append(sValue as! SettingsItem)
            print (sName!, sValue)
            
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
        return settingsTableRows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cCell: CustomSettingCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! CustomSettingCell
        let item = settingsTableRows[indexPath.row]
        cCell.SettingLabel.text =  item.textLabel
        
        // handle the different types of setting value case-by-case
        switch item.sVal {
            case .integer:
                cCell.SettingValue.text = "\(item.getIntValue())"
            case .textParameter(let pVal):
                cCell.SettingValue.text =  pVal
            case .float:
                cCell.SettingValue.text! =  "\(item.getFloatValue())"
            default :
                cCell.SettingValue.text! =  "undefined value"
        }

        return cCell
    }
    
    @IBAction func backToMain(_ sender: Any) {
        print ("Back button")
        delegate?.SettingsVCDidFinish(controller: self, updatedS: localSettings!)
    }
}
