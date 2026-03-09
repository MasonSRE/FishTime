struct ScoringThresholds {
    let lowActivityEPM: Int
    let highActivityEPM: Int

    static let `default` = ScoringThresholds(lowActivityEPM: 2, highActivityEPM: 15)
}
