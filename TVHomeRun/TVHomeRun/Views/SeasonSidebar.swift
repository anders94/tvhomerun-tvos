//
//  SeasonSidebar.swift
//  TVHomeRun
//
//  Vertical list of seasons; selection follows focus, pressing jumps into the episode list
//

import SwiftUI

struct SeasonSidebar: View {
    let groups: [SeasonGroup]
    let selected: SeasonKey?
    var focus: FocusState<ShowDetailView.Focus?>.Binding
    var onSelect: (SeasonKey) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(groups) { group in
                    let isSelected = group.key == selected
                    Button {
                        onSelect(group.key)
                    } label: {
                        HStack {
                            Text(group.key.title)
                            Spacer()
                            Text("\(group.episodes.count)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .fontWeight(isSelected ? .semibold : .regular)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(isSelected ? Color.accentColor : Color.secondary)
                    .focused(focus, equals: .season(group.key))
                }
            }
            .padding(.vertical, 20)
        }
    }
}
