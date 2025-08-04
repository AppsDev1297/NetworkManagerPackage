//
//  Models.swift
//  NetworkManager
//
//  Created by aman.gupta on 31/07/25.
//

import Foundation

public struct MediaUploadModel {
    var mediaData : Data
    var fileName : String
    
    public init(mediaData: Data, fileName: String) {
        self.mediaData = mediaData
        self.fileName = fileName
    }
}
