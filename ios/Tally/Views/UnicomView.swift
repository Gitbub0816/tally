import SwiftUI

struct UnicomView: View {
    @EnvironmentObject private var store: TallyStore
    @State private var activeCard: Encounter?
    @State private var showingComposer = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ScreenHeader(eyebrow: "SOCIAL BAND · LIVE", title: "UNICOM", trailing: "ON FREQUENCY")
                    frequencySelector
                    ForEach(store.transmissions) { transmission in
                        TransmissionView(transmission: transmission)
                            .onTapGesture { activeCard = transmission.encounter }
                    }
                }.padding(20)
            }
            .background(TallyTheme.ink.ignoresSafeArea())
            .sheet(item: $activeCard) { CardDetailView(encounter: $0) }
            .overlay(alignment: .bottomTrailing) {
                Button { showingComposer = true } label: { Image(systemName: "wave.3.right.circle.fill").font(.system(size: 50)).foregroundStyle(TallyTheme.brass).shadow(radius: 12) }.padding(22)
            }
            .sheet(isPresented: $showingComposer) { TransmissionComposer() }
        }
    }

    private var frequencySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(store.frequencies) { frequency in
                    Button { store.selectedFrequency = frequency.channel } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack { Text(frequency.channel).font(.system(size: 18, weight: .medium, design: .monospaced)); if frequency.isPrivate { Image(systemName: "lock.fill").font(.caption) } }
                            Text(frequency.name.uppercased()).microLabel()
                            Text("\(frequency.memberCount.formatted()) ON FREQUENCY").font(.system(size: 8, design: .monospaced)).foregroundStyle(TallyTheme.muted)
                        }.foregroundStyle(TallyTheme.bone).frame(width: 190, alignment: .leading).padding(15).background(store.selectedFrequency == frequency.channel ? TallyTheme.elevated : TallyTheme.panel, in: RoundedRectangle(cornerRadius: 15)).overlay(RoundedRectangle(cornerRadius: 15).stroke(store.selectedFrequency == frequency.channel ? TallyTheme.brass : TallyTheme.olive.opacity(0.35)))
                    }
                }
            }
        }
    }
}

struct TransmissionComposer: View {
    @EnvironmentObject private var store: TallyStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEncounter: Encounter?
    @State private var message = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Frequency") { Text(store.selectedFrequency).font(.body.monospaced()) }
                Section("Attach a Tally") {
                    Picker("Aircraft", selection: $selectedEncounter) {
                        Text("Select").tag(nil as Encounter?)
                        ForEach(store.collected) { encounter in
                            Text("\(encounter.aircraft.registration) · \(encounter.aircraft.livery ?? encounter.aircraft.airline)").tag(encounter as Encounter?)
                        }
                    }
                }
                Section("Transmission") {
                    TextField("What did you find?", text: $message, axis: .vertical).lineLimit(3...7)
                    Text("\(message.count)/500").font(.caption.monospaced()).foregroundStyle(message.count > 500 ? TallyTheme.signal : TallyTheme.muted)
                }
            }
            .scrollContentBackground(.hidden).background(TallyTheme.ink)
            .navigationTitle("Transmit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        guard let selectedEncounter else { return }
                        Task { await store.transmit(encounter: selectedEncounter, message: message); dismiss() }
                    }.disabled(selectedEncounter == nil || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || message.count > 500 || store.isWorking)
                }
            }
        }
    }
}

struct TransmissionView: View {
    let transmission: Transmission
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Circle().fill(TallyTheme.olive).frame(width: 38, height: 38).overlay(Text(String(transmission.author.prefix(1))).font(.headline).foregroundStyle(TallyTheme.bone))
                VStack(alignment: .leading, spacing: 2) { Text(transmission.author).font(.subheadline.weight(.semibold)).foregroundStyle(TallyTheme.bone); Text("\(transmission.handle) · \(transmission.frequency)").microLabel() }
                Spacer(); Image(systemName: "ellipsis").foregroundStyle(TallyTheme.muted)
            }
            Text(transmission.message).font(.body).foregroundStyle(TallyTheme.bone)
            HStack(spacing: 14) {
                MiniCard(encounter: transmission.encounter).frame(width: 145)
                VStack(alignment: .leading, spacing: 9) {
                    Text(transmission.encounter.aircraft.livery ?? transmission.encounter.aircraft.airline).font(.headline).foregroundStyle(TallyTheme.bone)
                    Text(transmission.encounter.aircraft.displayModel).font(.caption).foregroundStyle(TallyTheme.muted)
                    Text(transmission.encounter.aircraft.registration).microLabel()
                    Text(transmission.encounter.route).font(.caption.monospaced()).foregroundStyle(TallyTheme.brass)
                }
            }
            HStack(spacing: 24) {
                Label("\(transmission.reactions)", systemImage: "diamond"); Label("\(transmission.comments)", systemImage: "bubble.left"); Spacer(); Label("TRANSMIT", systemImage: "wave.3.right")
            }.font(.caption).foregroundStyle(TallyTheme.muted)
        }.padding(16).background(TallyTheme.panel, in: RoundedRectangle(cornerRadius: 18))
    }
}
