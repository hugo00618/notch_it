//
//  CellSelectDelegate.swift
//  Notch It
//
//  Created by Hugo Yu on 2017-11-21.
//  Copyright © 2017 Hugo Yu. All rights reserved.
//

import Foundation

protocol CellSelectDelegate {
    func onSelectCell(at: Int)
    func onDeselectCell(at: Int)
}
