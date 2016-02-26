//
//  Download.swift
//  Book Antenna
//
//  Created by Siliangyu Cheng on 2/25/16.
//  Copyright © 2016 Heraclitus.corp. All rights reserved.
//

import Foundation

class Download: NSObject {
    
    var url: String
    var isDownloading = false
    var progress: Float = 0.0
    
    var downloadTask: NSURLSessionDownloadTask?
    var resumeData: NSData?
    
    init(url: String) {
        self.url = url
    }
}