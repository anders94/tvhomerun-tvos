//
//  GuideDetailView.swift
//  TVHomeRun
//
//  Detail view for upcoming episodes of a series with recording toggle
//

import SwiftUI

struct GuideDetailView: View {
    let series: GuideSeries
    @ObservedObject var apiClient: APIClient
    let isRecording: Bool
    @State private var isRecordingEnabled = false
    @State private var currentRecordingRule: RecordingRule?
    @State private var isLoadingRules = true
    @State private var isUpdating = false
    @FocusState private var isToggleFocused: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                // Recording toggle section
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Record This Series")
                                .font(.system(size: 28, weight: .semibold))
                            Text("Automatically record new episodes")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $isRecordingEnabled)
                            .labelsHidden()
                            .focused($isToggleFocused)
                    }
                    .padding(30)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(15)
                }

                // Upcoming episodes section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Upcoming Episodes")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.horizontal, 30)

                    if series.programs.isEmpty {
                        Text("No upcoming episodes found")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                            .padding(30)
                    } else {
                        VStack(spacing: 20) {
                            ForEach(series.programs.sorted(by: { $0.startTime < $1.startTime })) { program in
                                GuideProgramCard(program: program)
                            }
                        }
                    }
                }
            }
            .padding(50)
            }
        }
        .navigationTitle(series.title)
        .task {
            // Set initial state immediately based on passed parameter
            isRecordingEnabled = isRecording
            isLoadingRules = false
            // Load recording rule in background to get the rule ID
            await loadRecordingStatus()
            // Set focus to toggle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isToggleFocused = true
            }
        }
        .onChange(of: isRecordingEnabled) { oldValue, newValue in
            // Only act on user changes, not initial load
            if !isLoadingRules && oldValue != newValue {
                Task {
                    await toggleRecording(enabled: newValue)
                }
            }
        }
        .disabled(isUpdating)
    }

    private func loadRecordingStatus() async {
        do {
            let response = try await apiClient.fetchRecordingRules()
            await MainActor.run {
                // Store the recording rule (we need the ID for deletion)
                currentRecordingRule = response.rules.first { $0.seriesId == series.id }
            }
        } catch {
            // Silently fail - user can still toggle to create rule
        }
    }

    private func toggleRecording(enabled: Bool) async {
        isUpdating = true
        do {
            if enabled {
                // Create new recording rule
                let response = try await apiClient.createRecordingRule(seriesId: series.id)
                await MainActor.run {
                    if let rule = response.recordingRule {
                        currentRecordingRule = rule
                    }
                    isUpdating = false
                }
            } else {
                // Delete existing recording rule
                if let ruleId = currentRecordingRule?.id {
                    try await apiClient.deleteRecordingRule(ruleId: ruleId)
                    await MainActor.run {
                        currentRecordingRule = nil
                        isUpdating = false
                    }
                }
            }
        } catch {
            await MainActor.run {
                // Revert toggle on error
                isRecordingEnabled = !enabled
                currentRecordingRule = enabled ? nil : currentRecordingRule
                isUpdating = false
            }
            // Error is already handled by APIClient's error alert
        }
    }
}

struct GuideProgramCard: View {
    let program: GuideProgram

    var body: some View {
        HStack(spacing: 20) {
            // Program image
            if let imageUrl = program.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.3)
                            ProgressView()
                        }
                        .frame(width: 120, height: 180)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 180)
                            .clipped()
                    case .failure:
                        ZStack {
                            Color.gray.opacity(0.3)
                            Image(systemName: "tv")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 120, height: 180)
                    @unknown default:
                        Color.gray.opacity(0.3)
                            .frame(width: 120, height: 180)
                    }
                }
                .cornerRadius(10)
            } else {
                // Placeholder when no image
                ZStack {
                    Color.gray.opacity(0.3)
                    Image(systemName: "tv")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
                .frame(width: 120, height: 180)
                .cornerRadius(10)
            }

            VStack(alignment: .leading, spacing: 12) {
                // Show episode title if available, otherwise show series title
                if let episodeTitle = program.episodeTitle, !episodeTitle.isEmpty {
                    Text(episodeTitle)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                } else {
                    Text(program.title)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }

                if let episodeNumber = program.episodeNumber, !episodeNumber.isEmpty {
                    Text(episodeNumber)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.blue)
                }

                HStack(spacing: 12) {
                    Text(program.formattedStartTime)
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text("\(program.durationMinutes) min")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }

                if let synopsis = program.synopsis, !synopsis.isEmpty {
                    Text(synopsis)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .padding(.horizontal, 30)
    }
}
