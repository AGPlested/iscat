//
//  CustomSettingsCells.swift
//  ISCAT
//
//  Created by Andrew on 15/03/2017.
//  Copyright © 2017 Andrew. All rights reserved.
//

import UIKit

class CustomSettingCell: UITableViewCell {

    @IBOutlet weak var view: UIView!
    @IBOutlet weak var SettingLabel: UILabel!
    @IBOutlet weak var SettingValue: UILabel!
}

class CustomEventCell: UITableViewCell {
    @IBOutlet weak var basicEventView: UIView!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var amplitude: UILabel!
    @IBOutlet weak var timePt: UILabel!
    @IBOutlet weak var kindOfEvent: UILabel!
    @IBOutlet weak var SSD: UILabel!

}
