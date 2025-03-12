struct FSRSParameters {
    static let weights = Weights()
    
    struct Weights {
        let stabilityIncrease: Double = 0.4
        let stabilityDecay: Double = 0.6
        let forgettingMultiplier: Double = 5.8
        let difficultyWeight: Double = 4.93
        let stabilityWeight: Double = 0.94
        let difficultyAdjustment: Double = 1.49
        let difficultyBias: Double = 0.14
        let intervalModifier: Double = 0.94
    }
}