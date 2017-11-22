//
//  UIShadowButton.swift
//  Notch It
//
//  Created by Hugo Yu on 2017-11-22.
//  Copyright © 2017 Hugo Yu. All rights reserved.
//

import UIKit

class UIShadowButton: UIButton {
    override open var isHighlighted: Bool {
        didSet {
                if (self.isHighlighted) {
                    self.backgroundColor = UIColor(hue: 192.0 / 360, saturation: 0.72, brightness: 0.72, alpha: 1)
                } else {
                    self.backgroundColor = UIColor(hue: 192.0 / 360, saturation: 0.72, brightness: 0.80, alpha: 1)
                }
        }
    }
}
