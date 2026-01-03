//
//  QuestionGameWrapper.swift
//  Games Collection
//
//  Created by Ken  on 27.12.25.
//


import SwiftUI

struct QuestionGameWrapper: View {
    // Hier erstellen wir das Herzstück (Daten-Speicher) für das Frage-Spiel,
    // genau so, wie wir es vorher in der QuestionApp gemacht haben.
    @StateObject private var appModel = AppModel()

    var body: some View {
        // Wir starten den Container und übergeben das Model
        QuestionsModeContainer(appModel: appModel)
    }
}