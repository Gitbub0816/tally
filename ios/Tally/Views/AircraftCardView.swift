import SwiftUI

struct AircraftCardView: View {
    let encounter: Encounter
    @Binding var showingBack: Bool

    var body: some View {
        ZStack {
            if showingBack { back.transition(.opacity.combined(with: .scale(scale: 0.975))) }
            else { front.transition(.opacity.combined(with: .scale(scale: 0.975))) }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.685, contentMode: .fit)
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: showingBack)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 20).onEnded { value in
            if value.translation.height < -35 { showingBack = true }
            if value.translation.height > 35 { showingBack = false }
        })
        .onTapGesture { showingBack.toggle() }
        .accessibilityAction(named: showingBack ? "Show card front" : "Show aircraft dossier") { showingBack.toggle() }
    }

    private var shell: some Shape { RoundedRectangle(cornerRadius: 28, style: .continuous) }
    private var primary: Color { Color(hex: encounter.palette.primaryHex) }
    private var secondary: Color { Color(hex: encounter.palette.secondaryHex) }
    private var accent: Color { Color(hex: encounter.palette.accentHex) }
    private var serial: String { String(format: "%04d", encounter.rarityScore * 37 + encounter.altitudeFeet % 997) }

    private var front: some View {
        ZStack {
            shell.fill(TallyTheme.panel)
            cardColorField
            technicalGrid.opacity(0.22).clipShape(shell)

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("TALLY AIRCRAFT ARCHIVE").font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(1.6)
                        Text("SERIES 01  /  № \(serial)").font(.system(size: 8, weight: .medium, design: .monospaced)).opacity(0.7)
                    }
                    Spacer()
                    rarityBadge
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 21).padding(.top, 20)

                ZStack(alignment: .topLeading) {
                    Text(encounter.aircraft.registration)
                        .font(.system(size: 41, weight: .black, design: .rounded))
                        .tracking(-1.5)
                        .foregroundStyle(Color.white.opacity(0.12))
                        .padding(.leading, 18).padding(.top, 6)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(encounter.aircraft.airline.uppercased())
                            .font(.system(size: 10, weight: .black, design: .rounded)).tracking(1.8)
                            .foregroundStyle(.white.opacity(0.84))
                            .padding(.leading, 21).padding(.top, 20)
                        Spacer()
                        AircraftArtwork(encounter: encounter)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 2)
                    }
                }
                .frame(maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(encounter.aircraft.livery ?? encounter.aircraft.airline)
                            .font(.system(size: 27, weight: .bold, design: .serif))
                            .foregroundStyle(TallyTheme.bone)
                            .lineLimit(2).minimumScaleFactor(0.72)
                        Spacer(minLength: 10)
                        Text(encounter.flightNumber)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(TallyTheme.brass)
                    }
                    Text(encounter.aircraft.displayModel.uppercased())
                        .font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1.35)
                        .foregroundStyle(TallyTheme.muted).padding(.top, 6)

                    routeStrip.padding(.top, 15)
                    Divider().overlay(TallyTheme.brass.opacity(0.35)).padding(.vertical, 13)
                    HStack {
                        stat("TAIL", encounter.aircraft.registration)
                        Spacer(); stat("CAPTURED", encounter.capturedAt.formatted(date: .abbreviated, time: .omitted).uppercased())
                        Spacer(); stat("ALTITUDE", "\(encounter.altitudeFeet.formatted()) FT")
                    }
                    HStack {
                        Label("VERIFIED CONTACT", systemImage: "checkmark.seal.fill")
                        Spacer(); Text("TAP / SWIPE FOR DOSSIER")
                    }
                    .font(.system(size: 7.5, weight: .bold, design: .monospaced)).tracking(0.75)
                    .foregroundStyle(TallyTheme.muted).padding(.top, 14)
                }
                .padding(.horizontal, 21).padding(.vertical, 19)
                .background(TallyTheme.panel.opacity(0.97))
            }
            rarityEdge
        }
        .clipShape(shell)
        .overlay(shell.stroke(borderGradient, lineWidth: 1.35))
        .shadow(color: .black.opacity(0.34), radius: 28, y: 14)
    }

    private var cardColorField: some View {
        ZStack {
            LinearGradient(colors: [secondary, primary], startPoint: .topLeading, endPoint: .bottomTrailing)
            DiagonalBand().fill(accent.opacity(0.88)).rotationEffect(.degrees(-7)).offset(x: 105, y: -65)
            Circle().stroke(Color.white.opacity(0.18), lineWidth: 1).frame(width: 265).offset(x: 112, y: 75)
            Circle().stroke(Color.white.opacity(0.12), lineWidth: 1).frame(width: 165).offset(x: 112, y: 75)
            if encounter.rarityScore >= 78 {
                LinearGradient(colors: [.clear, Color.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .blendMode(.screen).rotationEffect(.degrees(-18)).offset(x: -70)
            }
        }.clipShape(shell)
    }

    private var technicalGrid: some View {
        GeometryReader { proxy in
            Path { path in
                stride(from: 0.0, through: proxy.size.width, by: 32).forEach { x in
                    path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: proxy.size.height * 0.65))
                }
                stride(from: 0.0, through: proxy.size.height * 0.65, by: 32).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                }
            }.stroke(Color.white.opacity(0.3), lineWidth: 0.45)
        }
    }

    private var rarityEdge: some View {
        HStack { Rectangle().fill(accent).frame(width: 5); Spacer() }
            .allowsHitTesting(false)
    }

    private var rarityBadge: some View {
        HStack(spacing: 7) {
            Text("\(encounter.rarityScore)").font(.system(size: 17, weight: .black, design: .monospaced))
            VStack(alignment: .leading, spacing: 0) {
                Text(encounter.rarity.title).font(.system(size: 7, weight: .black, design: .monospaced)).tracking(1)
                Text("RARITY INDEX").font(.system(size: 6, weight: .medium, design: .monospaced)).opacity(0.7)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(Color.black.opacity(0.24), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 0.7))
    }

    private var routeStrip: some View {
        HStack(spacing: 9) {
            Text(encounter.origin).font(.system(size: 18, weight: .black, design: .monospaced))
            Circle().fill(TallyTheme.brass).frame(width: 5)
            Rectangle().fill(TallyTheme.brass.opacity(0.5)).frame(height: 1)
            Image(systemName: "airplane").font(.caption).foregroundStyle(TallyTheme.brass)
            Rectangle().fill(TallyTheme.brass.opacity(0.5)).frame(height: 1)
            Circle().fill(TallyTheme.brass).frame(width: 5)
            Text(encounter.destination).font(.system(size: 18, weight: .black, design: .monospaced))
        }.foregroundStyle(TallyTheme.bone)
    }

    private var back: some View {
        ZStack {
            shell.fill(TallyTheme.panel)
            technicalGrid.opacity(0.07).clipShape(shell)
            VStack(alignment: .leading, spacing: 15) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AIRFRAME DOSSIER").microLabel()
                        Text(encounter.aircraft.registration)
                            .font(.system(size: 28, weight: .black, design: .monospaced)).foregroundStyle(TallyTheme.bone)
                        Text("\(encounter.aircraft.airline.uppercased()) / \(encounter.flightNumber)")
                            .font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(1).foregroundStyle(TallyTheme.muted)
                    }
                    Spacer(); rarityBadge.foregroundStyle(TallyTheme.bone)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 16).fill(TallyTheme.ink)
                    VStack(spacing: 12) {
                        HStack { airport(encounter.origin, "ORIGIN"); Spacer(); Image(systemName: "airplane").foregroundStyle(TallyTheme.brass); Spacer(); airport(encounter.destination, "DESTINATION") }
                        HStack { Circle().fill(TallyTheme.brass).frame(width: 8); Rectangle().fill(TallyTheme.brass.opacity(0.5)).frame(height: 1); Circle().fill(TallyTheme.brass).frame(width: 8) }
                    }.padding(17)
                }.frame(height: 92)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    dossierCell("AIRCRAFT", encounter.aircraft.displayModel)
                    dossierCell("VARIANT", encounter.aircraft.variant)
                    dossierCell("POWERPLANT", encounter.aircraft.engines)
                    dossierCell("YEAR", encounter.aircraft.yearBuilt == 0 ? "—" : "\(encounter.aircraft.yearBuilt)")
                    dossierCell("CRUISE", value(encounter.aircraft.cruiseSpeedKnots, suffix: " KT"))
                    dossierCell("RANGE", value(encounter.aircraft.rangeNauticalMiles, suffix: " NM"))
                }

                Divider().overlay(TallyTheme.brass.opacity(0.35))
                Text("WHY IT SCORED \(encounter.rarityScore)").microLabel()
                ForEach(encounter.rarityReasons.prefix(3), id: \.self) { reason in
                    HStack(alignment: .top, spacing: 9) {
                        Diamond().fill(TallyTheme.brass).frame(width: 8, height: 8).padding(.top, 3)
                        Text(reason).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(TallyTheme.bone)
                    }
                }
                Spacer(minLength: 0)
                HStack { Text("ARCHIVE № \(serial)"); Spacer(); Text("SWIPE DOWN TO RETURN") }
                    .font(.system(size: 7.5, weight: .bold, design: .monospaced)).tracking(0.9).foregroundStyle(TallyTheme.muted)
            }.padding(22)
            rarityEdge
        }
        .clipShape(shell)
        .overlay(shell.stroke(borderGradient, lineWidth: 1.25))
        .shadow(color: .black.opacity(0.34), radius: 28, y: 14)
    }

    private var borderGradient: LinearGradient {
        LinearGradient(colors: [accent.opacity(0.95), TallyTheme.brass.opacity(0.65), primary.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func airport(_ code: String, _ label: String) -> some View {
        VStack(alignment: label == "ORIGIN" ? .leading : .trailing, spacing: 2) {
            Text(code).font(.system(size: 22, weight: .black, design: .monospaced)).foregroundStyle(TallyTheme.bone)
            Text(label).microLabel()
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 7, weight: .bold, design: .monospaced)).tracking(1).foregroundStyle(TallyTheme.muted)
            Text(value).font(.system(size: 9.5, weight: .bold, design: .monospaced)).foregroundStyle(TallyTheme.bone).lineLimit(1).minimumScaleFactor(0.7)
        }
    }

    private func dossierCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).microLabel()
            Text(value).font(.system(size: 11, weight: .semibold, design: .monospaced)).foregroundStyle(TallyTheme.bone).lineLimit(2).minimumScaleFactor(0.75)
        }.frame(maxWidth: .infinity, minHeight: 48, alignment: .topLeading).padding(10).background(TallyTheme.elevated.opacity(0.7), in: RoundedRectangle(cornerRadius: 10))
    }

    private func value(_ number: Int, suffix: String) -> String { number == 0 ? "—" : number.formatted() + suffix }
}

private struct DiagonalBand: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.width * 0.58, y: -rect.height * 0.1))
            path.addLine(to: CGPoint(x: rect.width * 1.08, y: rect.height * 0.03))
            path.addLine(to: CGPoint(x: rect.width * 0.78, y: rect.height * 0.72))
            path.addLine(to: CGPoint(x: rect.width * 0.34, y: rect.height * 0.57))
            path.closeSubpath()
        }
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY)); path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY)); path.addLine(to: CGPoint(x: rect.minX, y: rect.midY)); path.closeSubpath()
        }
    }
}
