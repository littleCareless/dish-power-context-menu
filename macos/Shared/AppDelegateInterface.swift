import Foundation

@MainActor
protocol AppDelegateInterface {
  func showUserAlert(title: String, message: String)
}
