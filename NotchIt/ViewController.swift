//
//  ViewController.swift
//  NotchIt
//
//  Created by Hugo Yu on 2017-11-04.
//  Copyright © 2017 Hugo Yu. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver {
    
    let REUSE_ID_PHOTO_CELL = "PhotoCell"
    let SEGUE_ID_SHOW_PHOTO_DETAILS = "ShowPhotoDetails"
    
    let IPHONE_X_WIDTH_PX: CGFloat = 1125.0
    let IPHONE_X_HEIGHT_PX: CGFloat = 2436.0
    
    let notchImage = UIImage(named: "img_notch")
    var notchImageLeft, notchImageRight: UIImage?
    
    // view
    @IBOutlet var collection_photos: UICollectionView!
    
    // photo assets
    var myFetchResult: PHFetchResult<PHAsset>!
    var assets = [PHAsset]()
    var imageManager: PHCachingImageManager!
    var previousPreheatRect: CGRect!
    
    // view params
    var gridSpacing: CGFloat!
    var _selectedCells : NSMutableArray = []
    
    override func awakeFromNib() {
        // init imageManager
        imageManager = PHCachingImageManager()
//        resetCachedAssets()
        
        // fetch photos
        fetchPhotos()
        
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collection_photos.allowsMultipleSelection = true
        collection_photos.delegate = self
        collection_photos.dataSource = self
        
        gridSpacing = (collection_photos.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing
        
        // hide tool bar
        self.navigationController?.setToolbarHidden(true, animated: false)
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
        myCell.updateSelectionView()
        
        return myCell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                                 didSelectItemAt indexPath: IndexPath) {
        // show toolbar
        self.navigationController?.setToolbarHidden(false, animated: true)
        
        self._selectedCells.add(indexPath)
        
        // update cell
        let myCell = collectionView.cellForItem(at: indexPath) as! PhotoThumbnailCell
        myCell.isSelected = true
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition.bottom)
        myCell.updateSelectionView()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                                 didDeselectItemAt indexPath: IndexPath) {
        _selectedCells.remove(indexPath)
        
        // update cell
        let myCell = collectionView.cellForItem(at: indexPath) as! PhotoThumbnailCell
        myCell.isSelected = false
        myCell.updateSelectionView()
        
        // hide toolbar if no photos selected
        if (_selectedCells.count == 0) {
            self.navigationController?.setToolbarHidden(true, animated: true)
        }
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
            height = IPHONE_X_HEIGHT_PX / IPHONE_X_WIDTH_PX * width
        } else { // one landscape per row
            width = view.frame.width
            height = IPHONE_X_WIDTH_PX / IPHONE_X_HEIGHT_PX  * width
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
                self._selectedCells = []
                self.navigationController?.setToolbarHidden(true, animated: true)
                
                // update data source
                self.myFetchResult = changeDetails?.fetchResultAfterChanges
                self.saveToAssets()
                self.collection_photos.reloadData()
                
                // check if there is no screenshots
                if (self.myFetchResult.count == 0) {
                    
                } else {
                    
                }
                
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
        myFetchResult.enumerateObjects { (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            if let asset = obj as? PHAsset {
                // filter out non-iPhone X scrrenshots
                if ((CGFloat(asset.pixelWidth) == self.IPHONE_X_WIDTH_PX &&
                    CGFloat(asset.pixelHeight) == self.IPHONE_X_HEIGHT_PX) ||
                    (CGFloat(asset.pixelWidth) == self.IPHONE_X_HEIGHT_PX &&
                        CGFloat(asset.pixelHeight) == self.IPHONE_X_WIDTH_PX)){
                    self.assets.append(asset)
                }
            }
        }
    }
    
    func fetchPhotos() {
        loadFetchResult()
        saveToAssets()
    }

    @IBAction func onClickNotchIt(_ sender: Any) {
        // TODO: show loading HUD
        
        // set image request params
        let targetSize = CGSize(width: IPHONE_X_WIDTH_PX, height: IPHONE_X_HEIGHT_PX)
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        // add notch to each of the selected cell
        for indexPath in _selectedCells {
            // request original size
            let idx = (indexPath as! IndexPath).row
            let myAsset = assets[idx]
            let myCell = collection_photos.cellForItem(at: indexPath as! IndexPath) as! PhotoThumbnailCell
            
            self.imageManager.requestImage(for: myAsset, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions, resultHandler: {(result, info) in
                // combine image
                // get orientation
                var myNotchOrientation = UIImageOrientation.up
                if (!myCell.isPortrait) {
                    myNotchOrientation = myCell.notchOrientation
                }
                let combinedImg = self.combineImage(bottomImg: result!, orientation: myNotchOrientation)
                
                // write to album
                CustomPhotoAlbum.saveImage(image: combinedImg)
            })
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
}

