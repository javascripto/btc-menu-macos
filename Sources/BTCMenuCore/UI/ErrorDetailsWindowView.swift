import SwiftUI

struct ErrorDetailsWindowView: View {
    let details: ErrorDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(details.title)
                .font(.title3.weight(.semibold))

            Text(details.message)
                .textSelection(.enabled)

            Text("Horário: \(formattedTimestamp)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Resposta")
                .font(.headline)

            ScrollView {
                Text(details.formattedResponseBody)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(20)
        .frame(minWidth: 560, minHeight: 520, alignment: .topLeading)
    }

    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return formatter.string(from: details.timestamp)
    }
}
