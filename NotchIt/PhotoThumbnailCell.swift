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
    static let NOTCH_SWITCH_ANIM_TIME = 0.2

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
        
        updateSelectionView()
    }
    
    private func updateSelectionView() {
        img_tick.isHidden = !isSelected
        img_rotate.isHidden = !isSelected || isPortrait // show rotate button only when cell is selected and cell is landscape
        
        if (isSelected) {
            print(notchOrientation == .left)
            animateNotchOn()
        } else {
            animateNotchOff()
        }
    }
    
    func setNotchOnOff(on: Bool) {
        if (on) {
            notchOrientation = .left
        }
        updateSelectionView()
    }
    
    func animateNotchOn(duration: TimeInterval = PhotoThumbnailCell.NOTCH_SWITCH_ANIM_TIME, completion: ((Bool)->Void)? = nil) {
        let cellWidth = self.bounds.width
        let cellHeight = self.bounds.height
        
        self.img_notch.center = CGPoint(x: cellWidth / 2.0, y: cellHeight / 2.0)
        
        // set notch orientation
        if (isPortrait) {
            self.img_notch.transform = CGAffineTransform.identity
        } else {
            if (notchOrientation == .left) {
                self.img_notch.transform = CGAffineTransform(rotationAngle: -90.0 * .pi / 180.0)
            } else {
                self.img_notch.transform = CGAffineTransform(rotationAngle: 90.0 * .pi / 180.0)
            }
        }
        
        // shirnk notch size to make it visible
        UIView.animate(withDuration: duration, animations: {() in
            if (self.isPortrait) {
                self.img_notch.bounds = CGRect(x: 0, y: 0, width: cellWidth, height: cellHeight)
            } else {
                self.img_notch.bounds = CGRect(x: 0, y: 0,
                                               width: cellHeight,
                                               height: cellWidth)
            }
        }, completion: completion)
    }
    
    func animateNotchOff(duration: TimeInterval = PhotoThumbnailCell.NOTCH_SWITCH_ANIM_TIME,
                         completion: ((Bool)->Void)? = nil) {
        let cellWidth = self.bounds.width
        let cellHeight = self.bounds.height
        
        self.img_notch.center = CGPoint(x: cellWidth / 2.0, y: cellHeight / 2.0)
        
        // enlarge notch size to make it invisible
        UIView.animate(withDuration: duration, animations: {() in
            if (self.isPortrait) {
                self.img_notch.bounds = CGRect(x: 0, y: 0,
                                           width: cellWidth * self.NOTCH_OFF_FACTOR,
                                           height: cellHeight * self.NOTCH_OFF_FACTOR)
            } else {
                self.img_notch.bounds = CGRect(x: 0, y: 0,
                                               width: cellHeight * self.NOTCH_OFF_FACTOR,
                                               height: cellWidth * self.NOTCH_OFF_FACTOR)
            }
        }, completion: completion)
    }
    
    @objc func onClickRotate(_ sender: UITapGestureRecognizer) {
        // animate off
        animateNotchOff(duration: PhotoThumbnailCell.NOTCH_SWITCH_ANIM_TIME / 2.0, completion: {(finished) in
            
            // change notch orientation
            if (self.notchOrientation == .left) {
                self.img_notch.transform = CGAffineTransform(rotationAngle: 90.0 * .pi / 180.0);
                self.notchOrientation = .right
            } else {
                self.img_notch.transform = CGAffineTransform(rotationAngle: -90.0 * .pi / 180.0);
                self.notchOrientation = .left
            }
            
            // animate back on
            self.animateNotchOn(duration: PhotoThumbnailCell.NOTCH_SWITCH_ANIM_TIME / 2.0)
        })
    }
}
