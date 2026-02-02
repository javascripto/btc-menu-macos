from datetime import datetime

import rumps
from .alert_window import open_alert_window
from .alerts import beep, notify
from .api import fetch_btc_quote
from .formatting import format_price, format_volume
from .logger import log
from .settings import (
    load_api_key,
    load_alert_config,
    load_currency,
    disable_alert,
    save_api_key,
    save_currency,
)


class BTCMenuBarApp(rumps.App):
    def __init__(self):
        self.currency = load_currency() or "usd"
        self.api_key = load_api_key()
        self.last_price = None
        self.change_24h = None
        self.last_fetch_ts = 0

        self.api_key_item = rumps.MenuItem("Definir API Key", callback=self.set_api_key)
        self.alert_item = rumps.MenuItem(
            "Definir alerta de preço/variação", callback=self.open_alert_window
        )
        self.last_update_item = rumps.MenuItem("Última atualização: --:--")
        self.change_24h_item = rumps.MenuItem("Variação 24h: --")
        self.volume_item = rumps.MenuItem("Volume 24h: --")

        super().__init__("₿ ...", quit_button=None)

        self.usd_item = rumps.MenuItem("USD", callback=self.set_usd)
        self.brl_item = rumps.MenuItem("BRL", callback=self.set_brl)

        moeda_menu = rumps.MenuItem("Moeda")
        moeda_menu.add(self.usd_item)
        moeda_menu.add(self.brl_item)

        self.menu = [
            rumps.MenuItem("Atualizar agora", callback=self.manual_update),
            None,
            self.last_update_item,
            self.change_24h_item,
            self.volume_item,
            None,
            moeda_menu,
            self.alert_item,
            self.api_key_item,
            None,
            rumps.MenuItem("Sair", callback=rumps.quit_application),
        ]

        if self.api_key:
            self.update_currency_check()
            self.update_price(force=True)
        else:
            self.title = "₿ --"

    def update_currency_check(self):
        self.usd_item.state = self.currency == "usd"
        self.brl_item.state = self.currency == "brl"

    def set_usd(self, _):
        log("MOEDA", "Trocando moeda para USD")
        self.currency = "usd"
        save_currency(self.currency)
        self.update_currency_check()
        self.update_price(force=True)

    def set_brl(self, _):
        log("MOEDA", "Trocando moeda para BRL")
        self.currency = "brl"
        save_currency(self.currency)
        self.update_currency_check()
        self.update_price(force=True)

    def update_price(self, _=None, force=False):
        import time

        now = time.time()
        if force:
            log("UPDATE", "Atualização forçada")
        else:
            log("UPDATE", "Atualização automática")
        if not force and now - self.last_fetch_ts < 30:
            log("COOLDOWN", "Ignorando chamada (cooldown ativo)")
            return
        try:
            if not self.api_key:
                raise Exception("API key não configurada")

            log("API", f"Buscando BTC em {self.currency.upper()} na CoinMarketCap")
            data = fetch_btc_quote(self.api_key, self.currency)
            self.change_24h = data.get("percent_change_24h")
            change_1h = data.get("percent_change_1h")
            change_3h = data.get("percent_change_3h")
            volume_24h = data.get("volume_24h")

            price = data["price"]

            emoji = "→"
            if self.last_price is not None:
                if price > self.last_price:
                    emoji = "🟢↑"
                elif price < self.last_price:
                    emoji = "🔴↓"

            if self.change_24h is not None:
                change_emoji = "🟢" if self.change_24h >= 0 else "🔴"
                self.change_24h_item.title = (
                    f"Variação 24h: {change_emoji} {self.change_24h:.2f}%"
                )

            symbol = "$" if self.currency == "usd" else "R$"

            if volume_24h is not None:
                formatted_volume = format_volume(volume_24h)
                self.volume_item.title = f"Volume 24h: {symbol}{formatted_volume}"

            prev_price = self.last_price
            self.last_price = price
            log("API", f"Sucesso | BTC {self.currency.upper()} = {price}")
            self.last_fetch_ts = now

            formatted_price = format_price(price)
            self.title = f"{emoji} ₿ {symbol}{formatted_price}"

            now_str = datetime.now().strftime("%H:%M:%S")
            self.last_update_item.title = f"Última atualização: {now_str}"

            self._check_alerts(price, prev_price, change_1h, change_3h, self.change_24h)

        except Exception as exc:
            log("ERRO", f"Falha ao atualizar preço do BTC: {exc}")
            self.title = "₿ erro"

    def manual_update(self, _):
        log("UPDATE", "Atualização manual solicitada")
        self.title = "₿ ..."
        self.update_price(force=True)

    def set_api_key(self, _):
        response = rumps.Window(
            title="CoinMarketCap API Key",
            message="Cole sua API key da CoinMarketCap",
            default_text=self.api_key or "",
            ok="Salvar",
            cancel="Cancelar",
        ).run()

        if response.clicked:
            key = response.text.strip()
            if key:
                self.api_key = key
                save_api_key(self.api_key)
                log("CONFIG", "API key salva com sucesso")
                self.update_price(force=True)
            else:
                rumps.notification(
                    title="Erro",
                    message="API key não pode ser vazia",
                )

    def open_alert_window(self, _):
        open_alert_window()

    def _check_alerts(self, price, prev_price, change_1h, change_3h, change_24h):
        config = load_alert_config()
        if not config["enabled"]:
            return

        if config["type"] == "price":
            target = float(config["price_target"] or 0)
            if target <= 0 or prev_price is None:
                return

            direction = config["price_direction"]
            crossed_up = prev_price < target <= price
            crossed_down = prev_price > target >= price
            triggered = (direction == "above" and crossed_up) or (
                direction == "below" and crossed_down
            )
            if triggered:
                arrow = "↑" if direction == "above" else "↓"
                notify(
                    "BTCMenu",
                    f"Alerta de preço {arrow}: {price:.2f} {self.currency.upper()}",
                )
                beep()
                log("ALERTA", f"Alerta de preço disparado: {price:.2f}")
                if not config["price_repeat"]:
                    disable_alert()

        elif config["type"] == "variation":
            window = config["variation_window"]
            threshold = float(config["variation_threshold"] or 0)
            if threshold <= 0:
                return

            change_map = {"1h": change_1h, "3h": change_3h, "24h": change_24h}
            value = change_map.get(window)
            if value is None:
                return

            if abs(value) >= threshold:
                direction = "↑" if value >= 0 else "↓"
                notify(
                    "BTCMenu",
                    f"Variação {window} {direction} {value:.2f}% (limite {threshold:.1f}%)",
                )
                beep()
                log("ALERTA", f"Alerta de variação disparado: {value:.2f}%")
                disable_alert()


def main():
    BTCMenuBarApp().run()
