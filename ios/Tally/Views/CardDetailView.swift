import SwiftUI

struct CardDetailView: View {
    @EnvironmentObject private var store: TallyStore
    @Environment(\.dismiss) private var dismiss
    let encounter: Encounter
    @State private var showingBack = false

    var body: some View {
        ZStack {
            TallyTheme.ink.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    HStack {
                        Button { dismiss() } label: { Image(systemName: "xmark").frame(width: 36, height: 36).background(TallyTheme.panel, in: Circle()) }
                        Spacer(); Text("CONTACT \(encounter.aircraft.registration)").microLabel(); Spacer()
                        ShareLink(item: shareText) { Image(systemName: "square.and.arrow.up").frame(width: 36, height: 36).background(TallyTheme.panel, in: Circle()) }
                    }.foregroundStyle(TallyTheme.bone)
                    AircraftCardView(encounter: encounter, showingBack: $showingBack)
                    if !encounter.isCollected {
                        HStack(spacing: 12) {
                            Button("PASS") { store.pass(encounter); dismiss() }
                                .buttonStyle(TallySecondaryButton())
                            Button("ADD TO TALLY") { store.collect(encounter); dismiss() }
                                .buttonStyle(TallyPrimaryButton())
                        }
                    } else {
                        Label("SAVED TO COLLECTION", systemImage: "checkmark.seal.fill").foregroundStyle(TallyTheme.phosphor).microLabel()
                    }
                }.padding(20)
            }
        }
    }

    private var shareText: String {
        "I tallied \(encounter.aircraft.registration), a \(encounter.aircraft.displayModel) in \(encounter.aircraft.livery ?? encounter.aircraft.airline) colors, flying \(encounter.route). #Tally"
    }
}

struct TallyPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 12, weight: .bold, design: .monospaced)).tracking(1).foregroundStyle(TallyTheme.ink).frame(maxWidth: .infinity).padding(.vertical, 15).background(TallyTheme.brass.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct TallySecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 12, weight: .bold, design: .monospaced)).tracking(1).foregroundStyle(TallyTheme.bone).frame(maxWidth: .infinity).padding(.vertical, 15).background(TallyTheme.panel, in: RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(TallyTheme.muted.opacity(0.4)))
    }
}
