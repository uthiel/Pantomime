//
// Created by Thomas Christensen on 24/08/16.
// Copyright (c) 2016 Nordija A/S. All rights reserved.
//

import Foundation

public class MediaPlaylist {
    public unowned let masterPlaylist: MasterPlaylist
    
    internal(set) public var path: String?
    internal(set) public var programId: Int = 0
    internal(set) public var bandwidth: Int = 0
    internal(set) public var codec: String?
    internal(set) public var version: Int?
    internal(set) public var targetDuration: Int?
    internal(set) public var mediaSequence: Int?
    
    public var segments = [MediaSegment]()

    public init(masterPlaylist: MasterPlaylist) {
        self.masterPlaylist = masterPlaylist
    }
    
    public init(masterPlaylist: MasterPlaylist, path: String) {
        self.masterPlaylist = masterPlaylist
        self.path = path
    }

    public func duration() -> Float {
        var dur: Float = 0.0
        for item in segments {
            dur += item.duration!
        }
        return dur
    }
}
