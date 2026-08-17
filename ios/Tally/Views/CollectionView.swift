import SwiftUI

struct CollectionView: View {
    @EnvironmentObject private var store: TallyStore
    @State private var filter = "All"
    @State private var activeCard: Encounter?
    private let filters = ["All", "Liveries", "Tails", "Types", "Airlines", "Routes"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ScreenHeader(eyebrow: "PERSONAL FLIGHTLINE", title: "Collection", trailing: "\(store.collected.count) TALLIES")
                    collectionSummary
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack { ForEach(filters, id: \.self) { item in filterButton(item) } }
                    }
                    if store.collected.isEmpty { emptyState }
                    else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(store.collected) { encounter in
                                MiniCard(encounter: encounter).onTapGesture { activeCard = encounter }
                            }
                        }
                    }
                    Text("RECENTLY ENCOUNTERED").microLabel().padding(.top, 8)
                    ForEach(store.encounters.prefix(4)) { encounter in
                        ContactRow(encounter: encounter).onTapGesture { activeCard = encounter }
                    }
                }.padding(20)
            }
            .background(TallyTheme.ink.ignoresSafeArea())
            .sheet(item: $activeCard) { CardDetailView(encounter: $0) }
        }
    }

    private var collectionSummary: some View {
        HStack {
            summary("TYPES", "6"); Spacer(); summary("AIRLINES", "5"); Spacer(); summary("LIVERIES", "3"); Spacer(); summary("ROUTES", "7")
        }.padding(16).background(TallyTheme.panel, in: RoundedRectangle(cornerRadius: 16))
    }

    private func summary(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) { Text(value).font(.title3.monospacedDigit()).foregroundStyle(TallyTheme.bone); Text(label).microLabel() }
    }

    private func filterButton(_ item: String) -> some View {
        Button { filter = item } label: {
            Text(item.uppercased()).font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1).padding(.horizontal, 14).padding(.vertical, 10).background(filter == item ? TallyTheme.brass : TallyTheme.panel, in: Capsule()).foregroundStyle(filter == item ? TallyTheme.ink : TallyTheme.bone)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) { Image(systemName: "rectangle.stack.badge.plus").font(.largeTitle); Text("Your flightline is waiting").font(.headline); Text("Collect a nearby contact to create your first Tally.").font(.subheadline).foregroundStyle(TallyTheme.muted) }.foregroundStyle(TallyTheme.bone).frame(maxWidth: .infinity).padding(40).background(TallyTheme.panel, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct MiniCard: View {
    let encounter: Encounter
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack { Text(encounter.rarity.title).microLabel(); Spacer(); Text("\(encounter.rarityScore)").font(.caption.monospaced()).foregroundStyle(TallyTheme.brass) }
            Image(systemName: "airplane").resizable().scaledToFit().frame(height: 68).foregroundStyle(LinearGradient(colors: [Color(hex: encounter.palette.primaryHex), Color(hex: encounter.palette.secondaryHex)], startPoint: .top, endPoint: .bottom))
            Text(encounter.aircraft.livery ?? encounter.aircraft.airline).font(.subheadline.weight(.semibold)).foregroundStyle(TallyTheme.bone).lineLimit(1)
            Text(encounter.aircraft.registration).microLabel()
        }.padding(14).aspectRatio(0.72, contentMode: .fit).background(TallyTheme.cardGradient, in: RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(TallyTheme.brass.opacity(0.42)))
    }
}

