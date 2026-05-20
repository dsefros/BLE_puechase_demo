import Foundation
import UserNotifications

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    private enum Identifier {
        static let candidateFound = "ru.pervyelement.bleapp.notification.candidateFound"
        static let paymentSuccess = "ru.pervyelement.bleapp.notification.paymentSuccess"
        static let paymentError = "ru.pervyelement.bleapp.notification.paymentError"
    }

    private let center: UNUserNotificationCenter
    private var hasRequestedAuthorization = false

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
        center.delegate = self
    }

    func prepareForRealScanStart() {
        Task { await requestAuthorizationIfNeeded() }
    }

    func notifyCandidateFound(amount: String, merchant: String) {
        post(
            identifier: Identifier.candidateFound,
            title: "Найден терминал Волна",
            body: "Сумма: \(amount), магазин: \(merchant)"
        )
    }

    func notifyPaymentSuccess(amount: String, merchant: String) {
        post(
            identifier: Identifier.paymentSuccess,
            title: "✅ Оплата успешна",
            body: "Списано \(amount) в магазине \(merchant)"
        )
    }

    func notifyPaymentError(amount: String, merchant: String, error: String) {
        post(
            identifier: Identifier.paymentError,
            title: "❌ Ошибка оплаты",
            body: "Не удалось списать \(amount) в магазине \(merchant): \(error)"
        )
    }

    private func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined, !hasRequestedAuthorization else { return }
        hasRequestedAuthorization = true
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    private func post(identifier: String, title: String, body: String) {
        Task {
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
            try? await center.add(request)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}
