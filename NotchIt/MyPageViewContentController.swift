//
//  MyPageViewContentController.swift
//  Notch It
//
//  Created by Hugo Yu on 2017-11-16.
//  Copyright © 2017 Hugo Yu. All rights reserved.
//

import UIKit
import Photos

class MyPageViewContentController: UIViewController {
    let NOTCH_OFF_FACTOR: CGFloat = 1.1
    static let NOTCH_SWITCH_ANIM_TIME = 0.15
    
    // model
    var index = 0
    var thumbnailAsset: PHAsset!
    var isSelected = false
    var isPortrait = true
    var notchLeft = true
    var selectDelegate: CellSelectDelegate!
    
    // view
    @IBOutlet weak var view_imageContainerOuter: UIView!
    @IBOutlet weak var constraint_outerRatio: NSLayoutConstraint!
    @IBOutlet weak var constraint_outerRatioLandscape: NSLayoutConstraint!
    @IBOutlet weak var constraint_outerLeading: NSLayoutConstraint!
    @IBOutlet weak var constraint_outerBottom: NSLayoutConstraint!
    @IBOutlet weak var view_imageContainerInner: UIView!
    @IBOutlet weak var image_thumbnail: UIImageView!
    @IBOutlet weak var image_tick: UIImageView!
    @IBOutlet weak var image_rotate: UIImageView!
    @IBOutlet weak var image_notch: UIImageView!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // show no photos prompt
        if (thumbnailAsset == nil) {
            self.view.isHidden = true
            return
        }
        
        // view
        // request thumbnail
        let scale = UIScreen.main.scale
        var targetSize = self.image_thumbnail.bounds.size
        targetSize.width *= scale
        targetSize.height *= scale
        ImageUtils.requestImage(asset: thumbnailAsset, targetSize: targetSize, resultHandler: {(result, info) in
            // set thumbnail image
            self.image_thumbnail.image = result
            
            // if is landscape
            let resultSize = result!.size
            if (resultSize.width > resultSize.height) { // if landscape
                self.isPortrait = false
                
                DispatchQueue.main.async(execute: {
                    // switch to landscape constraints
                    self.constraint_outerRatio.isActive = false
                    self.constraint_outerRatioLandscape.isActive = true
                    self.constraint_outerBottom.isActive = false
                    self.constraint_outerLeading.isActive = true
                    self.view.layoutIfNeeded()
                    
                    // re-init view
                    self.initView()
                })
            }
        })
        
        // add shadow to boundary
        let containerOuterLayer = self.view_imageContainerOuter.layer
        containerOuterLayer.shadowColor = UIColor.black.cgColor
        containerOuterLayer.shadowOffset = CGSize(width: 0, height: 3)
        containerOuterLayer.shadowRadius = 6;
        containerOuterLayer.shadowOpacity = 0.4;
        
        // add click listener to view
        let singleTapView = UITapGestureRecognizer(target: self, action: #selector (self.onClickView(_:)))
        singleTapView.numberOfTapsRequired = 1
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(singleTapView)
        
        // add click listener to rotate
        let singleTapRotate = UITapGestureRecognizer(target: self, action: #selector(self.onClickRotate(_:)))
        singleTapRotate.numberOfTapsRequired = 1
        self.image_rotate.isUserInteractionEnabled = true
        self.image_rotate.addGestureRecognizer(singleTapRotate)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.async(execute: {
            self.initView()
        })
    }
    
    func initView() {
        // tick
        image_tick.isHidden = !self.isSelected
        
        // rotate
        // show rotate button only when cell is selected and is not portrait
        image_rotate.isHidden = !(self.isSelected && !self.isPortrait)
        
        // notch
        updateNotchOrientation()
        updateNotchVisibility()
    }
    
    func animateSelection() {
        // tick
        image_tick.isHidden = !self.isSelected
        
        // rotate
        // show rotate button only when cell is selected and is not portrait
        image_rotate.isHidden = !(self.isSelected && !self.isPortrait)
        
        // notch
        animateNotchVisibility()
    }
    
    func animateNotchVisibility() {
        // if selected, update notch orientation before animation
        if (isSelected) {
            updateNotchOrientation()
        }
        
        UIView.animate(withDuration: MyPageViewContentController.NOTCH_SWITCH_ANIM_TIME, animations: {() in
            self.updateNotchVisibility()
        })
    }
    
    func updateNotchVisibility() {
        let cellWidth = self.view_imageContainerInner.bounds.width
        let cellHeight = self.view_imageContainerInner.bounds.height
        
        if (self.isSelected) { // notch on
            if (self.isPortrait) {
                self.image_notch.bounds = CGRect(x: 0, y: 0,
                                                 width: cellWidth, height: cellHeight)
            } else { // landscape
                self.landscapeNotchOn()
            }
        } else { // notch off
            if (self.isPortrait) {
                self.image_notch.bounds = CGRect(x: 0, y: 0,
                                                 width: cellWidth * self.NOTCH_OFF_FACTOR,
                                                 height: cellHeight * self.NOTCH_OFF_FACTOR)
            } else { // landscape
                self.landscapeNotchOff()
            }
        }
    }
    
    func landscapeNotchOn() {
        let cellWidth = self.view_imageContainerInner.bounds.width
        let cellHeight = self.view_imageContainerInner.bounds.height
        
        self.image_notch.bounds = CGRect(x: 0, y: 0, width: cellHeight, height: cellWidth)
    }
    
    func landscapeNotchOff() {
        let cellWidth = self.view_imageContainerInner.bounds.width
        let cellHeight = self.view_imageContainerInner.bounds.height
        
        self.image_notch.bounds = CGRect(x: 0, y: 0,
                                         width: cellHeight * self.NOTCH_OFF_FACTOR,
                                         height: cellWidth * self.NOTCH_OFF_FACTOR)
    }
    
    func updateNotchOrientation() {
        if (isPortrait) {
            return
        }
        
        var rotateAngle: CGFloat
        if (self.notchLeft) {
            rotateAngle = CGFloat(-Double.pi / 2.0) // -90 deg
        } else {
            rotateAngle = CGFloat(Double.pi / 2.0) // 90 deg
        }
        self.image_notch.transform = CGAffineTransform(rotationAngle: rotateAngle)
    }
    
    @objc func onClickView(_ sender: UITapGestureRecognizer) {
        self.isSelected = !self.isSelected
        
        if (self.isSelected) {
            selectDelegate.onSelectCell(at: index)
        } else {
            selectDelegate.onDeselectCell(at: index)
        }
        
        // if deselcted, reset notch orientation to left
        if (!self.isSelected) {
            notchLeft = true
        }
        
        animateSelection()
    }
    
    @objc func onClickRotate(_ sender: UITapGestureRecognizer) {
        self.notchLeft = !self.notchLeft
        
        // animate off
        UIView.animate(withDuration: MyPageViewContentController.NOTCH_SWITCH_ANIM_TIME / 2.0, animations: {() in
            self.landscapeNotchOff()
        }, completion: {(finished) in
            self.updateNotchOrientation()
            
            // animate back on
            UIView.animate(withDuration: MyPageViewContentController.NOTCH_SWITCH_ANIM_TIME / 2.0, animations: {() in
                self.landscapeNotchOn()
            })
        })
    }
}
