import SwiftUI

extension View {
    /// Presents a `SingleButtonAlert` driven by an optional source, clearing it on
    /// dismiss. Shows the standard OK button plus an optional "Try again" action,
    /// matching the app's single-button error alert.
    func singleButtonAlert(_ alert: Binding<SingleButtonAlert?>) -> some View {
        let isPresented = Binding(
            get: { alert.wrappedValue != nil },
            set: { if !$0 { alert.wrappedValue = nil } }
        )
        return self.alert(
            alert.wrappedValue?.title ?? "",
            isPresented: isPresented,
            presenting: alert.wrappedValue
        ) { current in
            if let handler = current.action.tryAgainHandler {
                Button(current.action.tryAgainButtonTitle) { handler() }
            }
            Button(current.action.buttonTitle, role: .cancel) { alert.wrappedValue = nil }
        } message: { current in
            Text(current.message ?? "")
        }
    }
}
