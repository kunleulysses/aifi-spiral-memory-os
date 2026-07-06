import SwiftUI

struct AppView: View {
    var body: some View {
        CreatureRoomView()
    }
}

#Preview {
    AppView()
        .environment(CreatureStore())
}
