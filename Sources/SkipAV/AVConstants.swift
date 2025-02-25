// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if !SKIP_BRIDGE
#if SKIP
import Foundation

// AVAudioSettings constants
public let AVFormatIDKey: String = "AVFormatIDKey"
public let AVSampleRateKey: String = "AVSampleRateKey"
public let AVNumberOfChannelsKey: String = "AVNumberOfChannelsKey"
public let AVLinearPCMBitDepthKey: String = "AVLinearPCMBitDepthKey"
public let AVLinearPCMIsBigEndianKey: String = "AVLinearPCMIsBigEndianKey"
public let AVLinearPCMIsFloatKey: String = "AVLinearPCMIsFloatKey"
public let AVLinearPCMIsNonInterleaved: String = "AVLinearPCMIsNonInterleaved"
public let AVAudioFileTypeKey: String = "AVAudioFileTypeKey"
public let AVEncoderAudioQualityKey: String = "AVEncoderAudioQualityKey"
public let AVEncoderAudioQualityForVBRKey: String = "AVEncoderAudioQualityForVBRKey"
public let AVEncoderBitRateKey: String = "AVEncoderBitRateKey"
public let AVEncoderBitRatePerChannelKey: String = "AVEncoderBitRatePerChannelKey"
public let AVEncoderBitRateStrategyKey: String = "AVEncoderBitRateStrategyKey"
public let AVEncoderBitDepthHintKey: String = "AVEncoderBitDepthHintKey"
public let AVSampleRateConverterAlgorithmKey: String = "AVSampleRateConverterAlgorithmKey"
public let AVSampleRateConverterAudioQualityKey: String = "AVSampleRateConverterAudioQualityKey"
public let AVChannelLayoutKey: String = "AVChannelLayoutKey"

// AVAudioBitRateStrategy constants
public let AVAudioBitRateStrategy_Constant: String = "AVAudioBitRateStrategy_Constant"
public let AVAudioBitRateStrategy_LongTermAverage: String = "AVAudioBitRateStrategy_LongTermAverage"
public let AVAudioBitRateStrategy_VariableConstrained: String = "AVAudioBitRateStrategy_VariableConstrained"
public let AVAudioBitRateStrategy_Variable: String = "AVAudioBitRateStrategy_Variable"

// AVSampleRateConverterAlgorithm constants
public let AVSampleRateConverterAlgorithm_Normal: String = "AVSampleRateConverterAlgorithm_Normal"
public let AVSampleRateConverterAlgorithm_Mastering: String = "AVSampleRateConverterAlgorithm_Mastering"
public let AVSampleRateConverterAlgorithm_MinimumPhase: String = "AVSampleRateConverterAlgorithm_MinimumPhase"

public enum AVAudioQuality: Int, @unchecked Sendable {
    case min = 0
    case low = 32
    case medium = 64
    case high = 96
    case max = 127
}

#endif
#endif

