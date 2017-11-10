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
        let targetSize = getGridSize(scale: UIScreen.main.scale)
        self.imageManager.requestImage(for: myAsset, targetSize: targetSize, contentMode: .aspectFit, options: PHImageRequestOptions(),
                                       resultHandler: {(result, info)->Void in
            myCell.img_thumbnail.image = result
        })
        
        // set check icon
        myCell.img_tick.isHidden = !myCell.isSelected
        
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
        myCell.img_tick.isHidden = false
    }
    
    func collectionView(_ collectionView: UICollectionView,
                                 didDeselectItemAt indexPath: IndexPath) {
        _selectedCells.remove(indexPath)
        
        // update cell
        let myCell = collectionView.cellForItem(at: indexPath) as! PhotoThumbnailCell
        myCell.isSelected = false
        myCell.img_tick.isHidden = true
        
        // hide toolbar if no photos selected
        if (_selectedCells.count == 0) {
            self.navigationController?.setToolbarHidden(true, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return getGridSize(scale: 1)
    }
    
    func getGridSize(scale: CGFloat) -> CGSize {
        let width = (view.frame.width) / 2.0 - gridSpacing
        let height = IPHONE_X_HEIGHT_PX / IPHONE_X_WIDTH_PX * width
        return CGSize(width: width * scale, height: height * scale)
    }
    
    // MARK: PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        let changeDetails = changeInstance.changeDetails(for: myFetchResult)
        
        // check if there are changes to assets, update myFetchResult and reload collection view
        if (changeDetails != nil) {
            
            DispatchQueue.main.async {
                self.myFetchResult = changeDetails?.fetchResultAfterChanges
                self.collection_photos.reloadData()
            }
        }
        
        // check if there is no screenshots
        if (myFetchResult.count == 0) {
            
        } else {
            
        }
        
        //resetCachedAssets()
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
                if (CGFloat(asset.pixelWidth) == self.IPHONE_X_WIDTH_PX &&
                    CGFloat(asset.pixelHeight) == self.IPHONE_X_HEIGHT_PX) {
                    self.assets.append(asset)
                }
            }
        }
    }
    
    func fetchPhotos() {
        loadFetchResult()
        saveToAssets();
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
            
            self.imageManager.requestImage(for: myAsset, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions, resultHandler: {(result, info)->Void in
                // combine image
                let topImg = UIImage(named: "img_notch")
                let combinedImg = self.combineImage(bottomImg: result!, topImg: topImg!)
                
                // write to album
                CustomPhotoAlbum.saveImage(image: combinedImg)
            })
        }
    }
    
    func combineImage(bottomImg: UIImage, topImg: UIImage) -> UIImage {
        let size = bottomImg.size
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        // draw images in order
        bottomImg.draw(in: rect)
        topImg.draw(in: rect)
        
        let newImg:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImg
    }
}

