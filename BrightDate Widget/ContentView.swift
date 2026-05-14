//
//  ContentView.swift
//  BrightDate Widget
//
//  Created by Jessica Mulein on 5/13/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("BrightDate")
                .font(.largeTitle.bold())
            Text("This is a widget-only app.")
                .font(.headline)
            Text("Add the BrightDate widget to your Home Screen or Desktop to see the current date.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
