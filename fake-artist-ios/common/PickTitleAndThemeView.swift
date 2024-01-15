import SwiftUI

struct PickTitleAndThemeView: View {
    @Binding var theme: String
    @Binding var title: String

    var body: some View {
        HStack {
            VStack {
                Text("What is the theme?")
                    .font(.caption)
                    .fontWeight(.bold)
                TextField("Animal", text: $theme)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            VStack {
                Text("What is the title?")
                    .font(.caption)
                    .fontWeight(.bold)
                TextField("Lion", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding()
    }
}
