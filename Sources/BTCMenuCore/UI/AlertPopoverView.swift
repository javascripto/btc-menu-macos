import SwiftUI

struct AlertPopoverView: View {
    @State private var alertType: AlertType
    @State private var priceDirection: PriceDirection
    @State private var priceTargetText: String
    @State private var priceRepeat: Bool
    @State private var variationWindow: VariationWindow
    @State private var variationThreshold: Double

    let onSave: (AlertConfiguration) -> Void
    let onTest: () -> Void
    let onCancel: () -> Void

    init(
        initialConfig: AlertConfiguration,
        onSave: @escaping (AlertConfiguration) -> Void,
        onTest: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        _alertType = State(initialValue: initialConfig.type)
        _priceDirection = State(initialValue: initialConfig.priceDirection)
        _priceTargetText = State(initialValue: initialConfig.priceTarget.map { String($0) } ?? "")
        _priceRepeat = State(initialValue: initialConfig.priceRepeat)
        _variationWindow = State(initialValue: initialConfig.variationWindow)
        _variationThreshold = State(initialValue: initialConfig.variationThreshold)
        self.onSave = onSave
        self.onTest = onTest
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Definir alerta")
                .font(.headline)

            Text("Configure um alerta por preco ou por variacao. Ele sera salvo no app e monitorado nas proximas atualizacoes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Picker("Tipo", selection: $alertType) {
                Text("Preco").tag(AlertType.price)
                Text("Variacao").tag(AlertType.variation)
            }
            .pickerStyle(.segmented)

            if alertType == .price {
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Preco alvo", text: $priceTargetText)
                        .textFieldStyle(.roundedBorder)

                    Picker("Direcao", selection: $priceDirection) {
                        Text("Acima").tag(PriceDirection.above)
                        Text("Abaixo").tag(PriceDirection.below)
                    }
                    .pickerStyle(.segmented)

                    Toggle("Repetir ate desativar", isOn: $priceRepeat)
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Janela", selection: $variationWindow) {
                        ForEach(VariationWindow.allCases, id: \.self) { window in
                            Text(window.rawValue).tag(window)
                        }
                    }
                    .pickerStyle(.menu)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Limite")
                            Spacer()
                            Text(String(format: "%.1f%%", variationThreshold))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $variationThreshold, in: 0.1...10.0, step: 0.1)
                    }
                }
            }

            HStack(spacing: 10) {
                Button("Cancelar", action: onCancel)
                Button("Testar", action: onTest)
                Spacer()
                Button("Salvar") {
                    onSave(makeConfiguration())
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 380)
    }

    private func makeConfiguration() -> AlertConfiguration {
        if alertType == .price {
            return AlertConfiguration(
                enabled: true,
                type: .price,
                priceDirection: priceDirection,
                priceTarget: Double(priceTargetText.trimmingCharacters(in: .whitespacesAndNewlines)),
                priceRepeat: priceRepeat,
                variationWindow: variationWindow,
                variationThreshold: variationThreshold
            )
        }

        return AlertConfiguration(
            enabled: true,
            type: .variation,
            priceDirection: priceDirection,
            priceTarget: Double(priceTargetText.trimmingCharacters(in: .whitespacesAndNewlines)),
            priceRepeat: priceRepeat,
            variationWindow: variationWindow,
            variationThreshold: variationThreshold
        )
    }
}
