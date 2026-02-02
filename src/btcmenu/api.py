import requests


def fetch_btc_quote(api_key, currency):
    headers = {
        "Accepts": "application/json",
        "X-CMC_PRO_API_KEY": api_key,
        "User-Agent": "BTCMenuBarApp/1.0",
    }
    response = requests.get(
        "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest",
        headers=headers,
        params={
            "symbol": "BTC",
            "convert": currency.upper(),
        },
        timeout=10,
    )
    response.raise_for_status()
    quote = response.json()["data"]["BTC"]["quote"]
    return quote[currency.upper()]
