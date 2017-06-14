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
    @IBOutlet weak var directoryControl: UISegmentedControl!
    
    //tables
    @IBOutlet weak var settingsTableView: UITableView!
    @IBOutlet weak var filesBrowserTableView: UITableView!
    
    let fileListCellReuseID = "DBFile"
    let cellReuseID = "standardSetting"
    let sliderCellReuseID = "sliderSetting"
    let toggleCellReuseID = "toggleSetting"
    
    var fileTableToggle = "documents"
    
    var localSettings : SettingsList?
    var settingsTableRows = [SettingsItem]()
    var DBFileRows = [FilesItem]()
    var documentsFileRows = [FilesItem]()
    var delegate: SettingsViewControllerDelegate? = nil
    var filenames: Array<String>?                           //not used?
    
  
    override func viewDidLoad() {
        super.viewDidLoad()
        filesBrowserTableView.dataSource = self
        filesBrowserTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.delegate = self

        let local = Storage()
        documentsFileRows = local.getFilesInDocumemtsDirectory()
        DBFileRows = getDropboxFiles()
        filesBrowserTableView.reloadData()
        
        unpackSettingsToTable()
        
        if settingsTableRows.count > 0 {
            return
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    @IBAction func directoryControl(_ sender: Any) {
        
        switch directoryControl.selectedSegmentIndex {
        case 0:
            print ("directory control toggled to local documents")
            fileTableToggle = "documents"
        case 1:
            print ("directory control toggled to Dropbox folder")
            fileTableToggle = "Dropbox"
        default:
            print ("illegal index for directory Control")
        }
        print ("fileTT \(fileTableToggle)")
        filesBrowserTableView.reloadData()
    }
    
    //this code taken from the example Dropbox Swift app integration.
    @IBAction func loginDropbox(_ sender: UIButton) {
        DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: self, openURL: {(url: URL) -> Void in UIApplication.shared.openURL(url)})
        filesBrowserTableView.reloadData()
        
    }
   
    func unpackSettingsToTable() {
        //expose all settings
        print ("Unpacking contents of settingsList to table rows")
        let localMirror = Mirror(reflecting:localSettings!)
        for (sName, sValue) in localMirror.children {
            settingsTableRows.append(sValue as! SettingsItem)
            print (sName!, sValue)
        }
    }
    
    
    
    func sliderChanged(sender: UISlider ) {
        let item = settingsTableRows[sender.tag]
        item.setValue(val: sender.value)
        //print (item, item.sVal, localSettings?.panAngleSensitivity)
        settingsTableView.reloadData()
    }
    
    // MARK: - Table view data sources
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == settingsTableView {
            return settingsTableRows.count
        } else {
            //file directory view
            if fileTableToggle == "Dropbox" {
                return DBFileRows.count
            } else {
                //local documents
                print ("ftt in rows", fileTableToggle)
                return documentsFileRows.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == settingsTableView {
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
                    cCell.sliderValue.text = String(format:"%.2f", item.getFloatValue())
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
        
        } else {
            var item : FilesItem
            if fileTableToggle == "Dropbox" {
                print("loading dropbox dir into table")
                //Dropbox File table
                item = DBFileRows[indexPath.row]
            } else {
                print("loading documents dir into table")
                //documents directory file table
                item = documentsFileRows[indexPath.row]
            }
            print (item)
            let cCell: FileListCell = tableView.dequeueReusableCell(withIdentifier: fileListCellReuseID, for: indexPath) as! FileListCell
            cCell.filenameLabel.text = item.filename
            cCell.fileSizeLabel.text = item.size
            cCell.fileDateLabel.text = item.date
            return cCell

            
            
        }

    }
    
    @IBAction func backToMain(_ sender: Any) {
        print ("Back button")
        delegate?.SettingsVCDidFinish(controller: self, updatedS: localSettings!)
    }
}
