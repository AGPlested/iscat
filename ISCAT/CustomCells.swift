//
//  CustomSettingsCells.swift
//  ISCAT
//
//  Created by Andrew on 15/03/2017.
//  Copyright © 2017 Andrew. All rights reserved.
//

import UIKit

//cells for settings table

class CustomSettingCell: UITableViewCell {
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var SettingLabel: UILabel!
    @IBOutlet weak var SettingValue: UILabel!
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
}


//cells for event tables

class CustomEventCell: UITableViewCell {
    @IBOutlet weak var basicEventView: UIView!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var amplitude: UILabel!
    @IBOutlet weak var timePt: UILabel!
    @IBOutlet weak var kindOfEvent: UILabel!
    @IBOutlet weak var SSD: UILabel!
}
