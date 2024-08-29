// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

public typealias CMTimeValue = Int64
public typealias CMTimeScale = Int32
public typealias CMTimeFlags = UInt32
public typealias CMTimeEpoch = Int64

/// Time as a rational value, with a time value as the numerator and timescale as the denominator. The structure can represent a specific numeric time in the media timeline, and can also represent nonnumeric values like invalid and indefinite times or positive and negative infinity.
public struct CMTime : Hashable { // TODO: Comparable
    public static let zero = CMTime(seconds: 0.0, preferredTimescale: 0)

    public var value: CMTimeValue = CMTimeValue(0)
    public var timescale: CMTimeScale = CMTimeScale(0)
    public var flags: CMTimeFlags = CMTimeFlags(0)
    public var epoch: CMTimeEpoch = CMTimeEpoch(0)

    public init(value: CMTimeValue, timescale: CMTimeScale, flags: CMTimeFlags, epoch: CMTimeEpoch) {
        self.value = value as CMTimeValue
        self.timescale = timescale as CMTimeScale
        self.flags = flags as CMTimeFlags
        self.epoch = epoch as CMTimeEpoch
    }

    public init(seconds: Double, preferredTimescale: CMTimeScale) {
        self.value = CMTimeValue(seconds * 1000.0)
        self.timescale = preferredTimescale
    }

    public init(value: CMTimeValue, timescale: CMTimeScale) {
        self.value = value
        self.timescale = timescale
    }
}

