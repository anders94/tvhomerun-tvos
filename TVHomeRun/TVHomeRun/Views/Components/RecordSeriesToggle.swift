//
//  RecordSeriesToggle.swift
//  TVHomeRun
//
//  Toggle that creates or removes the series recording rule for a series
//

import SwiftUI

struct RecordSeriesToggle: View {
    let seriesId: String
    @ObservedObject var apiClient: APIClient
    /// When the caller already knows whether the series is recording, pass it
    /// so the toggle renders correctly before the rules request returns.
    var assumeRecording: Bool? = nil

    @State private var isOn = false
    @State private var rule: RecordingRule?
    @State private var isBusy = false
    @State private var isLoaded = false

    var body: some View {
        Toggle("Record Series", systemImage: "record.circle", isOn: $isOn)
            .disabled(isBusy)
            .task(id: seriesId) {
                await loadRule()
            }
            .onChange(of: isOn) { _, wantsRecording in
                // Ignore programmatic changes (initial load, error revert);
                // only act when the toggle disagrees with the known rule state.
                guard isLoaded, !isBusy, wantsRecording != (rule != nil) else { return }
                Task { await apply(wantsRecording) }
            }
    }

    private func loadRule() async {
        if let assumeRecording {
            isOn = assumeRecording
        }
        if let rules = try? await apiClient.fetchRecordingRules().rules {
            rule = rules.first { $0.seriesId == seriesId }
            isOn = rule != nil
        }
        isLoaded = true
    }

    private func apply(_ enable: Bool) async {
        isBusy = true
        defer { isBusy = false }
        do {
            if enable {
                rule = try await apiClient.createRecordingRule(seriesId: seriesId).recordingRule
            } else if let id = rule?.id {
                try await apiClient.deleteRecordingRule(ruleId: id)
                rule = nil
            }
        } catch {
            // Revert; the shared connection alert reports the failure.
            isOn = !enable
        }
    }
}
