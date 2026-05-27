import SwiftUI
import DepoUI

struct ContentView: View {
    @StateObject private var model = TimerModel()

    var body: some View {
        TimerView(model: model)
    }
}

#Preview {
    ContentView()
}
