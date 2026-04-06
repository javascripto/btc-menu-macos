import Foundation

struct ErrorDetails {
    let title: String
    let message: String
    let responseBody: String?
    let timestamp: Date

    var formattedResponseBody: String {
        guard let responseBody, !responseBody.isEmpty else {
            return "Nenhum corpo de resposta disponível."
        }

        guard
            let data = responseBody.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data),
            let formatted = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
            let prettyString = String(data: formatted, encoding: .utf8)
        else {
            return responseBody
        }

        return prettyString
    }
}
