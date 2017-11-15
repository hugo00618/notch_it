//
//  ViewController.swift
//  NotchIt
//
//  Created by Hugo Yu on 2017-11-04.
//  Copyright © 2017 Hugo Yu. All rights reserved.
//

import UIKit
import Photos
import MBProgressHUD

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver {
    
    let REUSE_ID_PHOTO_CELL = "PhotoCell"
    let SEGUE_ID_SHOW_PHOTO_DETAILS = "ShowPhotoDetails"
    
    static let IPHONE_X_WIDTH_PX: CGFloat = 1125.0
    static let IPHONE_X_HEIGHT_PX: CGFloat = 2436.0
    
    let ORIGINAL_IMAGE_TARGET_SIZE_PORTRAIT = CGSize(width: IPHONE_X_WIDTH_PX, height: IPHONE_X_HEIGHT_PX)
    let ORIGINAL_IMAGE_TARGET_SIZE_LANDSCAPE = CGSize(width: IPHONE_X_HEIGHT_PX, height: IPHONE_X_WIDTH_PX)
    
    let notchImage = UIImage(named: "img_notch")
    var notchImageLeft, notchImageRight: UIImage?
    
    // view
    @IBOutlet var collection_photos: UICollectionView!
    @IBOutlet weak var label_noPhotos: UILabel!
    @IBOutlet weak var batButtonNumSelected: UIBarButtonItem!
    var hud: MBProgressHUD!
    
    // photo assets
    var myFetchResult: PHFetchResult<PHAsset>!
    var assets = [PHAsset]()
    var imageManager: PHCachingImageManager!
    var previousPreheatRect: CGRect!
    
    // view params
    var gridSpacing: CGFloat!
    var selectedCells = [IndexPath: PhotoThumbnailCell]()
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // collection view
        collection_photos.allowsMultipleSelection = true
        collection_photos.delegate = self
        collection_photos.dataSource = self
        
        gridSpacing = (collection_photos.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing
        
        // hide tool bar
        self.navigationController?.setToolbarHidden(true, animated: false)
        
        // init imageManager
        imageManager = PHCachingImageManager()
        //        resetCachedAssets()
        PHPhotoLibrary.shared().register(self)
        
        // fetch photos
        fetchPhotos()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myAsset = assets[indexPath.row]
        
        // load reused cell
        let myCell = collection_photos.dequeueReusableCell(
            withReuseIdentifier: REUSE_ID_PHOTO_CELL, for: indexPath) as! PhotoThumbnailCell
        
        // set thumbnail image of cell
        let isPortrait = myAsset.pixelWidth < myAsset.pixelHeight
        let gridSize = getGridSize(scale: UIScreen.main.scale, isPortrait: isPortrait)
        self.imageManager.requestImage(for: myAsset, targetSize: gridSize, contentMode: .aspectFit, options: PHImageRequestOptions(), resultHandler: {(result, info) in
            myCell.img_thumbnail.image = result
        })
        
        // set isPortrait of cell
        myCell.isPortrait = isPortrait
        
        // set cell selection view
//        myCell.updateSelectionView()
        
        return myCell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                                 didSelectItemAt indexPath: IndexPath) {
        let myCell = collection_photos.cellForItem(at: indexPath) as! PhotoThumbnailCell
        
        // update model
        selectedCells[indexPath] = myCell
        
        // toolbar
        // show toolbar
        self.navigationController?.setToolbarHidden(false, animated: true)
        // update numSelected
        updateNumSelected()
        
        // tool bar bounds takes time to update
        // selecting cells in the last row doesn't scroll to desried position if execute immediately after
        // adding a small delay would fix this...
        // assuming user device has a refresh rate of 120Hz, this only add one frame of delay
        // so they probably won't notice lol
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 / 120, execute: {
            // update collection view
            self.collection_photos.selectItem(at: indexPath, animated: true, scrollPosition: .centeredVertically)
            
            // update cell view
            myCell.isSelected = true
            myCell.setNotchOnOff(on: true)
        })
    }
    
    func collectionView(_ collectionView: UICollectionView,
                                 didDeselectItemAt indexPath: IndexPath) {
        let myCell = collection_photos.cellForItem(at: indexPath) as! PhotoThumbnailCell
        
        // _selectedCells
        selectedCells.removeValue(forKey: indexPath)
        
        // toolbar
        // hide toolbar if no photos selected
        if (selectedCells.count == 0) {
            self.navigationController?.setToolbarHidden(true, animated: true)
        }
        // update numSelected
        updateNumSelected()
        
        // update cell
        myCell.isSelected = false
        myCell.setNotchOnOff(on: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let myAsset = assets[indexPath.row]
        let isPortrait = myAsset.pixelWidth < myAsset.pixelHeight
        return getGridSize(scale: 1, isPortrait: isPortrait)
    }
    
    func getGridSize(scale: CGFloat, isPortrait: Bool) -> CGSize {
        var width, height: CGFloat
        
        if (isPortrait) { // two portraits per row
            width = (view.frame.width) / 2.0 - gridSpacing
            height = ViewController.IPHONE_X_HEIGHT_PX / ViewController.IPHONE_X_WIDTH_PX * width
        } else { // one landscape per row
            width = view.frame.width
            height = ViewController.IPHONE_X_WIDTH_PX / ViewController.IPHONE_X_HEIGHT_PX  * width
        }
        
        return CGSize(width: width * scale, height: height * scale)
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
                
                //resetCachedAssets()
            })
        }
    }

    func loadFetchResult() {
        let photosFetchOptions = PHFetchOptions()
        photosFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        photosFetchOptions.predicate = NSPredicate(format: "mediaSubtype == %ld", PHAssetMediaSubtype.photoScreenshot.rawValue)
        myFetchResult = PHAsset.fetchAssets(with: photosFetchOptions)
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
                }
            }
        }
    }
    
    func updateView() {
        if (assets.isEmpty) { // no iPhone X screenshot found
            collection_photos.isHidden = true
            label_noPhotos.isHidden = false
        } else {
            collection_photos.isHidden = false
            label_noPhotos.isHidden = true
            collection_photos.reloadData()
        }
    }
    
    func fetchPhotos() {
        loadFetchResult()
        saveToAssets()
    }

    @IBAction func onClickNotchIt(_ sender: Any) {
        
        // show saving HUD
        showPhotosSavingHUD()
        
        // do work
        DispatchQueue.global(qos: .userInitiated).async {
            // sort keys
            let keys = Array(self.selectedCells.keys).sorted()
            
            // request options
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            
            // add notch to each of the selected image
            for myIndexPath in keys {
                let assetIndex = myIndexPath.row
                let myAsset = self.assets[assetIndex]
                let myCell = self.selectedCells[myIndexPath]!
                
                // get orientation for notch position and target size
                var myNotchOrientation = UIImageOrientation.up
                var myTargetSize = self.ORIGINAL_IMAGE_TARGET_SIZE_PORTRAIT
                if (!myCell.isPortrait) {
                    myNotchOrientation = myCell.notchOrientation
                    myTargetSize = self.ORIGINAL_IMAGE_TARGET_SIZE_LANDSCAPE
                }
                
                // request original size
                self.imageManager.requestImage(for: myAsset, targetSize: myTargetSize, contentMode: .aspectFit, options: requestOptions, resultHandler: {(result, info) in
                    // combine image
                    let combinedImg = self.combineImage(bottomImg: result!, orientation: myNotchOrientation)
                    
                    // write to album
                    CustomPhotoAlbum.saveImage(image: combinedImg, completionHandler: {(success, error) in
                        // update HUD progress
                        DispatchQueue.main.async(execute: {
                            if (self.hud != nil && self.hud.mode == .annularDeterminate) {
                                self.hud.progress += 1.0 / Float(self.selectedCells.count)
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
    
    @IBAction func onClickDeselectAll(_ sender: Any) {
        deselectAll()
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
    
    func deselectAll() {
        // tool bar
        self.navigationController?.setToolbarHidden(true, animated: true)
        
        // update cells
        for indexPath in collection_photos.indexPathsForSelectedItems! {
            collection_photos.deselectItem(at: indexPath, animated: false)
        }
        for (_, cell) in selectedCells {
            cell.setNotchOnOff(on: false)
        }
        
        // model
        self.selectedCells.removeAll()
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
    
    func updateNumSelected() {
        print(selectedCells.count)
        batButtonNumSelected.title = String(selectedCells.count) + " Selected"
    }
}

