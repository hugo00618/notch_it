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

    /**
     Creates album and save the image
     
     - Parameter image: The image to be saved
     */
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
   
    /**
     Tires to fetch the asset collection
     
     If the asset collection is found, sets to assetCollection
     
     - Returns: true if the the asset collection is found, false otherwise
     */
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
    
    /**
     Saves the image to photo album
     
     - Parameter image: The image to be saved
     */
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
