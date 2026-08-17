import SwiftUI

struct ContactsView: View {
    @EnvironmentObject private var store: TallyStore
    @State private var activeCard: Encounter?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ScreenHeader(eyebrow: "RADAR SESSION 03:42:18", title: "Contacts", trailing: "BNA · 12 NM")
                    awayBriefing
                    sessionControl
                    radar
                    prioritySection
                    allContacts
                }
                .padding(20)
            }
            .background(TallyTheme.ink.ignoresSafeArea())
            .sheet(item: $activeCard) { encounter in
                CardDetailView(encounter: encounter)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var sessionControl: some View {
        Group {
            if let session = store.radarSession, session.isActive {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RADAR ACTIVE").microLabel()
                        Text("Until \(session.endsAt.formatted(date: .omitted, time: .shortened)) · \(session.radiusMiles.formatted()) mile radius")
                            .font(.caption).foregroundStyle(TallyTheme.bone)
                    }
                    Spacer()
                    Button("END") { store.stopRadarSession() }
                        .font(.caption.bold()).foregroundStyle(TallyTheme.signal)
                }
            } else {
                Button { store.startRadarSession(); Task { await store.refresh() } } label: {
                    Label("START 2-HOUR RADAR SESSION", systemImage: "antenna.radiowaves.left.and.right")
                        .frame(maxWidth: .infinity)
                }.buttonStyle(TallyPrimaryButton())
            }
        }
        .padding(14)
        .background(TallyTheme.panel, in: RoundedRectangle(cornerRadius: 15))
    }

    private var awayBriefing: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(TallyTheme.olive.opacity(0.35)).frame(width: 52, height: 52)
                Image(systemName: "antenna.radiowaves.left.and.right").foregroundStyle(TallyTheme.phosphor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("WHILE YOU WERE AWAY").microLabel()
                Text("8 aircraft crossed your airspace")
                    .font(.headline).foregroundStyle(TallyTheme.bone)
                Text("3 may be worth a closer look")
                    .font(.subheadline).foregroundStyle(TallyTheme.muted)
            }
            Spacer()
        }
        .padding(16)
        .background(TallyTheme.panel, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(TallyTheme.brass.opacity(0.28)))
    }

    private var radar: some View {
        ZStack {
            ForEach([0.28, 0.52, 0.76, 1.0], id: \.self) { scale in
                Circle().stroke(TallyTheme.olive.opacity(0.35), lineWidth: 0.7).scaleEffect(scale)
            }
            Path { path in
                path.move(to: CGPoint(x: 160, y: 10)); path.addLine(to: CGPoint(x: 160, y: 310))
                path.move(to: CGPoint(x: 10, y: 160)); path.addLine(to: CGPoint(x: 310, y: 160))
            }.stroke(TallyTheme.olive.opacity(0.22), lineWidth: 0.7)
            Circle().fill(TallyTheme.phosphor).frame(width: 7).offset(x: 42, y: -68)
            Circle().fill(TallyTheme.brass).frame(width: 7).offset(x: -92, y: 32)
            Image(systemName: "airplane").foregroundStyle(TallyTheme.bone).rotationEffect(.degrees(24)).offset(x: 77, y: 81)
            VStack { HStack { Text("N").microLabel(); Spacer() }; Spacer() }.padding(12)
        }
        .frame(height: 320)
        .background(
            RadialGradient(colors: [TallyTheme.olive.opacity(0.15), TallyTheme.panel], center: .center, startRadius: 5, endRadius: 190),
            in: RoundedRectangle(cornerRadius: 160)
        )
        .overlay(Circle().stroke(TallyTheme.olive.opacity(0.6)))
        .padding(.horizontal, 8)
    }

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PRIORITY CONTACTS").microLabel()
            ForEach(store.priorityContacts.prefix(3)) { encounter in
                ContactRow(encounter: encounter)
                    .onTapGesture { activeCard = encounter }
            }
        }
    }

    private var allContacts: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ALL CONTACTS").microLabel()
            ForEach(store.encounters.filter { !store.priorityContacts.contains($0) }) { encounter in
                ContactRow(encounter: encounter)
                    .onTapGesture { activeCard = encounter }
            }
        }
    }
}

struct ContactRow: View {
    let encounter: Encounter

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: "airplane")
                .rotationEffect(.degrees(Double(encounter.headingDegrees - 90)))
                .frame(width: 38, height: 38)
                .background(TallyTheme.elevated, in: Circle())
                .foregroundStyle(encounter.rarityScore >= 70 ? TallyTheme.brass : TallyTheme.bone)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(encounter.aircraft.livery ?? encounter.aircraft.airline)
                        .font(.headline).foregroundStyle(TallyTheme.bone).lineLimit(1)
                    Spacer()
                    Text(encounter.rarity.title)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(encounter.rarityScore >= 70 ? TallyTheme.brass : TallyTheme.muted)
                }
                Text("\(encounter.aircraft.airline) · \(encounter.aircraft.displayModel)")
                    .font(.caption).foregroundStyle(TallyTheme.muted)
                HStack {
                    Text(encounter.aircraft.registration)
                    Text(encounter.route)
                    Spacer()
                    Text(String(format: "%.1f MI", encounter.distanceMiles))
                }
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(TallyTheme.muted)
            }
        }
        .padding(14)
        .background(TallyTheme.panel, in: RoundedRectangle(cornerRadius: 15))
    }
}
