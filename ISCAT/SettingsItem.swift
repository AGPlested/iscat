//
//  SettingsItem.swift
//  ISCAT
//
//  Created by Andrew on 10/03/2017.
//  Copyright © 2017 Andrew. All rights reserved.
//

import UIKit

class SettingsItem: NSObject {
    // A text description of this item.
    var text: String
    
    // A Boolean value that determines the whether this control is active
    var active: Bool
    
    // Returns a Settings Item initialized with the given text and default active value.
    init(text: String) {
        self.text = text
        self.active = true
    }
}
