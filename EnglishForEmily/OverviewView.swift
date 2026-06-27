import SwiftUI

struct OverviewView: View {
    @EnvironmentObject private var store: WordStore

    private var stats: [DailyPracticeStat] {
        Array(store.recentDailyStats(days: 14))
    }

    private var maxTested: Int {
        max(stats.map { $0.testedCount }.max() ?? 1, 1)
    }

    private var maxStars: Int {
        max(stats.map { $0.starsEarned }.max() ?? 1, 1)
    }

    var body: some View {
        ZStack {
            EmilyBackground()

            ScrollView {
                VStack(spacing: 22) {
                    Text("Přehled")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.emilyDeepBlue)

                    summaryCards

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Posledních 14 dní")
                            .font(.title2.bold())
                            .foregroundStyle(Color.emilyDeepBlue)

                        if stats.isEmpty {
                            Text("Zatím tu nejsou žádné testy. Až Emilka začne trénovat, objeví se tady graf.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(stats) { stat in
                                dayRow(stat)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: 760)
                    .background(.white.opacity(0.86))
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(radius: 5)
                }
                .padding()
            }
        }
        .navigationTitle("Přehled")
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            statCard(title: "Dnes testováno", value: "\(store.todayStat.testedCount)", icon: "📝")
            statCard(title: "Dnes hvězdiček", value: "\(store.todayStat.starsEarned)", icon: "⭐️")
        }
        .frame(maxWidth: 760)
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.largeTitle)
            Text(value)
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.emilyDeepBlue)
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(radius: 4)
    }

    private func dayRow(_ stat: DailyPracticeStat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(shortDate(stat.dayKey))
                    .font(.headline)
                Spacer()
                Text("\(stat.testedCount) slovíček · ⭐️ \(stat.starsEarned)")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.emilyDeepBlue)
            }

            VStack(spacing: 6) {
                barRow(
                    label: "Testy",
                    value: stat.testedCount,
                    maxValue: maxTested,
                    icon: "📝"
                )

                barRow(
                    label: "Hvězdy",
                    value: stat.starsEarned,
                    maxValue: maxStars,
                    icon: "⭐️"
                )
            }
        }
        .padding(.vertical, 6)
    }

    private func barRow(label: String, value: Int, maxValue: Int, icon: String) -> some View {
        HStack(spacing: 10) {
            Text(icon)
                .frame(width: 28)

            Text(label)
                .font(.caption.bold())
                .frame(width: 52, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.emilyBlue.opacity(0.45))

                    Capsule()
                        .fill(Color.emilyDeepBlue.opacity(0.85))
                        .frame(width: barWidth(value: value, maxValue: maxValue, totalWidth: geometry.size.width))
                }
            }
            .frame(height: 14)

            Text("\(value)")
                .font(.caption.bold())
                .frame(width: 32, alignment: .trailing)
        }
    }

    private func barWidth(value: Int, maxValue: Int, totalWidth: CGFloat) -> CGFloat {
        guard maxValue > 0 else { return 0 }
        let ratio = CGFloat(value) / CGFloat(maxValue)
        return max(0, totalWidth * ratio)
    }

    private func shortDate(_ key: String) -> String {
        let input = DateFormatter()
        input.calendar = Calendar(identifier: .gregorian)
        input.locale = Locale(identifier: "en_US_POSIX")
        input.dateFormat = "yyyy-MM-dd"

        guard let date = input.date(from: key) else { return key }

        let output = DateFormatter()
        output.locale = Locale(identifier: "cs_CZ")
        output.dateFormat = "E d. M."
        return output.string(from: date)
    }
}
