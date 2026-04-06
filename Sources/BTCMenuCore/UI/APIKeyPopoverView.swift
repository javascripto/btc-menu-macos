import SwiftUI

struct APIKeyPopoverView: View {
    @State private var sourcePreference: PriceSourcePreference
    @State private var apiKey: String

    let onSave: (PriceSourcePreference, String) -> Void
    let onCancel: () -> Void

    init(
        initialSourcePreference: PriceSourcePreference,
        initialAPIKey: String,
        onSave: @escaping (PriceSourcePreference, String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _sourcePreference = State(initialValue: initialSourcePreference)
        _apiKey = State(initialValue: initialAPIKey)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("API Key da CoinMarketCap")
                .font(.headline)

            Text("Opcional: sem chave o app usa a API publica. Com chave, usa a CoinMarketCap.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Picker("Fonte", selection: $sourcePreference) {
                ForEach(PriceSourcePreference.allCases, id: \.self) { preference in
                    Text(preference.title).tag(preference)
                }
            }
            .pickerStyle(.radioGroup)

            SecureField("API key", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .disabled(sourcePreference == .publicAPI)

            Text(sourcePreference == .publicAPI ? "A API publica usada no app é a CoinGecko." : "Com CoinMarketCap selecionada, a chave será usada sempre que disponível.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("Cancelar", action: onCancel)
                Spacer()
                Button("Salvar") {
                    onSave(sourcePreference, apiKey)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 360)
    }
}
