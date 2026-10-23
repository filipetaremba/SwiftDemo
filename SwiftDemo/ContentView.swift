import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "iphone")
                .font(.system(size: 55))
                .foregroundStyle(.blue)

            Text("Minha primeira aplicação iOS")
                .font(.title2)
                .bold()

            Text("SwiftUI a funcionar!")
                .foregroundStyle(.secondary)

            Button("Começar") {
                print("Botão pressionado")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
