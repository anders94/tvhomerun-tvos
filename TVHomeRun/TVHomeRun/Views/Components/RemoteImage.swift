//
//  RemoteImage.swift
//  TVHomeRun
//
//  Shared async image with loading and fallback states
//

import SwiftUI

/// Loads an image from an optional URL string into whatever frame the caller
/// gives it, showing a neutral placeholder while loading and a symbol when the
/// URL is missing or fails. Callers apply `.frame` and a clip shape.
struct RemoteImage: View {
    let url: String?
    var fallbackSystemImage: String = "tv"
    var contentMode: ContentMode = .fill

    var body: some View {
        Rectangle()
            .fill(.fill.tertiary)
            .overlay {
                AsyncImage(url: url.flatMap(URL.init(string:))) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    case .empty:
                        ProgressView()
                    default:
                        Image(systemName: fallbackSystemImage)
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .clipped()
    }
}
