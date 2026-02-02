# BTCMenu

Menu bar app para acompanhar o preço do BTC usando a API da CoinMarketCap.

## Requisitos
- macOS
- Python 3.9+ (recomendado 3.11)
- Chave da API da CoinMarketCap

## Rodar em modo desenvolvimento
```bash
python3 -m pip install -r requirements.txt
python3 -m btcmenu
```

## Empacotar como app macOS (.app)
```bash
./build_app.sh
```
O app será gerado em `dist/BTCMenu.app`.

## Estrutura
- `src/btcmenu/__main__.py`: entrypoint simples do app
- `src/btcmenu/`: código do app em módulos
- `assets/`: ícones gerados
- `scripts/`: utilitários (ex.: geração de ícone)

## Configuração
A API key e a moeda são salvas via `NSUserDefaults` no macOS.
