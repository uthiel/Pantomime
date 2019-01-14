//
// Created by Thomas Christensen on 25/08/16.
// Copyright (c) 2016 Nordija A/S. All rights reserved.
//

import Foundation

/**
* Parses HTTP Live Streaming manifest files
* Use a BufferedReader to let the parser read from various sources.
*/
open class ManifestBuilder {

    public init() {}

    /**
    * Parses Master playlist manifests
    */
    fileprivate func parseMasterPlaylist(_ url: URL?, reader: BufferedReader, onMediaPlaylist:
            ((_ playlist: MediaPlaylist) -> Void)?) -> MasterPlaylist {
        var masterPlaylist = MasterPlaylist(path: url?.absoluteString)
        var playlists: [MediaPlaylist] = []
        var currentMediaPlaylist: MediaPlaylist?

        defer {
            reader.close()
        }
        
        while let line = reader.readLine() {
            if line.isEmpty {
                // Skip empty lines

            }
            else if line.hasPrefix("#EXT") {
                // Tags
                if line.hasPrefix("#EXTM3U") {
                    // Ok Do nothing

                }
                else if line.hasPrefix("#EXT-X-STREAM-INF") {
                    currentMediaPlaylist = parseMasterPlaylistExtXStreamInf(line, masterPlaylist: masterPlaylist)
                }
                else if line.hasPrefix("#EXT-X-SESSION-KEY") {
                    parseMasterPlaylistExtXSessionKey(line, masterPlaylist: masterPlaylist)
                }
                
            } else if line.hasPrefix("#") {
                // Comments are ignored

            } else {
                // URI - must be
                if let currentMediaPlaylistExist = currentMediaPlaylist {
                    currentMediaPlaylistExist.path = line
                    playlists.append(currentMediaPlaylistExist)
                    if let callableOnMediaPlaylist = onMediaPlaylist {
                        callableOnMediaPlaylist(currentMediaPlaylistExist)
                    }
                }
            }
        }
        
        masterPlaylist.playlists = playlists
        return masterPlaylist
    }
    
    private func parseMasterPlaylistExtXStreamInf(_ line: String, masterPlaylist: MasterPlaylist) -> MediaPlaylist? {
        // #EXT-X-STREAM-INF:PROGRAM-ID=1, BANDWIDTH=200000
        // #EXT-X-STREAM-INF:BANDWIDTH=137954,CODECS=\"mp4a.40.2\"
        
        guard let parametersString = try? line.replace("#EXT-X-STREAM-INF:", replacement: "") else {
            print("Failed to parse program-id and bandwidth on master playlist. Line = \(line)")
            return nil
        }
        
        let currentMediaPlaylist = MediaPlaylist(masterPlaylist: masterPlaylist)
        
        let parameters = parametersString.split(separator: ",")
        
        for parameter in parameters {
            let parameterKeyValue = parameter.split(separator: "=")
            
            guard parameterKeyValue.count == 2 else {
                continue
            }
            
            let parameterKey = parameterKeyValue[0].trimmingCharacters(in: CharacterSet.whitespaces)
            let parameterValue = parameterKeyValue[1].trimmingCharacters(in: CharacterSet.whitespaces)
            
            switch (parameterKey) {
                case "PROGRAM-ID":
                    currentMediaPlaylist.programId = Int(parameterValue) ?? 0
                
                case "BANDWIDTH":
                    currentMediaPlaylist.bandwidth = Int(parameterValue) ?? 0
                
                case "CODECS":
                    currentMediaPlaylist.codec = parameterValue.unescaped
                
                default: ()
            }
        }
        
        return currentMediaPlaylist
    }
    
    private func parseMasterPlaylistExtXSessionKey(_ line: String, masterPlaylist: MasterPlaylist) {
        // #EXT-X-SESSION-KEY:METHOD=SAMPLE-AES,URI="skd://twelve",KEYFORMAT="com.apple.streamingkeydelivery",KEYFORMATVERSIONS="1"
        
        guard let parametersString = try? line.replace("#EXT-X-SESSION-KEY:", replacement: "") else {
            print("Failed to parse X-SESSION-KEY on master playlist. Line = \(line)")
            return
        }
        
        masterPlaylist.xKey = parseExtXKey(parametersString)
    }
    
    private func parseMediaPlaylistExtXKey(_ line: String) -> XKey? {
        // #EXT-X-KEY:METHOD=SAMPLE-AES,URI="skd://twelve",KEYFORMAT="com.apple.streamingkeydelivery",KEYFORMATVERSIONS="1"
        // #EXT-X-KEY:METHOD=AES-128,URI="https://my-host/?foo=bar",IV="0x0123456789ABCDEF"
        
        guard let parametersString = try? line.replace("#EXT-X-KEY:", replacement: "") else {
            print("Failed to parse X-KEY on media playlist. Line = \(line)")
            return nil
        }
        
        return parseExtXKey(parametersString)
    }
    
    private func parseExtXKey(_ parametersString: String) -> XKey? {
        let parameters = parametersString.m3u8_parseLine()
        
        guard let method = parameters["METHOD"],
              let uriString = parameters["URI"] else {
            return nil
        }
        
        let iv = parameters["IV"]
        let keyFormat = parameters["KEYFORMAT"]
        let keyFormatVersions = parameters["KEYFORMATVERSIONS"]
    
        return XKey(method: method, uri: uriString, iv: iv, keyFormat: keyFormat, keyFormatVersions: keyFormatVersions)
    }

    /**
    * Parses Media Playlist manifests
    */
    fileprivate func parseMediaPlaylist(_ reader: BufferedReader,
                                        mediaPlaylist: MediaPlaylist,
                                        onMediaSegment: ((_ segment: MediaSegment) -> Void)?) -> MediaPlaylist {
        var xKey: XKey?
        var currentSegment: MediaSegment?
        var currentURI: String?
        var currentSequence = 0

        defer {
            reader.close()
        }

        while let line = reader.readLine() {
            guard !line.isEmpty else {
                // Skip empty lines
                continue
            }
            
            if line.hasPrefix("#EXT") {
                // Tags
                if line.hasPrefix("#EXTM3U") {

                    // Ok Do nothing
                }
                else if line.hasPrefix("#EXT-X-VERSION") {
                    if let version = line.m3u8_getIntValue() {
                        mediaPlaylist.version = version
                    }
                }
                else if line.hasPrefix("#EXT-X-TARGETDURATION") {
                    if let targetDuration = line.m3u8_getIntValue() {
                        mediaPlaylist.targetDuration = targetDuration
                    }
                }
                else if line.hasPrefix("#EXT-X-MEDIA-SEQUENCE") {
                    if let mediaSequence = line.m3u8_getIntValue() {
                        mediaPlaylist.mediaSequence = mediaSequence
                        currentSequence = mediaSequence
                    }
                }
                else if line.hasPrefix("#EXTINF") {
                    currentSegment = MediaSegment(mediaPlaylist: mediaPlaylist)
                    
                    if let segmentDurationString = line.m3u8_getValue(0), let segmentTitle = line.m3u8_getValue(1) {
                        currentSegment!.duration = Float(segmentDurationString)
                        currentSegment!.title = segmentTitle
                    }
                }
                else if line.hasPrefix("#EXT-X-BYTERANGE") {
                    if let subrangeLength = line.m3u8_getIntValue(0) {
                        currentSegment!.subrangeLength = subrangeLength
                    }
                    
                    if line.contains("@") {
                        currentSegment!.subrangeStart = line.m3u8_getIntValue(1)
                    }
                }
                else if line.hasPrefix("#EXT-X-DISCONTINUITY") {
                    currentSegment!.discontinuity = true
                }
                else if line.hasPrefix("#EXT-X-KEY") {
                    xKey = parseMediaPlaylistExtXKey(line)
                }

            }
            else if line.hasPrefix("#") {
                // Comments are ignored

            }
            else {
                // URI - must be
                if let currentSegmentExists = currentSegment {
                    currentSegmentExists.xKey = xKey
                    currentSegmentExists.path = line
                    currentSegmentExists.sequence = currentSequence
                    currentSequence += 1
                    mediaPlaylist.segments.append(currentSegmentExists)
                    if let callableOnMediaSegment = onMediaSegment {
                        callableOnMediaSegment(currentSegmentExists)
                    }
                }
            }
        }

        return mediaPlaylist
    }

    /**
    * Parses the master playlist manifest from a string document.
    *
    * Convenience method that uses a StringBufferedReader as source for the manifest.
    */
    open func parseMasterPlaylistFromString(_ string: String, onMediaPlaylist:
                ((_ playlist: MediaPlaylist) -> Void)? = nil) -> MasterPlaylist {
        return parseMasterPlaylist(nil, reader: StringBufferedReader(string: string), onMediaPlaylist: onMediaPlaylist)
    }

    /**
    * Parses the master playlist manifest from a file.
    *
    * Convenience method that uses a FileBufferedReader as source for the manifest.
    */
    open func parseMasterPlaylistFromFile(_ path: String, onMediaPlaylist:
                ((_ playlist: MediaPlaylist) -> Void)? = nil) -> MasterPlaylist {
        return parseMasterPlaylist(nil, reader: FileBufferedReader(path: path), onMediaPlaylist: onMediaPlaylist)
    }

    /**
    * Parses the master playlist manifest requested synchronous from a URL
    *
    * Convenience method that uses a URLBufferedReader as source for the manifest.
    */
    open func parseMasterPlaylistFromURL(_ url: URL, onMediaPlaylist:
                ((_ playlist: MediaPlaylist) -> Void)? = nil) -> MasterPlaylist {
        return parseMasterPlaylist(url, reader: URLBufferedReader(uri: url), onMediaPlaylist: onMediaPlaylist)
    }

    /**
    * Parses the media playlist manifest from a string document.
    *
    * Convenience method that uses a StringBufferedReader as source for the manifest.
    */
    open func parseMediaPlaylistFromString(_ string: String,
                                           mediaPlaylist: MediaPlaylist,
                                           onMediaSegment:((_ segment: MediaSegment) -> Void)? = nil) -> MediaPlaylist {
        return parseMediaPlaylist(StringBufferedReader(string: string),
                mediaPlaylist: mediaPlaylist, onMediaSegment: onMediaSegment)
    }

    /**
    * Parses the media playlist manifest from a file document.
    *
    * Convenience method that uses a FileBufferedReader as source for the manifest.
    */
    open func parseMediaPlaylistFromFile(_ path: String,
                                         mediaPlaylist: MediaPlaylist,
                                         onMediaSegment: ((_ segment: MediaSegment) -> Void)? = nil) -> MediaPlaylist {
        return parseMediaPlaylist(FileBufferedReader(path: path),
                mediaPlaylist: mediaPlaylist, onMediaSegment: onMediaSegment)
    }

    /**
    * Parses the media playlist manifest requested synchronous from a URL
    *
    * Convenience method that uses a URLBufferedReader as source for the manifest.
    */
    @discardableResult
    open func parseMediaPlaylistFromURL(_ url: URL,
                                        mediaPlaylist: MediaPlaylist,
                                        onMediaSegment: ((_ segment: MediaSegment) -> Void)? = nil) -> MediaPlaylist {
        return parseMediaPlaylist(URLBufferedReader(uri: url),
                mediaPlaylist: mediaPlaylist, onMediaSegment: onMediaSegment)
    }

    /**
    * Parses the master manifest found at the URL and all the referenced media playlist manifests recursively.
    */
    open func parse(_ url: URL,
                    onMediaPlaylist: ((_ playlist: MediaPlaylist) -> Void)? = nil,
                    onMediaSegment: ((_ segment: MediaSegment) -> Void)? = nil) -> MasterPlaylist {
        // Parse master
        let master = parseMasterPlaylistFromURL(url, onMediaPlaylist: onMediaPlaylist)
        for playlist in master.playlists {
            if let path = playlist.path {

                // Detect if manifests are referred to with protocol
                if path.hasPrefix("http") || path.hasPrefix("file") {
                    // Full path used
                    if let mediaURL = URL(string: path) {
                        parseMediaPlaylistFromURL(mediaURL,
                                mediaPlaylist: playlist, onMediaSegment: onMediaSegment)
                    }
                } else {
                    // Relative path used
                    if let mediaURL = url.URLByReplacingLastPathComponent(path) {
                        parseMediaPlaylistFromURL(mediaURL,
                                mediaPlaylist: playlist, onMediaSegment: onMediaSegment)
                    }
                }
            }
        }
        return master
    }
}
