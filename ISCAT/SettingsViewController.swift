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
    
    let cellReuseID = "standardSetting"
    let sliderCellReuseID = "sliderSetting"
    let toggleCellReuseID = "toggleSetting"
    
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
   
    func sliderChanged(sender: UISlider ) {
        let item = settingsTableRows[sender.tag]
        item.setValue(val: sender.value)
        print (item.sVal)
        //tableView.reloadData()
    }
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsTableRows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //dequeue different settings cells
        let item = settingsTableRows[indexPath.row]
        print (item)
        switch item.sVal {
            case .toggle:
                let cCell: ToggleSettingCell = tableView.dequeueReusableCell(withIdentifier: toggleCellReuseID, for: indexPath) as! ToggleSettingCell
                cCell.toggleLabel.text = "Toggle control"
                cCell.toggleSetting.isOn = true
                return cCell
            
            case .slider:
                let cCell: SliderSettingCell = tableView.dequeueReusableCell(withIdentifier: sliderCellReuseID, for: indexPath) as! SliderSettingCell
                
                cCell.settingSlider.value = Float(item.getFloatValue())
                cCell.sliderLabel.text =  item.textLabel
                cCell.sliderValue.text = String(item.getFloatValue())
                cCell.settingSlider.tag = indexPath.row
                cCell.settingSlider.addTarget(self, action: #selector(self.sliderChanged), for: .valueChanged)
                return cCell
                
            case .float :
                let cCell: StandardSettingCell = tableView.dequeueReusableCell(withIdentifier: cellReuseID, for: indexPath) as! StandardSettingCell
                cCell.standardValue.text =  "\(item.getFloatValue())"
                cCell.standardLabel.text = item.textLabel
                return cCell
            
            case .integer :
               let cCell: StandardSettingCell = tableView.dequeueReusableCell(withIdentifier: cellReuseID, for: indexPath) as! StandardSettingCell
               cCell.standardValue.text = "\(item.getIntValue())"
               cCell.standardLabel.text = item.textLabel
               return cCell
            
            default :
                let cCell: StandardSettingCell = tableView.dequeueReusableCell(withIdentifier: cellReuseID, for: indexPath) as! StandardSettingCell
                cCell.standardValue.text = item.getStringValue()
                cCell.standardLabel.text = item.textLabel
                return cCell
        }
    }
    
    @IBAction func backToMain(_ sender: Any) {
        print ("Back button")
        delegate?.SettingsVCDidFinish(controller: self, updatedS: localSettings!)
    }
}
