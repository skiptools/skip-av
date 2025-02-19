// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if !SKIP_BRIDGE
#if SKIP
import Foundation

// MARK: - CoreAudioTypes

public typealias OSStatus = Int32
public typealias AudioFormatID = Int32
public typealias AudioFormatFlags = Int32

public struct AudioStreamBasicDescription {
    public var mSampleRate: Double
    public var mFormatID: AudioFormatID
    public var mFormatFlags: AudioFormatFlags
    public var mBytesPerPacket: Int32
    public var mFramesPerPacket: Int32
    public var mBytesPerFrame: Int32
    public var mChannelsPerFrame: Int32
    public var mBitsPerChannel: Int32
    public var mReserved: Int32
    
    public init() {
        mSampleRate = 0
        mFormatID = 0
        mFormatFlags = 0
        mBytesPerPacket = 0
        mFramesPerPacket = 0
        mBytesPerFrame = 0
        mChannelsPerFrame = 0
        mBitsPerChannel = 0
        mReserved = 0
    }
}

public let kAudioFormatLinearPCM: AudioFormatID = AudioFormatID(Int(0x6C70636D)) // 'lpcm'
public let kAudioFormatMPEG4AAC: AudioFormatID = AudioFormatID(Int(0x61616320)) // 'aac '

public struct AudioChannelLayout {
    public var mChannelLayoutTag: AudioChannelLayoutTag
    public var mChannelBitmap: AudioChannelBitmap
    public var mNumberChannelDescriptions: Int32
    public var mChannelDescriptions: [AudioChannelDescription]
    
    public init() {
        mChannelLayoutTag = 0
        mChannelBitmap = 0
        mNumberChannelDescriptions = 0
        mChannelDescriptions = []
    }
}

public typealias AudioChannelLayoutTag = Int32
public typealias AudioChannelBitmap = Int32

public struct AudioChannelDescription {
    public var mChannelLabel: AudioChannelLabel
    public var mChannelFlags: AudioChannelFlags
    public var mCoordinates: (Double, Double, Double)
    
    public init() {
        mChannelLabel = 0
        mChannelFlags = 0
        mCoordinates = (0.0, 0.0, 0.0)
    }
}

public typealias AudioChannelLabel = Int32
public typealias AudioChannelFlags = Int32

#endif
#endif

