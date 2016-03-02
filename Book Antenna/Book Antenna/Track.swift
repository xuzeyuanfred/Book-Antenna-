//
//  Track.swift
//  Book Antenna
//
//  Created by Zeyuan Xu on 2/25/16.
//  Copyright © 2016 Heraclitus.corp. All rights reserved.
//

class Track {
    var name: String?
    var artist: String?
    var previewUrl: String?
    
    init(name: String?, artist: String?, previewUrl: String?) {
        self.name = name
        self.artist = artist
        self.previewUrl = previewUrl
  
    }
}