import SwiftUI

struct RootView: View {
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            ContactsView()
                .tabItem { Label("Contacts", systemImage: "scope") }
                .tag(0)
            CollectionView()
                .tabItem { Label("Collection", systemImage: "rectangle.stack.fill") }
                .tag(1)
            UnicomView()
                .tabItem { Label("UNICOM", systemImage: "wave.3.right") }
                .tag(2)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(3)
        }
        .tint(TallyTheme.brass)
        .toolbarBackground(TallyTheme.ink, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

struct ScreenHeader: View {
    let eyebrow: String
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(eyebrow).microLabel()
                Text(title)
                    .font(.system(size: 30, weight: .medium, design: .rounded))
                    .foregroundStyle(TallyTheme.bone)
            }
            Spacer()
            if let trailing {
                Text(trailing).microLabel()
            }
        }
    }
}

