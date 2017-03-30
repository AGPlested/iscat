//
//  CustomSettingsCells.swift
//  ISCAT
//
//  Created by Andrew on 15/03/2017.
//  Copyright © 2017 Andrew. All rights reserved.
//

import UIKit

//cells for settings table

//seems like there is little point because these different classes must be passed back from the same data source.

class StandardSettingCell: UITableViewCell {
    
    @IBOutlet weak var standardSettingView: UIView!
    @IBOutlet weak var standardLabel: UILabel!
    @IBOutlet weak var standardValue: UILabel!
}

class ToggleSettingCell: UITableViewCell {
    @IBOutlet weak var toggleContentView: UIView!
    @IBOutlet weak var toggleSetting: UISwitch!
    @IBOutlet weak var toggleLabel: UILabel!
}

class SliderSettingCell: UITableViewCell {
    @IBOutlet weak var sliderContentView: UIView!
    @IBOutlet weak var sliderLabel: UILabel!
    @IBOutlet weak var settingSlider: UISlider!
    @IBOutlet weak var sliderValue: UILabel!
    
}


//cells for event tables
//these cells are on the main screen 

class RecentFitCell: UITableViewCell {
    @IBOutlet weak var recentFitCellView: UIView!
    @IBOutlet weak var eventsLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var orderLabel: UILabel!
}


class CustomEventCell: UITableViewCell {
    @IBOutlet weak var basicEventView: UIView!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var amplitude: UILabel!
    @IBOutlet weak var timePt: UILabel!
    @IBOutlet weak var kindOfEvent: UILabel!
    @IBOutlet weak var SSD: UILabel!
}
