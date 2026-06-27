import SwiftUI
import AVKit

struct PracticeView: View {
    @EnvironmentObject private var store: WordStore
    @StateObject private var speaker = SpeechSpeaker()
    @StateObject private var recognizer = SpeechRecognizer()

    @State private var deck: [WordItem] = []
    @State private var index = 0
    @State private var answer = ""
    @State private var spokenAnswer = ""
    @State private var feedback = ""
    @State private var stars = 0
    @State private var streak = 0
    @State private var unlockedFlowers = 0
    @State private var mode: PracticeMode = .hearAndType
    @State private var selectedMode: PracticeMode?
    @State private var autoAdvanceWorkItem: DispatchWorkItem?
    @State private var listeningTimeoutWorkItem: DispatchWorkItem?
    @State private var showRewardVideo = false
    @State private var rewardVideoOpacity = 0.0
    @State private var rewardPlayer: AVPlayer?
    @State private var rewardEndObserver: NSObjectProtocol?
    @FocusState private var answerFieldFocused: Bool

    enum PracticeMode: String, CaseIterable, Identifiable {
        case hearAndType = "Slyším a píšu"
        case czechToEnglish = "Česky → anglicky"
        case speakEnglish = "Řekni anglicky"
        var id: String { rawValue }

        func iconAssetName(for language: LearningLanguage) -> String {
            switch self {
            case .hearAndType:
                return "HearWriteIcon"
            case .czechToEnglish:
                return language == .spanish ? "TranslateSpanishIcon" : "TranslateEnglishIcon"
            case .speakEnglish:
                return language == .spanish ? "SpeakSpanishIcon" : "SpeakEnglishIcon"
            }
        }

        func displayTitle(for language: LearningLanguage) -> String {
            switch self {
            case .hearAndType:
                return "Slyším a píšu"
            case .czechToEnglish:
                return language == .spanish ? "Česky - Španělsky" : "Česky → anglicky"
            case .speakEnglish:
                return language == .spanish ? "Řekni to španělsky" : "Řekni anglicky"
            }
        }

        func selectorSubtitle(for language: LearningLanguage) -> String {
            switch self {
            case .hearAndType:
                return language == .spanish ? "Poslech a psaní španělských slovíček" : "Poslech a psaní anglických slovíček"
            case .czechToEnglish:
                return language == .spanish ? "Překlad z češtiny do španělštiny" : "Překlad z češtiny do angličtiny"
            case .speakEnglish:
                return language == .spanish ? "Řekni odpověď španělsky nahlas" : "Řekni odpověď anglicky nahlas"
            }
        }
    }

    var current: WordItem? {
        guard deck.indices.contains(index) else { return nil }
        return deck[index]
    }

    var body: some View {
        ZStack {
            EmilyBackground()
            modeWatermark

            ScrollView(showsIndicators: false) {
                VStack(spacing: selectedMode == nil ? 20 : 14) {
                    scoreHeader
                        .padding(.top, 6)

                    if selectedMode == nil {
                        modeSelectionView
                    } else if let word = current {
                        detailModeView(for: word)
                    } else {
                        detailEmptyStateView
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity, alignment: .top)
            }

            rewardVideoOverlay
        }
        .navigationTitle("Game")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                if let word = current, selectedMode != nil, mode != .speakEnglish {
                    Button("Zkontrolovat ✅") {
                        submitTypedAnswer(word)
                    }
                    .font(.headline)
                }

                if selectedMode != nil {
                    Button("Další ➡️") {
                        answerFieldFocused = false
                        nextQuestion()
                    }
                    .font(.headline)
                }
            }
        }
        .onAppear {
            refreshDeck()
            recognizer.requestAuthorization()
            resetQuestion()
        }
        .onDisappear {
            cancelAutoAdvance()
            cancelListeningTimeout()
            recognizer.stop()
            stopRewardVideo()
            answerFieldFocused = false
        }
        .onChange(of: store.selectedLanguage) { _ in
            leavePracticeMode()
            refreshDeck()
            resetQuestion()
        }
    }

    private var rewardVideoOverlay: some View {
        Group {
            if showRewardVideo, let rewardPlayer {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()

                    VStack(spacing: 14) {
                        VideoPlayer(player: rewardPlayer)
                            .frame(maxWidth: 720, maxHeight: 420)
                            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .stroke(Color.emilyYellow, lineWidth: 4)
                            )
                            .shadow(color: Color.black.opacity(0.32), radius: 18, x: 0, y: 8)

                        Text("Kytička pro jednorožce! 🌸")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .padding()
                }
                .opacity(rewardVideoOpacity)
                .transition(.opacity)
                .zIndex(200)
                .allowsHitTesting(false)
            }
        }
    }

    private var modeWatermark: some View {
        Group {
            if let selectedMode {
                Image(selectedMode.iconAssetName(for: store.selectedLanguage))
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 680)
                    .opacity(0.08)
                    .rotationEffect(.degrees(-8))
                    .offset(y: 120)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }

    private var modeSelectionView: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Text("Vyber herní režim")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.emilyDeepBlue)

                Text("Vrchní ikonky jsou hlavní rozcestník. Po klepnutí se otevře celý režim přes celou stránku.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 620)
            }

            VStack(spacing: 14) {
                ForEach(PracticeMode.allCases) { practiceMode in
                    selectorButton(for: practiceMode)
                }
            }
            .frame(maxWidth: 760)
        }
    }

    private func selectorButton(for practiceMode: PracticeMode) -> some View {
        Button {
            enterPracticeMode(practiceMode)
        } label: {
            HStack(spacing: 18) {
                Image(practiceMode.iconAssetName(for: store.selectedLanguage))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 92, height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: Color.emilyDeepBlue.opacity(0.18), radius: 8, x: 0, y: 5)

                VStack(alignment: .leading, spacing: 6) {
                    Text(practiceMode.displayTitle(for: store.selectedLanguage))
                        .font(.title3.bold())
                        .foregroundStyle(Color.emilyDeepBlue)
                        .multilineTextAlignment(.leading)

                    Text(practiceMode.selectorSubtitle(for: store.selectedLanguage))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.emilyDeepBlue)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.emilyBlue.opacity(0.42), lineWidth: 2)
            )
            .shadow(color: Color.emilyDeepBlue.opacity(0.12), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(practiceMode.displayTitle(for: store.selectedLanguage))
    }

    private func detailModeView(for word: WordItem) -> some View {
        VStack(spacing: 14) {
            HStack {
                Button {
                    leavePracticeMode()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("Zpět na výběr režimů")
                    }
                    .font(.headline.bold())
                    .foregroundStyle(Color.emilyDeepBlue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.94))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.emilyBlue.opacity(0.35), lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .frame(maxWidth: 760)

            HStack(spacing: 12) {
                Image(mode.iconAssetName(for: store.selectedLanguage))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color.emilyDeepBlue.opacity(0.12), radius: 6, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayTitle(for: store.selectedLanguage))
                        .font(.title2.bold())
                        .foregroundStyle(Color.emilyDeepBlue)
                    Text("Teď je otevřený celý režim. Po návratu si můžeš vybrat jinou ikonku.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(14)
            .frame(maxWidth: 760)
            .background(Color.white.opacity(0.90))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.emilyBlue.opacity(0.30), lineWidth: 2)
            )

            practiceCard(for: word)
        }
    }

    private var detailEmptyStateView: some View {
        VStack(spacing: 14) {
            HStack {
                Button {
                    leavePracticeMode()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("Zpět na výběr režimů")
                    }
                    .font(.headline.bold())
                    .foregroundStyle(Color.emilyDeepBlue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.94))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.emilyBlue.opacity(0.35), lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .frame(maxWidth: 760)

            emptyStateView
        }
    }

    private var scoreHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("🌸 \(unlockedFlowers)")
                    .font(.title2.bold())
                    .accessibilityLabel("Kytičky \(unlockedFlowers)")

                HStack(spacing: 8) {
                    Text("⭐️")
                        .font(.title2)
                    Text("\(stars)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.emilyYellow, lineWidth: 3)
                )
                .shadow(color: Color.emilyDeepBlue.opacity(0.12), radius: 6, x: 0, y: 4)
                .accessibilityLabel("Hvězdičky \(stars)")

                Text("\(store.selectedLanguage.displayName) · Combo \(streak)/10")
                    .font(.headline)
                    .foregroundStyle(Color.emilyDeepBlue)
            }

            Spacer()

            Text("🦄")
                .font(.largeTitle)
        }
        .frame(maxWidth: 760)
    }

    private func practiceCard(for word: WordItem) -> some View {
        VStack(spacing: 10) {
            prompt(for: word)

            switch mode {
            case .speakEnglish:
                speakEnglishControls(for: word)

            case .hearAndType:
                typedAnswerField(for: word)

                HStack(spacing: 12) {
                    gameActionButton(title: "Přehrát", icon: "🔊") {
                        playCurrentEnglishWordAndFocusKeyboard(word)
                    }

                    gameActionButton(title: "Zkontrolovat") {
                        submitTypedAnswer(word)
                    }
                }
                .padding(.horizontal)

            case .czechToEnglish:
                typedAnswerField(for: word)

                gameActionButton(title: "Zkontrolovat") {
                    submitTypedAnswer(word)
                }
            }

            Text(feedback)
                .font(.title3.bold())
                .foregroundStyle(Color.emilyDeepBlue)
                .multilineTextAlignment(.center)
                .frame(minHeight: 28)

            if mode == .speakEnglish {
                Button("Další slovíčko") {
                    nextQuestion()
                }
                .buttonStyle(EmilyButtonStyle())
            }
        }
        .padding(14)
        .frame(maxWidth: 760)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.96), Color.emilyYellow.opacity(0.34)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.emilyDeepBlue.opacity(0.22), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Color.emilyDeepBlue.opacity(0.18), radius: 10, x: 0, y: 6)
    }

    private func enterPracticeMode(_ practiceMode: PracticeMode) {
        mode = practiceMode
        selectedMode = practiceMode
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        cancelAutoAdvance()
        cancelListeningTimeout()
        recognizer.stop()
        recognizer.transcript = ""
        answerFieldFocused = false
        index = 0
        refreshDeck()
        resetQuestion()
    }

    private func leavePracticeMode() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        cancelAutoAdvance()
        cancelListeningTimeout()
        recognizer.stop()
        recognizer.transcript = ""
        answerFieldFocused = false
        feedback = ""
        answer = ""
        spokenAnswer = ""
        selectedMode = nil
    }

    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 52))
                .foregroundStyle(Color.emilyDeepBlue)
            Text(emptyTitle)
                .font(.title2.bold())
            Text(emptyDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: 620)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.98), Color.emilyYellow.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.emilyDeepBlue.opacity(0.22), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var emptyTitle: String {
        mode == .hearAndType ? "Nejdřív nahraj slovíčka" : "Nejdřív doplň překlady"
    }

    private var emptyDescription: String {
        mode == .hearAndType
            ? "Importuj PDF nebo přidej slovíčka ručně pro vybraný jazyk. Tento režim umí pracovat i bez českého překladu."
            : "Pro český režim a mluvení potřebuju slovíčka s českým překladem."
    }

    @ViewBuilder
    private func prompt(for word: WordItem) -> some View {
        switch mode {
        case .hearAndType:
            VStack(spacing: 8) {
                Text(store.selectedLanguage.hearAndTypePrompt)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("Klepni na Přehrát a potom napiš odpověď.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

        case .czechToEnglish:
            VStack(spacing: 12) {
                Text(store.selectedLanguage.targetPrompt)
                    .font(.title2)
                promptWordText(word.displayCzech)
                Button("🔊 Přečíst česky") {
                    speaker.speakCzech(word.displayCzech)
                }
                .buttonStyle(EmilyButtonStyle())
            }

        case .speakEnglish:
            VStack(spacing: 6) {
                Text(store.selectedLanguage.speakPrompt)
                    .font(.title2)
                promptWordText(word.displayCzech)
                Button("🔊 Přečíst česky") {
                    playCzechThenStartListening(word)
                }
                .buttonStyle(EmilyButtonStyle())
            }
        }
    }

    private func gameActionButton(title: String, icon: String = "", action: @escaping () -> Void) -> some View {
        let label = icon.isEmpty ? title : "\(icon) \(title)"

        return Text(label)
            .font(.title3.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(Color.emilyDeepBlue)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.emilyDeepBlue.opacity(0.22), radius: 5, x: 0, y: 3)
            .contentShape(Rectangle())
            .highPriorityGesture(
                TapGesture().onEnded {
                    action()
                }
            )
            .onTapGesture {
                action()
            }
            .accessibilityLabel(label)
    }

    private func typedAnswerField(for word: WordItem) -> some View {
        TextField("Napiš odpověď", text: $answer)
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .focused($answerFieldFocused)
            .submitLabel(.done)
            .onSubmit {
                submitTypedAnswer(word)
            }
            .padding(12)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(.horizontal)
    }

    private func speakEnglishControls(for word: WordItem) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image("ListeningUnicorn")
                    .resizable()
                    .scaledToFit()
                    .frame(width: recognizer.isRecording ? 132 : 104, height: recognizer.isRecording ? 92 : 74)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(recognizer.isRecording ? Color.emilyYellow : Color.emilyDeepBlue.opacity(0.22), lineWidth: recognizer.isRecording ? 3 : 1.5)
                    )
                    .shadow(color: recognizer.isRecording ? Color.emilyDeepBlue.opacity(0.24) : Color.clear, radius: 8, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(recognizer.isRecording ? "Jednorožec poslouchá…" : "Jednorožec je připravený poslouchat")
                        .font(.headline.bold())
                        .foregroundStyle(Color.emilyDeepBlue)

                    Text(recognizer.isRecording ? "Naslouchání se samo vypne nejpozději za 20 sekund." : "Klepni na „Přečíst česky“. Po přečtení se naslouchání spustí automaticky.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal)

            HStack(spacing: 10) {
                TextField("Rozpoznaná odpověď", text: $spokenAnswer)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($answerFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        finishSpokenAnswer(word)
                    }
                    .onChange(of: recognizer.transcript) { newTranscript in
                        guard mode == .speakEnglish else { return }
                        guard !answerFieldFocused else { return }
                        spokenAnswer = newTranscript
                    }

                Button {
                    cancelListeningTimeout()
                    recognizer.stop()
                    answerFieldFocused = true
                } label: {
                    Image(systemName: "keyboard")
                        .font(.title2.bold())
                        .foregroundStyle(Color.emilyDeepBlue)
                        .padding(10)
                        .background(Color.emilyBlue.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Otevřít klávesnici pro opravu odpovědi")
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.emilyDeepBlue.opacity(0.12), lineWidth: 1.5)
            )

            HStack(spacing: 12) {
                Button(recognizer.isRecording ? "Ukončit a zkontrolovat" : "Zkontrolovat") {
                    answerFieldFocused = false
                    finishSpokenAnswer(word)
                }
                .buttonStyle(EmilyButtonStyle())

                Button("Vymazat") {
                    clearSpokenAnswer()
                }
                .buttonStyle(EmilyButtonStyle())
            }
        }
    }

    private func promptWordText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 34, weight: .heavy, design: .rounded))
            .foregroundStyle(Color.emilyDeepBlue)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.72)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8)
    }

    private func playCurrentEnglishWordAndFocusKeyboard(_ word: WordItem) {
        answerFieldFocused = false
        speaker.speak(word.english, language: store.selectedLanguage) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                guard current?.id == word.id && mode == .hearAndType else { return }
                answerFieldFocused = true
            }
        }
    }

    private func clearSpokenAnswer() {
        cancelListeningTimeout()
        recognizer.stop()
        recognizer.transcript = ""
        spokenAnswer = ""
        feedback = ""
        answerFieldFocused = false
    }

    private func playCzechThenStartListening(_ word: WordItem) {
        cancelListeningTimeout()
        recognizer.stop()
        recognizer.transcript = ""
        spokenAnswer = ""
        answerFieldFocused = false
        feedback = "Připrav se…"

        speaker.speakCzech(word.displayCzech) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                guard current?.id == word.id && mode == .speakEnglish else { return }
                startTimedListening(for: word)
            }
        }
    }

    private func startTimedListening(for word: WordItem) {
        cancelListeningTimeout()
        feedback = "Jednorožec poslouchá…"
        recognizer.start(language: store.selectedLanguage)

        let workItem = DispatchWorkItem {
            guard current?.id == word.id && mode == .speakEnglish else { return }
            recognizer.stop()
            feedback = spokenAnswer.isEmpty ? "Naslouchání skončilo. Můžeš odpověď napsat klávesnicí." : "Naslouchání skončilo. Zkontroluj odpověď."
        }

        listeningTimeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: workItem)
    }

    private func cancelListeningTimeout() {
        listeningTimeoutWorkItem?.cancel()
        listeningTimeoutWorkItem = nil
    }

    private func submitTypedAnswer(_ word: WordItem) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        answerFieldFocused = false
        feedback = "Kontroluji..."
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            checkTyped(word)
        }
    }

    private func checkTyped(_ word: WordItem) {
        let ok = normalize(answer) == normalize(word.english)
        finishCheck(word, ok: ok)
    }

    private func checkSpoken(_ word: WordItem) {
        let spoken = normalize(spokenAnswer)
        let target = normalize(word.english)
        let ok = spoken == target || spoken.contains(target)
        finishCheck(word, ok: ok)
    }

    private func finishSpokenAnswer(_ word: WordItem) {
        cancelListeningTimeout()
        if recognizer.isRecording {
            recognizer.stop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                checkSpoken(word)
            }
        } else {
            checkSpoken(word)
        }
    }

    private func finishCheck(_ word: WordItem, ok: Bool) {
        cancelAutoAdvance()
        store.recordAnswer(for: word.id, correct: ok)

        if ok {
            stars += 1
            streak += 1

            if streak >= 10 {
                unlockedFlowers += 1
                streak = 0
                feedback = store.selectedLanguage.greatJobText
                speaker.speak(store.selectedLanguage.greatJobSpeech, language: store.selectedLanguage)
                playRewardVideo()
            } else {
                feedback = store.selectedLanguage.goodJobText
                speaker.speak(store.selectedLanguage.goodJobSpeech, language: store.selectedLanguage)
            }

            scheduleAutoAdvance(after: 1.8)
        } else {
            streak = 0
            feedback = "\(store.selectedLanguage.almostTextPrefix) \(word.displayEnglish)"
            speaker.speak(word.english, language: store.selectedLanguage)
        }
    }

    private func playRewardVideo() {
        guard let url = Bundle.main.url(forResource: "jednorozec_raduje_se_z_uspechu", withExtension: "mp4") else {
            return
        }

        stopRewardVideo()

        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)

        rewardPlayer = player
        showRewardVideo = true
        rewardVideoOpacity = 0

        rewardEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            fadeOutRewardVideo()
        }

        withAnimation(.easeIn(duration: 0.55)) {
            rewardVideoOpacity = 1
        }

        player.seek(to: .zero)
        player.play()

        // Safety fallback: kdyby systém neposlal notifikaci o konci videa,
        // overlay se stejně sám uklidí.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.50) {
            if showRewardVideo {
                fadeOutRewardVideo()
            }
        }
    }

    private func fadeOutRewardVideo() {
        withAnimation(.easeOut(duration: 0.7)) {
            rewardVideoOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            stopRewardVideo()
        }
    }

    private func stopRewardVideo() {
        rewardPlayer?.pause()
        rewardPlayer = nil
        showRewardVideo = false
        rewardVideoOpacity = 0

        if let rewardEndObserver {
            NotificationCenter.default.removeObserver(rewardEndObserver)
            self.rewardEndObserver = nil
        }
    }

    private func scheduleAutoAdvance(after delay: TimeInterval) {
        let workItem = DispatchWorkItem {
            nextQuestion()
        }
        autoAdvanceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func cancelAutoAdvance() {
        autoAdvanceWorkItem?.cancel()
        autoAdvanceWorkItem = nil
    }

    private func nextQuestion() {
        cancelAutoAdvance()
        cancelListeningTimeout()

        if index + 1 < deck.count {
            index += 1
        } else {
            refreshDeck()
            index = 0
        }

        resetQuestion()
        prepareCurrentQuestion(after: 0.35)
    }

    private func refreshDeck() {
        deck = store.practiceDeck(includeUntranslated: mode == .hearAndType)
        if index >= deck.count {
            index = 0
        }
    }

    private func resetQuestion() {
        answer = ""
        spokenAnswer = ""
        feedback = ""
        recognizer.stop()
        recognizer.transcript = ""
        answerFieldFocused = false
    }

    private func prepareCurrentQuestion(after delay: TimeInterval = 0.35) {
        // Záměrně bez automatického spuštění. Dítě si samo klepne na akci podle zvoleného režimu.
    }

    private func normalize(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "cs_CZ"))
            .lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
