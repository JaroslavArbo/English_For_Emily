import SwiftUI

struct ManualWordView: View {
    @EnvironmentObject private var store: WordStore
    @Environment(\.dismiss) private var dismiss

    @State private var english = ""
    @State private var czech = ""
    @State private var message = ""

    var body: some View {
        NavigationView {
            ZStack {
                EmilyBackground()

                VStack(spacing: 22) {
                    Text("🦄")
                        .font(.system(size: 72))

                    Text("Nové slovíčko")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.emilyDeepBlue)

                    Text("Aktuální jazyk: \(store.selectedLanguage.displayName)")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 14) {
                        Text(store.selectedLanguage.targetLabel)
                            .font(.headline)
                        TextField("např. \(store.selectedLanguage.exampleWord)", text: $english)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.title2.bold())
                            .textFieldStyle(.roundedBorder)

                        Text("Česky")
                            .font(.headline)
                        TextField("např. motýl", text: $czech)
                            .font(.title2)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                    .background(.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(.horizontal)

                    if !message.isEmpty {
                        Text(message)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 14) {
                        Button("Přidat a zavřít") {
                            addWord(closeAfterAdd: true)
                        }
                        .buttonStyle(EmilyButtonStyle())

                        Button("Přidat další") {
                            addWord(closeAfterAdd: false)
                        }
                        .buttonStyle(EmilyButtonStyle())
                    }

                    Spacer()
                }
                .padding(.top, 28)
            }
            .navigationTitle("Ručně přidat")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Zavřít") { dismiss() }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func addWord(closeAfterAdd: Bool) {
        let trimmedTarget = english.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTarget.isEmpty else {
            message = "Nejdřív napiš slovíčko v jazyce \(store.selectedLanguage.displayName)."
            return
        }

        store.addManualWord(english: english, czech: czech)
        message = "Přidáno: \(WordStore.cleanEnglish(trimmedTarget))"
        english = ""
        czech = ""

        if closeAfterAdd {
            dismiss()
        }
    }
}
