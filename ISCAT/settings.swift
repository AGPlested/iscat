//
//  settings.swift
//  ISCAT
//
//  Created by Andrew on 10/03/2017.
//  Copyright © 2017 Andrew. All rights reserved.
//

import UIKit

//define the kind of settings we want to have in the table
enum settingValue {
    case float(Double)
    case integer(Int)
    case textParameter(String)
    case toggle (Bool)
    case group (SettingsGroup)
}

//settings for the app as a whole at the moment
class SettingsList {
    
    //header at the start of Axograph binary (raw) data file is 3000 16-bits
    var header = SettingsItem(text: "Header", sValue: .integer(3000))
    
    //chunks to break trace data into
    var basicChunk = SettingsItem(text: "Chunk Size", sValue: .integer(100))
    
    //working directory
    var workingPath = SettingsItem(text: "Working Path", sValue: .textParameter("Dropbox"))
    
    //filename to save idealization to
    var idealizationFilename = SettingsItem(text: "Idealization", sValue: .textParameter("Test.txt"))
    
    //type of files
    
}

class SettingsGroup {
    var value = [String:Any]()
}

class SettingsItem: NSObject {
    // A text description of this item for UITableView.
    var textLabel: String
    
    // A Boolean value that determines the whether this control is active
    var active: Bool
    
    //provides information about how to display and edit the setting
    var sVal : settingValue
    
    // Returns a Settings Item initialized with the given text, kind and default 'active' and default value.
    
    init(text: String, sValue: settingValue) {
        textLabel = text

        active = true
        
        switch sValue {
        case .float:
            self.sVal = settingValue.float(0.0)
        case .integer:
            self.sVal = settingValue.integer(0)
        case .textParameter:
            self.sVal = settingValue.textParameter("Not defined yet.")
        case .toggle:
            self.sVal = settingValue.toggle(false)
        /*case .group:
            self.sVal = settingValue.group() */
        default:
            self.sVal = settingValue.textParameter("")
        }
    }

    @discardableResult func setValue(val: Any) -> Bool {
        switch sVal {
            
            case .integer(_) :
                self.sVal = settingValue.integer(val as! Int)
            case .float :
                self.sVal = settingValue.float(val as! Double)
            case .toggle :
                self.sVal = settingValue.toggle(val as! Bool)
            case .textParameter:
                self.sVal = settingValue.textParameter(val as! String)
            default:
                self.sVal = settingValue.textParameter("")
        }
        return true
    }
}
