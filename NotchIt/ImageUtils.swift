//
//  ImageUtils.swift
//  Notch It
//
//  Created by Hugo Yu on 2017-11-16.
//  Copyright © 2017 Hugo Yu. All rights reserved.
//

import Foundation
import Photos

class ImageUtils {
    static let imageManager = PHCachingImageManager()
    
    static func requestImage(asset: PHAsset, targetSize: CGSize,
                             contentMode: PHImageContentMode = .aspectFit, options: PHImageRequestOptions = PHImageRequestOptions(), resultHandler: @escaping ((UIImage?, [AnyHashable : Any]?) -> Void) = {(result, info) in }) {
        self.imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options, resultHandler: resultHandler)
    }
}
