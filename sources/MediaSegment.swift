//
// Created by Thomas Christensen on 24/08/16.
// Copyright (c) 2016 Nordija A/S. All rights reserved.
//

import Foundation

public class MediaSegment {
    public unowned let mediaPlaylist: MediaPlaylist
    
    internal(set) public var path: String?
    internal(set) public var duration: Float?
    internal(set) public var sequence: Int = 0
    internal(set) public var subrangeLength: Int?
    internal(set) public var subrangeStart: Int?
    internal(set) public var title: String?
    internal(set) public var discontinuity: Bool = false

    public init(mediaPlaylist: MediaPlaylist) {
        self.mediaPlaylist = mediaPlaylist
    }
    
    public init(mediaPlaylist: MediaPlaylist, duration: Float, path: String) {
        self.mediaPlaylist = mediaPlaylist
        self.duration = duration
        self.path = path
    }
}
