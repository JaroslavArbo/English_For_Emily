import SwiftUI
import UniformTypeIdentifiers

struct RootView: View {
    @EnvironmentObject private var store: WordStore
    @State private var showingPDFImporter = false
    @State private var showingWordsImporter = false
    @State private var showingManualAdd = false
    @State private var showingImportOptions = false
    @State private var importMessage = ""
    @State private var exportFile: ExportFile?

    var body: some View {
        NavigationView {
            ZStack {
                EmilyBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        UnicornBadge()
                            .padding(.top, 12)

                        Text("English for Emily")
                            .font(.system(size: 44, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.emilyDeepBlue)

                        languagePickerCard

                        HStack(spacing: 16) {
                            NavigationLink {
                                PracticeView()
                            } label: {
                                homeActionCard(
                                    assetName: "HomeStartGameIcon",
                                    title: "Start Game",
                                    subtitle: "Jednorožec vyráží lovit slovíčka"
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                OverviewView()
                            } label: {
                                homeActionCard(
                                    assetName: "HomeOverviewIcon",
                                    title: "Přehled",
                                    subtitle: "Jednorožec hlídá pokrok"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: 620)

                        NavigationLink {
                            WordListView()
                        } label: {
                            HStack(spacing: 10) {
                                Text("📚")
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Slovíčka a překlady")
                                        .font(.headline.bold())
                                    Text("Import, export a ruční úpravy jsou schované tady")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: 620)
                            .background(.white.opacity(0.82))
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .actionSheet(isPresented: $showingImportOptions) {
                ActionSheet(
                    title: Text("Import slovíček"),
                    message: Text("Vyber, odkud chceš slovíčka načíst do jazyka \(store.selectedLanguage.displayName)."),
                    buttons: [
                        .default(Text("Importovat z PDF")) {
                            showingPDFImporter = true
                        },
                        .default(Text("Importovat ze zálohy JSON")) {
                            showingWordsImporter = true
                        },
                        .cancel(Text("Zrušit"))
                    ]
                )
            }
            .sheet(isPresented: $showingManualAdd) {
                ManualWordView()
                    .environmentObject(store)
            }
            .sheet(item: $exportFile) { file in
                ActivityView(activityItems: [file.url])
            }
            .fileImporter(isPresented: $showingPDFImporter, allowedContentTypes: [.pdf], allowsMultipleSelection: false) { result in
                handlePDFImport(result)
            }
            .fileImporter(isPresented: $showingWordsImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
                handleWordsImport(result)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            ReminderManager.shared.requestAuthorizationAndSchedule(using: store)
        }
    }

    private func homeActionCard(assetName: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                .shadow(color: Color.emilyDeepBlue.opacity(0.18), radius: 10, x: 0, y: 6)

            Text(title)
                .font(.title3.bold())
                .foregroundStyle(Color.emilyDeepBlue)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 250)
        .padding()
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.emilyBlue.opacity(0.25), lineWidth: 2)
        )
        .shadow(color: Color.emilyDeepBlue.opacity(0.12), radius: 10, x: 0, y: 6)
    }

    private var languagePickerCard: some View {
        VStack(spacing: 16) {
            Text("Vyber jazyk procvičování")
                .font(.headline)
                .foregroundStyle(Color.emilyDeepBlue)

            HStack(spacing: 16) {
                languageSelectionButton(.english)
                languageSelectionButton(.spanish)
            }
            .frame(maxWidth: 760)

            Text("Vybraný jazyk se pamatuje z posledního spuštění. Nově importovaná i ručně přidaná slovíčka se uloží do právě zvoleného jazyka.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: 760)
        .background(.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.emilyBlue.opacity(0.28), lineWidth: 2)
        )
    }

    private func languageSelectionButton(_ language: LearningLanguage) -> some View {
        let isSelected = store.selectedLanguage == language
        let count = store.words.filter { $0.languageCode == language.rawValue }.count

        return VStack(spacing: 12) {
            Image(language.homeSelectionIconAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(color: Color.emilyDeepBlue.opacity(isSelected ? 0.24 : 0.12), radius: 10, x: 0, y: 6)

            Text(language.displayName)
                .font(.title3.bold())
                .foregroundStyle(isSelected ? Color.emilyDeepBlue : Color.primary)

            Text("\(count) slovíček")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(isSelected ? "Aktivní jazyk" : "Vybrat")
                .font(.caption.bold())
                .foregroundStyle(isSelected ? Color.white : Color.emilyDeepBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.emilyDeepBlue : Color.emilyBlue.opacity(0.22))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.white.opacity(0.98) : Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isSelected ? Color.emilyYellow : Color.emilyBlue.opacity(0.32), lineWidth: isSelected ? 4 : 2)
        )
        .shadow(color: isSelected ? Color.emilyDeepBlue.opacity(0.16) : Color.clear, radius: 8, x: 0, y: 5)
        .contentShape(Rectangle())
        .highPriorityGesture(
            TapGesture().onEnded {
                selectLanguage(language)
            }
        )
        .onTapGesture {
            selectLanguage(language)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Vybrat jazyk \(language.displayName)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func selectLanguage(_ language: LearningLanguage) {
        store.selectedLanguage = language
    }

    private func handlePDFImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                importMessage = "Import se nepovedl: soubor nebyl vybrán."
                return
            }

            let title = url.deletingPathExtension().lastPathComponent
            let allowed = url.startAccessingSecurityScopedResource()
            defer {
                if allowed {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let localURL = try makeLocalCopyOfImportedPDF(from: url, title: title)
                let words = PDFWordExtractor.extractWords(from: localURL)

                store.addImportedWords(words, sourceTitle: title)

                if words.isEmpty {
                    importMessage = "PDF se otevřelo, ale nenašla jsem v něm žádná slovíčka. Pokud je PDF jen obrázek/sken, tahle verze ho neumí přečíst."
                } else {
                    importMessage = "Našla jsem \(words.count) slovíček pro jazyk \(store.selectedLanguage.displayName). Teď doplň české překlady."
                }
            } catch {
                importMessage = "Import se nepovedl: \(error.localizedDescription)"
            }

        case .failure(let error):
            importMessage = "Import se nepovedl: \(error.localizedDescription)"
        }
    }

    private func handleWordsImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                importMessage = "Import slovíček se nepovedl: soubor nebyl vybrán."
                return
            }

            let allowed = url.startAccessingSecurityScopedResource()
            defer {
                if allowed {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let data = try Data(contentsOf: url)
                let changed = try store.importBackupData(data)
                importMessage = "Import slovíček hotov: přidáno nebo doplněno \(changed) položek."
            } catch {
                importMessage = "Import slovíček se nepovedl: \(error.localizedDescription)"
            }

        case .failure(let error):
            importMessage = "Import slovíček se nepovedl: \(error.localizedDescription)"
        }
    }

    private func exportWords() {
        guard !store.words.isEmpty else {
            importMessage = "Zatím není co exportovat — seznam slovíček je prázdný."
            return
        }

        do {
            let data = try store.exportBackupData()
            let url = try makeExportFile(data: data)
            importMessage = "Export připraven: \(store.words.count) slovíček."
            exportFile = ExportFile(url: url)
        } catch {
            importMessage = "Export se nepovedl: \(error.localizedDescription)"
        }
    }

    private func makeExportFile(data: Data) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        let stamp = formatter.string(from: Date())

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("EnglishForEmily-Words-\(stamp).json")

        try data.write(to: url, options: [.atomic])
        return url
    }

    private func makeLocalCopyOfImportedPDF(from sourceURL: URL, title: String) throws -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folder = docs.appendingPathComponent("ImportedPDFs", isDirectory: true)

        if !FileManager.default.fileExists(atPath: folder.path) {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }

        let safeTitle = title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let destinationURL = folder.appendingPathComponent("\(safeTitle.isEmpty ? "ImportedPDF" : safeTitle)-\(UUID().uuidString).pdf")

        let data = try Data(contentsOf: sourceURL)
        try data.write(to: destinationURL, options: [.atomic])
        return destinationURL
    }
}

struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}
