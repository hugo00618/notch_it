//
//  MyViewController.swift
//  Notch It
//
//  Created by Hugo Yu on 2017-11-15.
//  Copyright © 2017 Hugo Yu. All rights reserved.
//

import UIKit
import Photos
import MBProgressHUD

class MyViewController: UIViewController, UIPageViewControllerDataSource, PHPhotoLibraryChangeObserver, CellSelectDelegate {
    
    static let IPHONE_X_WIDTH_PX: CGFloat = 1125.0
    static let IPHONE_X_HEIGHT_PX: CGFloat = 2436.0
    
    let ORIGINAL_IMAGE_TARGET_SIZE_PORTRAIT = CGSize(width: IPHONE_X_WIDTH_PX, height: IPHONE_X_HEIGHT_PX)
    let ORIGINAL_IMAGE_TARGET_SIZE_LANDSCAPE = CGSize(width: IPHONE_X_HEIGHT_PX, height: IPHONE_X_WIDTH_PX)
    
    let notchImage = UIImage(named: "img_notch")
    var notchImageLeft, notchImageRight: UIImage?
    
    // model
    var myFetchResult: PHFetchResult<PHAsset>!
    var assets = [PHAsset]()
    var contentVCs = [MyPageViewContentController?]()
    var selectedIndices = [Int]()
    
    // view
    @IBOutlet weak var labelNoPhotos: UILabel!
    var pageViewController: UIPageViewController!
    @IBOutlet weak var buttonExport: UIShadowButton!
    @IBOutlet weak var labelNumSelected: UILabel!
    @IBOutlet weak var imageDeslectAll: UIImageView!
    var hud: MBProgressHUD!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // model
        //        resetCachedAssets()
        PHPhotoLibrary.shared().register(self)
        
        // fetch photos
        fetchPhotos()
        
        // pageViewController
        self.pageViewController = self.storyboard?.instantiateViewController(withIdentifier: "MyPageViewController") as! UIPageViewController
        self.pageViewController.dataSource = self
        self.pageViewController.setViewControllers([getPageVCContent(at: 0)], direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
        self.pageViewController.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        self.addChildViewController(self.pageViewController)
        
        self.view.insertSubview(self.pageViewController.view, belowSubview: buttonExport)
        self.pageViewController.didMove(toParentViewController: self)
        
        // reset export button to show normal state
        buttonExport.isHighlighted = false
        
        // add click listener to deselect all
        let singleTapDeselectAll = UITapGestureRecognizer(target: self, action: #selector (self.onClickDeselectAll(_:)))
        singleTapDeselectAll.numberOfTapsRequired = 1
        imageDeslectAll.isUserInteractionEnabled = true
        imageDeslectAll.addGestureRecognizer(singleTapDeselectAll)
        
        updateExportViewsVisibility()
    }
    
    
    
    // MARK: UIPageViewControllerDataSource
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let prevIdx = (viewController as! MyPageViewContentController).index - 1
        if (prevIdx >= 0) {
            return getPageVCContent(at: prevIdx)
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let nextIdx = (viewController as! MyPageViewContentController).index + 1
        if (nextIdx < assets.count) {
            return getPageVCContent(at: nextIdx)
        }
        return nil;
    }
    
    // MARK: PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        let changeDetails = changeInstance.changeDetails(for: myFetchResult)
        
        // if photo gallery has changed
        if (changeDetails != nil) {
            DispatchQueue.main.async(execute: {
                // selected indeices will get messed up, deselect all
                self.deselectAll()
                
                // update data source
                self.myFetchResult = changeDetails?.fetchResultAfterChanges
                self.saveToAssets()
                
                self.pageViewController.setViewControllers([self.getPageVCContent(at: 0)], direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
                //resetCachedAssets()
            })
        }
    }
    
    func getPageVCContent(at: Int) -> MyPageViewContentController {
        if (contentVCs.isEmpty) {
            let newVC = self.storyboard?.instantiateViewController(
                withIdentifier: "MyPageViewContentController") as! MyPageViewContentController
            return newVC
        }
        
        if (contentVCs[at] == nil) {
            let newVC = self.storyboard?.instantiateViewController(
                withIdentifier: "MyPageViewContentController") as! MyPageViewContentController
            newVC.index = at
            newVC.thumbnailAsset = assets[at]
            newVC.selectDelegate = self
            contentVCs[at] = newVC
        }
        
        return contentVCs[at]!
    }
    
    func fetchPhotos() {
        // load fetch result
        let photosFetchOptions = PHFetchOptions()
        photosFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        photosFetchOptions.predicate = NSPredicate(format: "mediaSubtype == %ld", PHAssetMediaSubtype.photoScreenshot.rawValue)
        myFetchResult = PHAsset.fetchAssets(with: photosFetchOptions)
        
        saveToAssets()
    }
    
    func saveToAssets() {
        assets = [PHAsset]()
        
        let totalCount = myFetchResult.count
        
        // go update view if fetch result is empty
        if (totalCount == 0) {
            updateView()
        }
        
        // enumerate
        var enumeratedCount = 0
        myFetchResult.enumerateObjects { (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            if let asset = obj as? PHAsset {
                // filter out non-iPhone X scrrenshots
                if ((CGFloat(asset.pixelWidth) == ViewController.IPHONE_X_WIDTH_PX &&
                    CGFloat(asset.pixelHeight) == ViewController.IPHONE_X_HEIGHT_PX) ||
                    (CGFloat(asset.pixelWidth) == ViewController.IPHONE_X_HEIGHT_PX &&
                        CGFloat(asset.pixelHeight) == ViewController.IPHONE_X_WIDTH_PX)){
                    self.assets.append(asset)
                }
                
                enumeratedCount += 1
                if (enumeratedCount == totalCount) { // enumeration finished
                    self.updateView()
                    
                    // re-init contentVCs
                    self.contentVCs = Array(repeating: nil, count: self.assets.count)
                    
                    // reload page view controller
                    DispatchQueue.main.async(execute: {
                        self.pageViewController.dataSource = nil;
                        self.pageViewController.dataSource = self;
                    })
                }
            }
        }
    }
    
    func updateView() {
        if (assets.isEmpty) {
            labelNoPhotos.isHidden = false
        } else {
            labelNoPhotos.isHidden = true
        }
    }
    
    func deselectAll() {
        selectedIndices = [Int]()
        
        for myVc in contentVCs {
            myVc?.isSelected = false
            myVc?.animateSelection()
        }
        
        animateExportViewsVisibility()
    }
    
    func animateExportViewsVisibility() {
        // if not hiding view, update counter before animation
        if (!self.selectedIndices.isEmpty) {
            updateNumSelected()
        }
        
        UIView.animate(withDuration: MyPageViewContentController.NOTCH_SWITCH_ANIM_TIME, animations: {() in
            self.updateExportViewsVisibility()
        }, completion: {(finished) in
            if (self.selectedIndices.isEmpty) {
                // if hiding view, update counter after animation
                self.updateNumSelected()
            }
        })
    }
    
    func updateNumSelected() {
        labelNumSelected.text = String(selectedIndices.count) + " Selected"
    }
    
    func updateExportViewsVisibility() {
        if (selectedIndices.isEmpty) {
            buttonExport.alpha = 0
            labelNumSelected.alpha = 0
            imageDeslectAll.alpha = 0
        } else {
            self.buttonExport.alpha = 1
            labelNumSelected.alpha = 1
            imageDeslectAll.alpha = 1
        }
    }
    
    // MARK: CellSelectDelegate
    func onSelectCell(at: Int) {
        selectedIndices.append(at)
        animateExportViewsVisibility()
    }
    
    func onDeselectCell(at: Int) {
        if let index = selectedIndices.index(of: at) {
            selectedIndices.remove(at: index)
            animateExportViewsVisibility()
        }
    }
    
    @objc func onClickDeselectAll(_ sender: Any) {
        deselectAll()
    }
    
    @IBAction func onClickExport(_ sender: Any) {
        // show saving HUD
        showPhotosSavingHUD()
        
        // do work
        DispatchQueue.global(qos: .userInitiated).async {
            // request options
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            
            // add notch to each of the selected image
            for index in self.selectedIndices.sorted() {
                let myAsset = self.assets[index]
                let myVC = self.contentVCs[index]!
                
                // get orientation for notch position and target size
                var myNotchOrientation = UIImageOrientation.up
                var myTargetSize = self.ORIGINAL_IMAGE_TARGET_SIZE_PORTRAIT
                if (!myVC.isPortrait) { // if landscape
                    myNotchOrientation = myVC.notchLeft ? UIImageOrientation.left : UIImageOrientation.right
                    myTargetSize = self.ORIGINAL_IMAGE_TARGET_SIZE_LANDSCAPE
                }
                
                // request original size
                ImageUtils.requestImage(asset: myAsset, targetSize: myTargetSize, options: requestOptions, resultHandler: {(result, info) in
                    // combine image
                    let combinedImg = self.combineImage(bottomImg: result!, orientation: myNotchOrientation)
                    
                    // write to album
                    CustomPhotoAlbum.saveImage(image: combinedImg, completionHandler: {(success, error) in
                        // update HUD progress
                        DispatchQueue.main.async(execute: {
                            if (self.hud != nil && self.hud.mode == .annularDeterminate) {
                                self.hud.progress += 1.0 / Float(self.selectedIndices.count)
                            }
                            
                            if (self.hud.progress == 1) { // finished
                                self.hud.hide(animated: true)
                                
                                // deselect all cells
                                self.deselectAll()
                                
                                // show done HUD
                                self.showPhotosSavedHUD()
                            }
                        })
                    })
                    
                })
            }
        }
    }
    
    /**
     Add notch to bottomImg
     
     - Parameter bottomImg: Image at the bottom
     - Parameter orientation: Orientation of the notch
     */
    func combineImage(bottomImg: UIImage, orientation: UIImageOrientation) -> UIImage {
        var topImg: UIImage?
        
        switch (orientation) {
        case .up:
            topImg = notchImage
            break
        case .left:
            if (notchImageLeft == nil) {
                notchImageLeft = UIImage(cgImage: notchImage!.cgImage!, scale: 1.0, orientation: .left)
            }
            topImg = notchImageLeft
            break
        case .right:
            if (notchImageRight == nil) {
                notchImageRight = UIImage(cgImage: notchImage!.cgImage!, scale: 1.0, orientation: .right)
            }
            topImg = notchImageRight
            break
        default:
            break
        }
        
        let size = bottomImg.size
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        // draw images in order
        bottomImg.draw(in: rect)
        topImg!.draw(in: rect)
        
        let newImg:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImg
    }
    
    func showPhotosSavingHUD() {
        // construct HUD
        hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.label.text = "Saving..."
        hud.mode = .annularDeterminate
    }
    
    func showPhotosSavedHUD() {
        // construct HUD
        hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.mode = .customView
        hud.label.text = "Done"
        
        // add icon
        let icon = UIImage(named: "ic_done")
        hud.customView = UIImageView(image: icon)
        
        // Looks a bit nicer if we make it square.
        hud.isSquare = true;
        
        // automatically dismissed after 2 seconds
        hud.hide(animated: true, afterDelay: 2.0)
        
        // add a gesture recoginer to dismiss the overlay on any tap
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onTapAnywhere))
        hud!.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func onTapAnywhere(gestureRecognizer: UIGestureRecognizer) {
        if (hud != nil) {
            hud!.hide(animated: true)
        }
    }
}
