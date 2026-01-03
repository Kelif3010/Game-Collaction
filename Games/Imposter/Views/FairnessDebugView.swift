import SwiftUI
import OSLog

struct FairnessDebugView: View {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FairnessDebug", category: "FairnessSimulator")
    
    @State private var playerNames: String = "Alice\nBob\nCharlie\nDavid\nEve\nFrank"
    @State private var impostersPerRound: Int = 1
    @State private var rounds: Int = 20
    @State private var seedText: String = ""
    @State private var results: String = ""
    @State private var isRunning: Bool = false
    @State private var alsoPrintToConsole: Bool = true
    
    // Policy tuning (small-sample focused)
    @State private var maxConsecutive: Int = 2
    @State private var minCooldownRounds: Int = 1
    @State private var recentWindow: Int = 5
    @State private var pairRecentWindow: Int = 7
    @State private var alphaFrequencyPenalty: Double = 0.7
    @State private var betaDistanceBonus: Double = 0.15
    @State private var gammaPairPenalty: Double = 1.8
    @State private var pairPenaltyDecay: Double = 0.55
    @State private var jitterPercent: Double = 0.02
    // New player integration
    @State private var newPlayerHardCooldownRounds: Int = 1
    @State private var newPlayerSoftPenaltyRounds: Int = 3
    @State private var newPlayerPenaltyFactor: Double = 0.3
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Players (one per line)")) {
                    TextEditor(text: $playerNames)
                        .frame(minHeight: 120)
                        .font(.system(.body, design: .monospaced))
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("Settings")) {
                    Stepper(value: $impostersPerRound, in: 1...3) {
                        Text("Imposters per Round: \(impostersPerRound)")
                    }
                    Stepper(value: $rounds, in: 1...10_000) {
                        Text("Rounds: \(rounds)")
                    }
                    TextField("Random Seed (optional)", text: $seedText)
                        .keyboardType(.numberPad)
                    Toggle(isOn: $alsoPrintToConsole) {
                        Text("Also print results to console")
                    }
                }
                
                Section(header: Text("Policy (Small-sample tuning)")) {
                    HStack {
                        Button("Preset: 1 Spion (10–20)") {
                            // Session profile for 1 imposter
                            impostersPerRound = 1
                            maxConsecutive = 2
                            minCooldownRounds = 1
                            recentWindow = 5
                            pairRecentWindow = 7
                            alphaFrequencyPenalty = 0.7
                            betaDistanceBonus = 0.15
                            gammaPairPenalty = 1.2
                            pairPenaltyDecay = 0.60
                            jitterPercent = 0.02
                            // New player handling
                            newPlayerHardCooldownRounds = 1
                            newPlayerSoftPenaltyRounds = 3
                            newPlayerPenaltyFactor = 0.3
                        }
                        Spacer(minLength: 12)
                        Button("Preset: 2 Spione (10–20)") {
                            // Session profile for 2 imposters
                            impostersPerRound = 2
                            maxConsecutive = 2
                            minCooldownRounds = 2
                            recentWindow = 6
                            pairRecentWindow = 9
                            alphaFrequencyPenalty = 0.8
                            betaDistanceBonus = 0.17
                            gammaPairPenalty = 2.0
                            pairPenaltyDecay = 0.50
                            jitterPercent = 0.015
                            // New player handling
                            newPlayerHardCooldownRounds = 1
                            newPlayerSoftPenaltyRounds = 3
                            newPlayerPenaltyFactor = 0.3
                        }
                    }
                    
                    // Preset button
                    Button("Apply Small-Sample Preset") {
                        maxConsecutive = 2
                        minCooldownRounds = 1
                        recentWindow = 5
                        pairRecentWindow = 7
                        alphaFrequencyPenalty = 0.7
                        betaDistanceBonus = 0.15
                        gammaPairPenalty = 1.8
                        pairPenaltyDecay = 0.55
                        jitterPercent = 0.02
                        newPlayerHardCooldownRounds = 1
                        newPlayerSoftPenaltyRounds = 3
                        newPlayerPenaltyFactor = 0.3
                    }
                    
                    // Hard constraints
                    Stepper(value: $maxConsecutive, in: 1...3) {
                        Text("Max consecutive: \(maxConsecutive)")
                    }
                    Stepper(value: $minCooldownRounds, in: 0...3) {
                        Text("Min cooldown rounds: \(minCooldownRounds)")
                    }
                    Stepper(value: $recentWindow, in: 0...10) {
                        Text("Recent window: \(recentWindow)")
                    }
                    Stepper(value: $pairRecentWindow, in: 0...12) {
                        Text("Pair recent window: \(pairRecentWindow)")
                    }
                    
                    // Soft weights
                    VStack(alignment: .leading) {
                        Text(String(format: "alpha (freq penalty): %.2f", alphaFrequencyPenalty))
                        Slider(value: $alphaFrequencyPenalty, in: 0...1.5, step: 0.05)
                    }
                    VStack(alignment: .leading) {
                        Text(String(format: "beta (distance bonus): %.2f", betaDistanceBonus))
                        Slider(value: $betaDistanceBonus, in: 0...0.3, step: 0.01)
                    }
                    VStack(alignment: .leading) {
                        Text(String(format: "gamma (pair penalty): %.2f", gammaPairPenalty))
                        Slider(value: $gammaPairPenalty, in: 0...3.0, step: 0.1)
                    }
                    VStack(alignment: .leading) {
                        Text(String(format: "pair decay: %.2f", pairPenaltyDecay))
                        Slider(value: $pairPenaltyDecay, in: 0.1...1.0, step: 0.05)
                    }
                    VStack(alignment: .leading) {
                        Text(String(format: "jitter: %.3f", jitterPercent))
                        Slider(value: $jitterPercent, in: 0...0.1, step: 0.005)
                    }
                    
                    // New player handling
                    Stepper(value: $newPlayerHardCooldownRounds, in: 0...3) {
                        Text("New player hard cooldown: \(newPlayerHardCooldownRounds)")
                    }
                    Stepper(value: $newPlayerSoftPenaltyRounds, in: 0...6) {
                        Text("New player soft rounds: \(newPlayerSoftPenaltyRounds)")
                    }
                    VStack(alignment: .leading) {
                        Text(String(format: "New player penalty factor: %.2f", newPlayerPenaltyFactor))
                        Slider(value: $newPlayerPenaltyFactor, in: 0...1.0, step: 0.05)
                    }
                }
                
                Section {
                    Button(action: runSimulation) {
                        HStack {
                            Spacer()
                            if isRunning {
                                ProgressView()
                            } else {
                                Text("Run Simulator")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isRunning || playerList.count < impostersPerRound || playerList.count < 2)
                }
                
                if !results.isEmpty {
                    Section(header: Text("Results")) {
                        ScrollView {
                            Text(results)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                        }
                        .frame(minHeight: 200)
                    }
                }
            }
            .navigationTitle("Fairness Debug")
        }
    }
    
    private var playerList: [String] {
        playerNames
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func runSimulation() {
        isRunning = true
        results = ""
        DispatchQueue.global(qos: .userInitiated).async {
            let seed: UInt64? = UInt64(seedText)
            var policy = FairnessPolicy(
                maxConsecutive: maxConsecutive,
                minCooldownRounds: minCooldownRounds,
                recentWindow: recentWindow,
                pairRecentWindow: pairRecentWindow,
                alphaFrequencyPenalty: alphaFrequencyPenalty,
                betaDistanceBonus: betaDistanceBonus,
                gammaPairPenalty: gammaPairPenalty,
                pairPenaltyDecay: pairPenaltyDecay,
                newPlayerHardCooldownRounds: newPlayerHardCooldownRounds,
                newPlayerSoftPenaltyRounds: newPlayerSoftPenaltyRounds,
                newPlayerPenaltyFactor: newPlayerPenaltyFactor,
                jitterPercent: jitterPercent
            )
            // If testing with 2+ imposters per round, make cooldown a bit stricter automatically
            if impostersPerRound >= 2 {
                policy.minCooldownRounds = max(policy.minCooldownRounds, 2)
            }
            let result = FairnessSimulator.runSimulation(
                playerNames: playerList,
                impostersPerRound: impostersPerRound,
                rounds: rounds,
                policy: policy,
                seed: seed
            )
            let text = formatSummary(result, policy: policy)
            DispatchQueue.main.async {
                results = text
                if alsoPrintToConsole {
                    let banner = "\n=== Fairness Simulation Results ===\n\(text)\n===============================\n"
                    print(banner)
                    FairnessDebugView.logger.info("\(banner, privacy: .public)")
                    NSLog("%s", banner)
                }
                isRunning = false
            }
        }
    }
    
    private func formatSummary(_ result: SimulationResult, policy: FairnessPolicy) -> String {
        var lines: [String] = []
        lines.append("Total rounds: \(result.rounds)")
        lines.append("Global max consecutive (any player): \(result.maxConsecutive)")
        lines.append("Pair repeats within window: \(result.pairRepeatCount)")
        lines.append("")
        lines.append("Player stats (times imposter):")
        // Map UUID->name and sort by times desc
        let nameForId: (UUID) -> String = { id in result.players[id] ?? id.uuidString }
        let sorted = result.timesImposter.sorted { lhs, rhs in
            if lhs.value == rhs.value { return nameForId(lhs.key) < nameForId(rhs.key) }
            return lhs.value > rhs.value
        }
        for (id, count) in sorted {
            lines.append("  \(nameForId(id)): \(count)")
        }
        lines.append("")
        lines.append("Policy snapshot:")
        lines.append("  maxConsecutive: \(policy.maxConsecutive)")
        lines.append("  minCooldownRounds: \(policy.minCooldownRounds)")
        lines.append("  recentWindow: \(policy.recentWindow)")
        lines.append("  pairRecentWindow: \(policy.pairRecentWindow)")
        lines.append(String(format: "  alphaFrequencyPenalty: %.2f", policy.alphaFrequencyPenalty))
        lines.append(String(format: "  betaDistanceBonus: %.2f", policy.betaDistanceBonus))
        lines.append(String(format: "  gammaPairPenalty: %.2f", policy.gammaPairPenalty))
        lines.append(String(format: "  pairPenaltyDecay: %.2f", policy.pairPenaltyDecay))
        lines.append(String(format: "  jitterPercent: %.3f", policy.jitterPercent))
        lines.append("  newPlayerHardCooldownRounds: \(policy.newPlayerHardCooldownRounds)")
        lines.append("  newPlayerSoftPenaltyRounds: \(policy.newPlayerSoftPenaltyRounds)")
        lines.append(String(format: "  newPlayerPenaltyFactor: %.2f", policy.newPlayerPenaltyFactor))
        
        return lines.joined(separator: "\n")
    }
}

struct FairnessDebugView_Previews: PreviewProvider {
    static var previews: some View {
        FairnessDebugView()
    }
}

