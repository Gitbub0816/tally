import SwiftUI

struct AircraftCardView: View {
    let encounter: Encounter
    @Binding var showingBack: Bool

    var body: some View {
        ZStack {
            if showingBack { back.transition(.opacity.combined(with: .scale(scale: 0.97))) }
            else { front.transition(.opacity.combined(with: .scale(scale: 0.97))) }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.685, contentMode: .fit)
        .animation(.spring(response: 0.45, dampingFraction: 0.84), value: showingBack)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 20).onEnded { value in
            if value.translation.height < -35 { showingBack = true }
            if value.translation.height > 35 { showingBack = false }
        })
        .onTapGesture { showingBack.toggle() }
    }

    private var shell: some Shape { RoundedRectangle(cornerRadius: 26, style: .continuous) }

    private var front: some View {
        ZStack {
            shell.fill(TallyTheme.cardGradient)
            LinearGradient(colors: [Color(hex: encounter.palette.primaryHex).opacity(0.35), .clear], startPoint: .top, endPoint: .center)
                .clipShape(shell)
            VStack(alignment: .leading, spacing: 0) {
                cardHeader
                Spacer(minLength: 15)
                aircraftIllustration
                Spacer()
                Text(encounter.aircraft.livery ?? "STANDARD LIVERY")
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                    .foregroundStyle(TallyTheme.bone)
                    .minimumScaleFactor(0.7)
                Text("\(encounter.aircraft.airline.uppercased()) · \(encounter.aircraft.displayModel.uppercased())")
                    .microLabel().padding(.top, 5)
                Divider().overlay(TallyTheme.brass.opacity(0.45)).padding(.vertical, 14)
                HStack {
                    stat("TAIL", encounter.aircraft.registration)
                    Spacer(); stat("ROUTE", encounter.route)
                    Spacer(); stat("ALT", "\(encounter.altitudeFeet.formatted()) FT")
                }
            }
            .padding(22)
            VStack { Spacer(); HStack { Spacer(); Text("SWIPE UP · DOSSIER").microLabel() } }.padding(18)
        }
        .overlay(shell.stroke(LinearGradient(colors: [TallyTheme.brass.opacity(0.8), TallyTheme.olive.opacity(0.5), TallyTheme.brass.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.2))
        .shadow(color: .black.opacity(0.55), radius: 25, y: 14)
    }

    private var back: some View {
        ZStack {
            shell.fill(TallyTheme.panel)
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AIRCRAFT DOSSIER").microLabel()
                        Text(encounter.aircraft.registration).font(.system(size: 27, weight: .medium, design: .monospaced)).foregroundStyle(TallyTheme.bone)
                    }
                    Spacer(); raritySeal
                }
                Divider().overlay(TallyTheme.brass.opacity(0.4))
                dossierRow("TYPE", encounter.aircraft.displayModel)
                dossierRow("OPERATOR", encounter.aircraft.airline)
                dossierRow("VARIANT", encounter.aircraft.variant)
                dossierRow("YEAR BUILT", "\(encounter.aircraft.yearBuilt)")
                dossierRow("POWERPLANT", encounter.aircraft.engines)
                dossierRow("CRUISE", "\(encounter.aircraft.cruiseSpeedKnots) KT")
                dossierRow("RANGE", "\(encounter.aircraft.rangeNauticalMiles.formatted()) NM")
                dossierRow("CAPACITY", "\(encounter.aircraft.seats) SEATS")
                Divider().overlay(TallyTheme.brass.opacity(0.4))
                Text("WHY THIS TALLY").microLabel()
                ForEach(encounter.rarityReasons, id: \.self) { reason in
                    Label(reason, systemImage: "diamond.fill")
                        .font(.caption).foregroundStyle(TallyTheme.bone)
                        .symbolRenderingMode(.monochrome)
                }
                Spacer()
                Text("PULL DOWN TO RETURN").microLabel().frame(maxWidth: .infinity)
            }.padding(22)
        }
        .overlay(shell.stroke(TallyTheme.brass.opacity(0.65), lineWidth: 1.2))
        .shadow(color: .black.opacity(0.55), radius: 25, y: 14)
    }

    private var cardHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TALLY · VERIFIED CONTACT").microLabel()
                Text(encounter.flightNumber).font(.system(size: 18, weight: .medium, design: .monospaced)).foregroundStyle(TallyTheme.bone)
            }
            Spacer(); raritySeal
        }
    }

    private var raritySeal: some View {
        VStack(spacing: 1) {
            Text("\(encounter.rarityScore)").font(.system(size: 20, weight: .bold, design: .monospaced))
            Text(encounter.rarity.title).font(.system(size: 7, weight: .bold, design: .monospaced)).tracking(1)
        }
        .foregroundStyle(encounter.rarityScore >= 70 ? TallyTheme.brass : TallyTheme.bone)
        .frame(width: 62, height: 62).overlay(Circle().stroke(TallyTheme.brass.opacity(0.7)))
    }

    private var aircraftIllustration: some View {
        ZStack {
            Ellipse().fill(Color.black.opacity(0.45)).frame(width: 270, height: 26).blur(radius: 12).offset(y: 48)
            Image(systemName: "airplane")
                .resizable().scaledToFit().frame(width: 285, height: 155)
                .rotationEffect(.degrees(-8))
                .foregroundStyle(LinearGradient(colors: [Color(hex: encounter.palette.primaryHex), Color(hex: encounter.palette.secondaryHex)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: Color(hex: encounter.palette.accentHex).opacity(0.35), radius: 14)
        }.frame(height: 190)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) { Text(label).microLabel(); Text(value).font(.system(size: 11, weight: .semibold, design: .monospaced)).foregroundStyle(TallyTheme.bone) }
    }

    private func dossierRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).microLabel(); Spacer(); Text(value).font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundStyle(TallyTheme.bone).multilineTextAlignment(.trailing) }
    }
}

