//
//  CustomPhotoAlbum.swift
//  NotchIt
//
//  Created by Hugo Yu on 2017-11-10.
//  Copyright © 2017 Hugo Yu. All rights reserved.
//

import Photos

class CustomPhotoAlbum {
    
    static let albumName = "Notch It"
    static var assetCollection: PHAssetCollection!
    
    static func createAlbum(image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: CustomPhotoAlbum.albumName)
        }) { success, _ in
            if success {
                fetchAssetCollectionForAlbum()
                saveImage(image: image)
            }
        }
    }
    
    static func fetchAssetCollectionForAlbum() -> Bool {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", CustomPhotoAlbum.albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let firstObject: AnyObject = collection.firstObject {
            self.assetCollection = collection.firstObject!
            return true
        }
        
        return false
    }
    
    static func saveImage(image: UIImage) {
        if (!fetchAssetCollectionForAlbum()) { // album not exist
            createAlbum(image: image)
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
            albumChangeRequest?.addAssets([assetPlaceholder] as NSArray)
        }, completionHandler: nil)
    }
    
    
}
