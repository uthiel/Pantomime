//
//  MasterPlaylist.swift
//  Pantomime
//
//  Created by Thomas Christensen on 25/08/16.
//  Copyright © 2016 Sebastian Kreutzberger. All rights reserved.
//

import Foundation

open class MasterPlaylist {
    open internal(set) var playlists = [MediaPlaylist]()
    open var path: String?

    public init() {}
}
