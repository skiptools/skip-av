// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !SKIP_BRIDGE
#if canImport(AVKit)
@_exported import AVKit
#elseif SKIP
public typealias CMTimeValue = Int64
public typealias CMTimeScale = Int32
public typealias CMTimeFlags = Int32 // UInt32 // FIXME: cannot yet bridge UInt32
public typealias CMTimeEpoch = Int64

public let kCMTimeFlags_Valid: CMTimeFlags = CMTimeFlags(1)
public let kCMTimeFlags_HasBeenRounded: CMTimeFlags = CMTimeFlags(2)
public let kCMTimeFlags_PositiveInfinity: CMTimeFlags = CMTimeFlags(4)
public let kCMTimeFlags_NegativeInfinity: CMTimeFlags = CMTimeFlags(8)
public let kCMTimeFlags_Indefinite: CMTimeFlags = CMTimeFlags(16)
public let kCMTimeFlags_ImpliedValueFlagsMask: CMTimeFlags = CMTimeFlags(4 | 8 | 16)

/// Time as a rational value, with a time value as the numerator and timescale as the denominator. The structure can represent a specific numeric time in the media timeline, and can also represent nonnumeric values like invalid and indefinite times or positive and negative infinity.
public struct CMTime : Hashable {
    public static let zero = CMTime(value: CMTimeValue(0), timescale: CMTimeScale(1), flags: kCMTimeFlags_Valid, epoch: CMTimeEpoch(0))
    public static let invalid = CMTime(value: CMTimeValue(0), timescale: CMTimeScale(0), flags: CMTimeFlags(0), epoch: CMTimeEpoch(0))
    public static let indefinite = CMTime(value: CMTimeValue(0), timescale: CMTimeScale(0), flags: kCMTimeFlags_Valid | kCMTimeFlags_Indefinite, epoch: CMTimeEpoch(0))
    public static let positiveInfinity = CMTime(value: CMTimeValue(0), timescale: CMTimeScale(0), flags: kCMTimeFlags_Valid | kCMTimeFlags_PositiveInfinity, epoch: CMTimeEpoch(0))
    public static let negativeInfinity = CMTime(value: CMTimeValue(0), timescale: CMTimeScale(0), flags: kCMTimeFlags_Valid | kCMTimeFlags_NegativeInfinity, epoch: CMTimeEpoch(0))

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
        let scale: CMTimeScale = preferredTimescale > Int32(0) ? preferredTimescale : Int32(1)
        self.value = CMTimeValue(seconds * Double(scale))
        self.timescale = scale
        self.flags = kCMTimeFlags_Valid
    }

    public init(value: CMTimeValue, timescale: CMTimeScale) {
        self.value = value
        self.timescale = timescale
        self.flags = kCMTimeFlags_Valid
    }

    /// The time expressed as seconds.
    public var seconds: Double {
        if (flags & kCMTimeFlags_Indefinite) != Int32(0) { return Double.nan }
        if (flags & kCMTimeFlags_PositiveInfinity) != Int32(0) { return Double.infinity }
        if (flags & kCMTimeFlags_NegativeInfinity) != Int32(0) { return -Double.infinity }
        if timescale == Int32(0) { return Double.nan }
        return Double(value) / Double(timescale)
    }

    /// Indicates whether the time is valid.
    public var isValid: Bool {
        return (flags & kCMTimeFlags_Valid) != Int32(0)
    }

    /// Indicates whether the time is indefinite.
    public var isIndefinite: Bool {
        return isValid && ((flags & kCMTimeFlags_Indefinite) != Int32(0))
    }

    /// Indicates whether the time is positive infinity.
    public var isPositiveInfinity: Bool {
        return isValid && ((flags & kCMTimeFlags_PositiveInfinity) != Int32(0))
    }

    /// Indicates whether the time is negative infinity.
    public var isNegativeInfinity: Bool {
        return isValid && ((flags & kCMTimeFlags_NegativeInfinity) != Int32(0))
    }

    /// Indicates whether the time is numeric (valid, not infinity, not indefinite).
    public var isNumeric: Bool {
        return isValid && ((flags & kCMTimeFlags_ImpliedValueFlagsMask) == Int32(0))
    }
}

/// A time range, expressed by start time and duration.
public struct CMTimeRange : Hashable {
    public static let zero = CMTimeRange(start: CMTime.zero, duration: CMTime.zero)
    public static let invalid = CMTimeRange(start: CMTime.invalid, duration: CMTime.invalid)

    public var start: CMTime
    public var duration: CMTime

    public init(start: CMTime, duration: CMTime) {
        self.start = start
        self.duration = duration
    }

    public var end: CMTime {
        return CMTimeAdd(start, duration)
    }

    public var isValid: Bool {
        return start.isValid && duration.isValid && duration.seconds >= 0.0
    }

    public func containsTime(_ time: CMTime) -> Bool {
        let t = time.seconds
        return t >= start.seconds && t < end.seconds
    }
}

public func CMTimeGetSeconds(_ time: CMTime) -> Double {
    return time.seconds
}

public func CMTimeMake(value: CMTimeValue, timescale: CMTimeScale) -> CMTime {
    return CMTime(value: value, timescale: timescale)
}

public func CMTimeMakeWithSeconds(_ seconds: Double, preferredTimescale: CMTimeScale) -> CMTime {
    return CMTime(seconds: seconds, preferredTimescale: preferredTimescale)
}

public func CMTimeAdd(_ lhs: CMTime, _ rhs: CMTime) -> CMTime {
    let scale: CMTimeScale = lhs.timescale > Int32(0) ? lhs.timescale : (rhs.timescale > Int32(0) ? rhs.timescale : Int32(1))
    return CMTime(seconds: lhs.seconds + rhs.seconds, preferredTimescale: scale)
}

public func CMTimeSubtract(_ lhs: CMTime, _ rhs: CMTime) -> CMTime {
    let scale: CMTimeScale = lhs.timescale > Int32(0) ? lhs.timescale : (rhs.timescale > Int32(0) ? rhs.timescale : Int32(1))
    return CMTime(seconds: lhs.seconds - rhs.seconds, preferredTimescale: scale)
}

public func CMTimeCompare(_ lhs: CMTime, _ rhs: CMTime) -> Int32 {
    let a = lhs.seconds
    let b = rhs.seconds
    if a < b { return Int32(-1) }
    if a > b { return Int32(1) }
    return Int32(0)
}

public func CMTimeMinimum(_ lhs: CMTime, _ rhs: CMTime) -> CMTime {
    return lhs.seconds < rhs.seconds ? lhs : rhs
}

public func CMTimeMaximum(_ lhs: CMTime, _ rhs: CMTime) -> CMTime {
    return lhs.seconds > rhs.seconds ? lhs : rhs
}

public func CMTimeRangeMake(start: CMTime, duration: CMTime) -> CMTimeRange {
    return CMTimeRange(start: start, duration: duration)
}

public func CMTimeRangeGetEnd(_ range: CMTimeRange) -> CMTime {
    return range.end
}

public func CMTimeRangeContainsTime(_ range: CMTimeRange, time: CMTime) -> Bool {
    return range.containsTime(time)
}

#endif
#endif
