import SwiftUI

struct WordListView: View {
    @EnvironmentObject private var store: WordStore
    @State private var showingManualAdd = false
    @State private var showingPDFImporter = false
    @State private var showingWordsImporter = false
    @State private var showingImportOptions = false
    @State private var importMessage = ""
    @State private var exportFile: ExportFile?

    init() {
        UITableView.appearance().backgroundColor = .clear
    }

    var body: some View {
        ZStack {
            EmilyBackground()

            List {
                Section {
                    VStack(spacing: 12) {
                        Text("🦄 Kouzelná knihovna slovíček")
                            .font(.title3.bold())
                            .foregroundStyle(Color.emilyDeepBlue)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("Tady je schovaný import, export, ruční přidávání a úpravy překladů pro jazyk \(store.selectedLanguage.displayName).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            libraryActionButton(icon: "🪄", title: "Přidat ručně") {
                                showingManualAdd = true
                            }

                            libraryActionButton(icon: "📥", title: "Import") {
                                showingImportOptions = true
                            }

                            libraryActionButton(icon: "🎒", title: "Export") {
                                exportWords()
                            }

                            libraryActionButton(icon: "🌈", title: "\(store.selectedLanguageWords.count) slovíček") {
                            }
                            .disabled(true)
                        }

                        if !importMessage.isEmpty {
                            Text(importMessage)
                                .font(.caption)
                                .foregroundStyle(Color.emilyDeepBlue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Color.white.opacity(0.78))
                }

                Section(header: listHeader) {
                    ForEach($store.words) { $word in
                        if word.languageCode == store.selectedLanguage.rawValue {
                            HStack(alignment: .top, spacing: 10) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top) {
                                        Text(word.displayEnglish)
                                            .font(.subheadline.bold())
                                            .lineLimit(2)
                                            .minimumScaleFactor(0.75)
                                            .fixedSize(horizontal: false, vertical: true)

                                        Spacer(minLength: 8)

                                        Text("⭐️ \(word.mastery)/5")
                                            .font(.caption.bold())
                                            .lineLimit(1)
                                    }

                                    TextField("Český překlad", text: $word.czech)
                                        .textFieldStyle(.roundedBorder)

                                    Text("\(word.sourceTitle) · \(word.language.displayName)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Button {
                                    store.deleteWord(id: word.id)
                                } label: {
                                    Image(systemName: "trash.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .accessibilityLabel("Smazat slovíčko \(word.displayEnglish)")
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .onDelete { offsets in
                        store.deleteWords(at: offsets)
                    }
                }
            }
            .background(Color.clear)
        }
        .navigationTitle("Slovíčka")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingManualAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("Přidat slovíčko")
            }
        }
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

    private func libraryActionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Text(icon)
                    .font(.system(size: 34))

                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(Color.emilyDeepBlue)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, minHeight: 88)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.emilyBlue.opacity(0.25), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var listHeader: some View {
        HStack {
            Text("Slovíčka: \(store.selectedLanguage.displayName)")
            Spacer()
            Text("Smazat: přejeď vlevo nebo klepni na koš")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
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
