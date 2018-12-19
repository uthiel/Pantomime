//
// Created by Thomas Christensen on 24/08/16.
// Copyright (c) 2016 Nordija A/S. All rights reserved.
//

import Foundation

open class MediaPlaylist {
    let masterPlaylist: MasterPlaylist

    open var programId: Int = 0
    open var bandwidth: Int = 0
    open var codec: String?
    open var path: String?
    open var version: Int?
    open var targetDuration: Int?
    open var mediaSequence: Int?
    open private(set) var segments = [MediaSegment]()

    public init(masterPlaylist: MasterPlaylist) {
        self.masterPlaylist = masterPlaylist
    }

    func addSegment(_ segment: MediaSegment) {
        segments.append(segment)
    }

    open func duration() -> Float {
        var dur: Float = 0.0
        for item in segments {
            dur += item.duration!
        }
        return dur
    }
}
