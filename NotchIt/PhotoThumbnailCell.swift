//
//  PhotoThumbnailCell.swift
//  live-manager
//
//  Created by Hugo Yu on 2016-04-13.
//  Copyright © 2016 Hugo Yu. All rights reserved.
//

import UIKit

class PhotoThumbnailCell: UICollectionViewCell {
    
    let NOTCH_OFF_FACTOR: CGFloat = 1.1
    let NOTCH_SWITCH_ANIM_TIME = 0.2

    @IBOutlet weak var img_thumbnail: UIImageView!
    @IBOutlet weak var img_notch: UIImageView!
    @IBOutlet weak var img_tick: UIImageView!
    @IBOutlet weak var img_rotate: UIImageView!
    
    var isPortrait = true
    var notchOrientation = UIImageOrientation.left
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // add click listener to rotate
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(self.onClickRotate(_:)))
        singleTap.numberOfTapsRequired = 1
        img_rotate.isUserInteractionEnabled = true
        img_rotate.addGestureRecognizer(singleTap)
    }
    
    func updateSelectionView() {
        img_tick.isHidden = !isSelected
        img_rotate.isHidden = !isSelected || isPortrait // show rotate button only when cell is selected and cell is landscape
        
        if (isSelected) {
            setNotchOn()
        } else {
            setNotchOff()
        }
    }
    
    func setNotchOn() {
        let cellWidth = self.bounds.width
        let cellHeight = self.bounds.height
        
        if (!isPortrait) {
            notchOrientation = .left
            self.img_notch.transform = CGAffineTransform(rotationAngle: -90.0 * .pi / 180.0);
        }
        
        UIView.animate(withDuration: NOTCH_SWITCH_ANIM_TIME, animations: {() in
            if (self.isPortrait) {
                self.img_notch.bounds = CGRect(x: 0, y: 0, width: cellWidth, height: cellHeight)
            } else {
                self.img_notch.bounds = CGRect(x: 0, y: 0,
                                               width: cellHeight,
                                               height: cellWidth)
                self.img_rotate.isHidden = false;
            }
        })
    }
    
    func setNotchOff() {
        let cellWidth = self.bounds.width
        let cellHeight = self.bounds.height
        
        self.img_notch.center = CGPoint(x: cellWidth / 2.0, y: cellHeight / 2.0)
        if (!isPortrait) {
            self.img_notch.transform = CGAffineTransform(rotationAngle: -90.0 * .pi / 180.0)
        }
        
        UIView.animate(withDuration: NOTCH_SWITCH_ANIM_TIME, animations: {() in
            if (self.isPortrait) {
                print(cellWidth, cellHeight)
                self.img_notch.bounds = CGRect(x: 0, y: 0,
                                           width: cellWidth * self.NOTCH_OFF_FACTOR,
                                           height: cellHeight * self.NOTCH_OFF_FACTOR)
            } else {
                self.img_notch.bounds = CGRect(x: 0, y: 0,
                                               width: cellHeight * self.NOTCH_OFF_FACTOR,
                                               height: cellWidth * self.NOTCH_OFF_FACTOR)
                self.img_rotate.isHidden = true;
            }
        })
    }
    
    @objc func onClickRotate(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: NOTCH_SWITCH_ANIM_TIME / 2.0, animations: {() in
            // notch off animation
            let cellWidth = self.bounds.width
            let cellHeight = self.bounds.height
            self.img_notch.bounds = CGRect(x: 0, y: 0,
                                           width: cellHeight * self.NOTCH_OFF_FACTOR,
                                           height: cellWidth * self.NOTCH_OFF_FACTOR)
        }, completion: {(finished) in
            // change notch orientation
            if (self.notchOrientation == .left) {
                self.img_notch.transform = CGAffineTransform(rotationAngle: 90.0 * .pi / 180.0);
                self.notchOrientation = .right
            } else {
                self.img_notch.transform = CGAffineTransform(rotationAngle: -90.0 * .pi / 180.0);
                self.notchOrientation = .left
            }
            
            // notch on animation
            let cellWidth = self.bounds.width
            let cellHeight = self.bounds.height
            UIView.animate(withDuration: self.NOTCH_SWITCH_ANIM_TIME / 2.0, animations: {() in
                self.img_notch.bounds = CGRect(x: 0, y: 0,
                                               width: cellHeight,
                                               height: cellWidth)
            })
        })
    }
}
