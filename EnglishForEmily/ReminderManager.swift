import Foundation
import UserNotifications

final class ReminderManager {
    static let shared = ReminderManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let reminderPrefix = "english-for-emily-practice-reminder-"

    private init() {}

    func requestAuthorizationAndSchedule(using store: WordStore) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            if let error = error {
                print("Notification authorization error:", error.localizedDescription)
            }

            guard granted else { return }

            DispatchQueue.main.async {
                self?.scheduleUpcomingReminders(using: store)
            }
        }
    }

    func scheduleUpcomingReminders(using store: WordStore, numberOfDays: Int = 30) {
        removeDeliveredPracticeReminders()

        let calendar = Calendar.current
        let today = Date()

        for offset in 0..<numberOfDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let key = Self.dayKey(for: date)

            // If testing already happened that day, do not schedule a reminder for that day.
            if store.hasTesting(onDayKey: key) {
                cancelReminder(forDayKey: key)
                continue
            }

            guard let fireDate = calendar.date(
                bySettingHour: 18,
                minute: 0,
                second: 0,
                of: date
            ) else { continue }

            // Do not schedule today's notification after 18:00.
            if fireDate <= Date() {
                continue
            }

            scheduleReminder(for: fireDate, dayKey: key)
        }
    }

    func cancelReminder(for date: Date) {
        cancelReminder(forDayKey: Self.dayKey(for: date))
    }

    private func scheduleReminder(for date: Date, dayKey: String) {
        let content = UNMutableNotificationContent()
        content.title = "English for Emily"
        content.body = "Co takhle testovat slovíčka?"
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: reminderPrefix + dayKey,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Reminder scheduling error:", error.localizedDescription)
            }
        }
    }

    private func cancelReminder(forDayKey dayKey: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminderPrefix + dayKey])
    }

    private func removeDeliveredPracticeReminders() {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [])
    }

    static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
