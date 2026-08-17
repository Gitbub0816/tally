import SwiftUI
import AuthenticationServices

struct ProfileView: View {
    @EnvironmentObject private var store: TallyStore
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ScreenHeader(eyebrow: "COLLECTOR PROFILE", title: "Caleb", trailing: "@CALEB")
                    HStack(spacing: 18) {
                        Circle().fill(LinearGradient(colors: [TallyTheme.olive, TallyTheme.panel], startPoint: .top, endPoint: .bottom)).frame(width: 84, height: 84).overlay(Text("C").font(.system(size: 34, weight: .medium, design: .rounded)).foregroundStyle(TallyTheme.bone)).overlay(Circle().stroke(TallyTheme.brass))
                        VStack(alignment: .leading, spacing: 6) { Text("BNA · NASHVILLE").microLabel(); Text("Tracking the uncommon aircraft hiding in ordinary skies.").font(.subheadline).foregroundStyle(TallyTheme.bone); Text("TALLY MEMBER 0017").microLabel() }
                    }
                    if !store.environment.isDemo && !store.isSignedIn {
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            guard case .success(let authorization) = result,
                                  let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                                  let data = credential.identityToken,
                                  let token = String(data: data, encoding: .utf8) else { return }
                            Task { await store.signIn(identityToken: token) }
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 48)
                    }
                    HStack { metric("128", "TALLIES"); Spacer(); metric("34", "LIVERIES"); Spacer(); metric("19", "TYPES"); Spacer(); metric("42", "ROUTES") }.padding(18).background(TallyTheme.panel, in: RoundedRectangle(cornerRadius: 16))
                    Text("ACHIEVEMENTS").microLabel()
                    achievement("diamond.fill", "State Colors", "Collected three Southwest state liveries")
                    achievement("airplane.arrival", "Rare Here", "Tallied a widebody arrival at BNA")
                    achievement("person.2.fill", "On Frequency", "Joined five UNICOM frequencies")
                    Text("WATCHLIST").microLabel().padding(.top, 8)
                    watch("Tennessee One", "LIVERY", true)
                    watch("Airbus A380", "AIRCRAFT TYPE", false)
                    watch("British Airways", "AIRLINE", false)
                    NavigationLink { SettingsView() } label: {
                        Label("Settings & Privacy", systemImage: "gearshape.fill").foregroundStyle(TallyTheme.bone).frame(maxWidth: .infinity, alignment: .leading).padding(16).background(TallyTheme.panel, in: RoundedRectangle(cornerRadius: 14))
                    }.padding(.top, 8)
                }.padding(20)
            }.background(TallyTheme.ink.ignoresSafeArea())
        }
    }

    private func metric(_ value: String, _ label: String) -> some View { VStack(alignment: .leading) { Text(value).font(.title2.monospacedDigit()).foregroundStyle(TallyTheme.bone); Text(label).microLabel() } }
    private func achievement(_ icon: String, _ title: String, _ detail: String) -> some View { HStack(spacing: 14) { Image(systemName: icon).foregroundStyle(TallyTheme.brass).frame(width: 40, height: 40).background(TallyTheme.elevated, in: Circle()); VStack(alignment: .leading) { Text(title).font(.headline).foregroundStyle(TallyTheme.bone); Text(detail).font(.caption).foregroundStyle(TallyTheme.muted) }; Spacer() }.padding(14).background(TallyTheme.panel, in: RoundedRectangle(cornerRadius: 14)) }
    private func watch(_ title: String, _ type: String, _ found: Bool) -> some View { HStack { Image(systemName: found ? "checkmark.seal.fill" : "scope").foregroundStyle(found ? TallyTheme.phosphor : TallyTheme.brass); VStack(alignment: .leading) { Text(title).foregroundStyle(TallyTheme.bone); Text(type).microLabel() }; Spacer(); Text(found ? "TALLIED" : "WATCHING").microLabel() }.padding(14).background(TallyTheme.panel, in: RoundedRectangle(cornerRadius: 14)) }
}

struct SettingsView: View {
    @EnvironmentObject private var store: TallyStore
    @AppStorage("tally.auto.special") private var autoSpecial = true
    @AppStorage("tally.auto.widebody") private var autoWidebody = true
    @AppStorage("tally.auto.rare") private var autoRare = true
    @AppStorage("tally.notifications") private var notifications = true
    @AppStorage("tally.appearance") private var appearance = "system"

    var body: some View {
        Form {
            Section("Automatic collection") {
                Toggle("Special liveries", isOn: $autoSpecial)
                Toggle("Widebody aircraft", isOn: $autoWidebody)
                Toggle("Rare or higher", isOn: $autoRare)
            }
            Section("Radar and privacy") {
                Toggle("Priority notifications", isOn: $notifications)
                if store.radarSession?.isActive == true { Button("End active radar session", role: .destructive) { store.stopRadarSession() } }
                Text("Public transmissions show airport or city context, never your exact collection location.").font(.caption).foregroundStyle(TallyTheme.muted)
            }
            Section("Environment") {
                Picker("Appearance", selection: $appearance) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                LabeledContent("Data mode", value: store.environment.isDemo ? "Demo" : "Live API")
                LabeledContent("Card renderer", value: "Native + C++")
                if store.isSignedIn { Button("Sign out", role: .destructive) { store.signOut() } }
            }
            Section("Aircraft credits") {
                Link(destination: URL(string: "https://www.cgtrader.com/designers/2001kraft")!) {
                    LabeledContent("Source aircraft models") {
                        HStack(spacing: 5) {
                            Text("2001kraft")
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                        }
                    }
                }
                Text("Aircraft source models are credited to 2001kraft except the Airbus A220-300. Tally liveries and collectible artwork are independently authored.")
                    .font(.caption)
                    .foregroundStyle(TallyTheme.muted)
            }
        }.navigationTitle("Settings").scrollContentBackground(.hidden).background(TallyTheme.ink)
    }
}
