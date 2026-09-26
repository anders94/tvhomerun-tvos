//
//  EpisodeSortMenu.swift
//  TVHomeRun
//
//  Sort controls for the show detail page
//

import SwiftUI

struct EpisodeSortMenu: View {
    @Binding var seasonOrder: SeasonSortOrder
    @Binding var episodeOrder: EpisodeDateOrder
    let showsSeasonOrder: Bool

    var body: some View {
        Menu {
            if showsSeasonOrder {
                Picker("Seasons", selection: $seasonOrder) {
                    ForEach(SeasonSortOrder.allCases) { order in
                        Text(order.title).tag(order)
                    }
                }
                .pickerStyle(.inline)
            }
            Picker("Episodes", selection: $episodeOrder) {
                ForEach(EpisodeDateOrder.allCases) { order in
                    Text(order.title).tag(order)
                }
            }
            .pickerStyle(.inline)
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }
}
