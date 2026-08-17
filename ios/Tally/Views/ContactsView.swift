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
        RadarScope(encounters: Array(store.encounters.prefix(5)))
            .frame(height: 340).padding(.horizontal, 2)
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
            AircraftArtwork(encounter: encounter, compact: true)
                .frame(width: 58, height: 38)
                .padding(5)
                .background(Color(hex: encounter.palette.primaryHex).opacity(0.22), in: RoundedRectangle(cornerRadius: 10))
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

private struct RadarScope: View {
    let encounters: [Encounter]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 24.0)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 6) / 6
            scope(angle: reduceMotion ? 42 : phase * 360)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Radar showing \(encounters.count) nearby aircraft contacts")
    }

    private func scope(angle: Double) -> some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let radius = side * 0.47
            ZStack {
                Circle().fill(RadialGradient(colors: [TallyTheme.olive.opacity(0.2), TallyTheme.panel], center: .center, startRadius: 2, endRadius: radius))
                ForEach(1...4, id: \.self) { ring in
                    Circle().stroke(TallyTheme.olive.opacity(0.42), style: StrokeStyle(lineWidth: 0.75, dash: ring == 4 ? [3, 3] : []))
                        .frame(width: radius * 2 * CGFloat(ring) / 4, height: radius * 2 * CGFloat(ring) / 4)
                }
                Path { path in
                    path.move(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2 - radius)); path.addLine(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2 + radius))
                    path.move(to: CGPoint(x: proxy.size.width / 2 - radius, y: proxy.size.height / 2)); path.addLine(to: CGPoint(x: proxy.size.width / 2 + radius, y: proxy.size.height / 2))
                }.stroke(TallyTheme.olive.opacity(0.3), lineWidth: 0.65)
                SweepWedge().fill(AngularGradient(colors: [TallyTheme.phosphor.opacity(0), TallyTheme.phosphor.opacity(0.25)], center: .center))
                    .frame(width: radius * 2, height: radius * 2).rotationEffect(.degrees(angle))
                Rectangle().fill(LinearGradient(colors: [TallyTheme.phosphor.opacity(0), TallyTheme.phosphor], startPoint: .leading, endPoint: .trailing))
                    .frame(width: radius, height: 1).offset(x: radius / 2).rotationEffect(.degrees(angle - 90))
                ForEach(Array(encounters.enumerated()), id: \.element.id) { index, encounter in
                    let bearing = Double(encounter.headingDegrees + index * 47) * .pi / 180
                    let contactRadius = CGFloat(min(max(encounter.distanceMiles / 12, 0.16), 0.9)) * radius
                    RadarBlip(encounter: encounter)
                        .offset(x: CGFloat(cos(bearing)) * contactRadius, y: CGFloat(sin(bearing)) * contactRadius)
                }
                Circle().fill(TallyTheme.phosphor).frame(width: 8, height: 8)
                    .overlay(Circle().stroke(TallyTheme.phosphor.opacity(0.4), lineWidth: 7))
                VStack {
                    HStack { Text("N"); Spacer(); Text("12 NM") }.padding(.horizontal, 14)
                    Spacer()
                    HStack { Text("270°"); Spacer(); Text("090°") }.padding(.horizontal, 12)
                }.padding(.vertical, 10).font(.system(size: 7, weight: .bold, design: .monospaced)).foregroundStyle(TallyTheme.muted)
            }
            .frame(width: side, height: side).position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            .overlay(alignment: .bottomLeading) {
                HStack(spacing: 12) {
                    Label("LIVE", systemImage: "dot.radiowaves.left.and.right")
                    Text("BNA  /  36.126°N 86.677°W")
                }.font(.system(size: 7.5, weight: .bold, design: .monospaced)).tracking(0.7).foregroundStyle(TallyTheme.muted).padding(12)
            }
        }
    }
}

private struct RadarBlip: View {
    let encounter: Encounter
    var body: some View {
        HStack(spacing: 4) {
            DiamondBlip().fill(encounter.rarityScore >= 70 ? TallyTheme.brass : TallyTheme.phosphor).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 0) {
                Text(encounter.aircraft.registration)
                Text("\(encounter.altitudeFeet / 100) · \(encounter.headingDegrees)°")
            }.font(.system(size: 6.5, weight: .bold, design: .monospaced)).foregroundStyle(TallyTheme.bone)
        }.padding(4).background(TallyTheme.panel.opacity(0.78), in: RoundedRectangle(cornerRadius: 4))
    }
}

private struct SweepWedge: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let center = CGPoint(x: rect.midX, y: rect.midY), radius = min(rect.width, rect.height) / 2
            path.move(to: center)
            path.addArc(center: center, radius: radius, startAngle: .degrees(-110), endAngle: .degrees(-90), clockwise: false)
            path.closeSubpath()
        }
    }
}

private struct DiamondBlip: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY)); path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY)); path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY)); path.addLine(to: CGPoint(x: rect.minX, y: rect.midY)); path.closeSubpath()
        }
    }
}
