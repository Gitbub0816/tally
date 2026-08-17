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
        ZStack {
            LinearGradient(
                colors: [Color(hex: encounter.palette.secondaryHex), Color(hex: encounter.palette.primaryHex)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.7).frame(width: 130).offset(x: 58, y: -48)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("№ \(String(format: "%04d", encounter.rarityScore * 37 + encounter.altitudeFeet % 997))")
                        .font(.system(size: 6.5, weight: .bold, design: .monospaced)).tracking(0.8)
                    Spacer()
                    Text("\(encounter.rarityScore)").font(.system(size: 12, weight: .black, design: .monospaced))
                }.foregroundStyle(.white.opacity(0.9))
                AircraftArtwork(encounter: encounter, compact: true)
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, -4)
                VStack(alignment: .leading, spacing: 5) {
                    Text(encounter.aircraft.livery ?? encounter.aircraft.airline)
                        .font(.system(size: 14, weight: .bold, design: .serif)).foregroundStyle(TallyTheme.bone).lineLimit(1)
                    HStack {
                        Text(encounter.aircraft.registration).microLabel()
                        Spacer()
                        Text(encounter.rarity.title).font(.system(size: 6.5, weight: .black, design: .monospaced)).tracking(0.7).foregroundStyle(TallyTheme.brass)
                    }
                }
                .padding(10).background(TallyTheme.panel.opacity(0.96), in: RoundedRectangle(cornerRadius: 10))
            }.padding(10)
        }
        .aspectRatio(0.72, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Color(hex: encounter.palette.accentHex).opacity(0.8), lineWidth: 1))
        .shadow(color: .black.opacity(0.18), radius: 8, y: 5)
    }
}
