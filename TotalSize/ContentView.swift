import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Welcome to Total Size")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
}
