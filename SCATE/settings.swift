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
    case slider (Float)
}

//settings for the app as a whole at the moment
class SettingsList  {
    
    
    //header at the start of Axograph binary (raw) data file is 3k 16-bit words?
    var header = SettingsItem(text: "Header",
                                sValue: .integer(3072))
    
    //sample rate
    var sampleRate = SettingsItem(text: "Sampling Rate",
                                sValue: .float(20000))
    
    //amplifier gain
    var gain = SettingsItem(text: "Gain (α)",
                                  sValue: .float(10000))
    
    //working directory
    var workingPath = SettingsItem(text: "Working Path",
                                sValue: .textParameter("Dropbox"))
    
    //filename to save idealization to
    var idealizationFilename = SettingsItem(text: "Idealization",
                                sValue: .textParameter("Test.txt"))
    
    var dataFilename = SettingsItem(text: "Datafile",
                                    sValue: .textParameter("sim1600"))
    
    //type of files
    var rawDataFileType = SettingsItem(text: "Input data file type",
                                sValue: .textParameter("Axograph Binary"))
    
    // control of
    var panAngleSensitivity = SettingsItem(text: "Pan arc",
                                sValue: .slider(0.5))
    
}

class SettingsGroup {
    var value = [String:Any]()
}

class SettingsItem: NSObject {
    // A text description of this item for UITableView.
    var textLabel: String
    
    var helperText: String?
    // optional helper text
    
    // A Boolean value that determines the whether this control is active
    var active: Bool
    
    //provides information about how to display and edit the setting, and its value
    var sVal : settingValue
    
    // Returns a Settings Item initialized with the given text, kind and default 'active' and default value.
    
    init(text: String, sValue: settingValue) {
        textLabel = text
        
        active = true
        
        switch sValue {
        case let .float(val):
            self.sVal = settingValue.float(val)
        case let .integer(val):
            self.sVal = settingValue.integer(val)
        case let .textParameter(val):
            self.sVal = settingValue.textParameter(val)
        case let .toggle(val):
            self.sVal = settingValue.toggle(val)
        case let .slider(val):
            self.sVal = settingValue.slider(val)
        /*case .group:
            self.sVal = settingValue.group() */
        default:
            self.sVal = settingValue.textParameter("Not defined yet.")
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
            case .slider:
                self.sVal = settingValue.slider(val as! Float)
            default:
                self.sVal = settingValue.textParameter("")
        }
        return true
    }
    
    func getIntValue () -> (Int) {
        switch sVal {
            case .integer(let integerValue) :
                return integerValue
            default:
                return 0
        }
    }
    
    func getFloatValue () -> (Double) {
        switch sVal {
            case .float(let floatValue) :
                return floatValue
            case .slider(let sliderValue) :
                return Double(sliderValue)
            default:
                return 0
        }
    }
    
    func getStringValue () -> String {
        switch sVal {
            case .textParameter(let textValue) :
                return textValue
            default:
                return ""
        }

    }
    

}
