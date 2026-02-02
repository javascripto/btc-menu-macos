from AppKit import (
    NSAlert,
    NSAlertStyleInformational,
    NSButton,
    NSButtonTypeSwitch,
    NSButtonTypeRadio,
    NSSlider,
    NSPopUpButton,
    NSTextField,
    NSView,
)
from Foundation import NSObject
from objc import super as objc_super

from .alerts import beep, notify
from .logger import log
from .settings import load_alert_config, save_alert_config


class AlertController(NSObject):
    def init(self):
        self = objc_super(AlertController, self).init()
        if self is None:
            return None
        self.price_radio = None
        self.variation_radio = None
        self.price_field = None
        self.price_label = None
        self.variation_slider = None
        self.variation_label = None
        self.variation_value = None
        self.direction_label = None
        self.direction_popup = None
        self.repeat_checkbox = None
        self.window_popup = None
        return self

    def updateMode_(self, _sender):
        is_price = self.price_radio.state() == 1
        self.price_field.setHidden_(not is_price)
        self.price_label.setHidden_(not is_price)
        self.direction_label.setHidden_(not is_price)
        self.direction_popup.setHidden_(not is_price)
        self.repeat_checkbox.setHidden_(not is_price)
        self.variation_slider.setHidden_(is_price)
        self.variation_label.setHidden_(is_price)
        self.variation_value.setHidden_(is_price)
        self.window_popup.setHidden_(is_price)

    def sliderChanged_(self, _sender):
        value = float(self.variation_slider.doubleValue())
        self.variation_value.setStringValue_(f"{value:.1f}%")


def open_alert_window():
    current = load_alert_config()
    controller = AlertController.alloc().init()

    alert = NSAlert.alloc().init()
    alert.setAlertStyle_(NSAlertStyleInformational)
    alert.setMessageText_("Definir alerta de preço/variação")
    alert.setInformativeText_("Escolha o tipo de alerta e defina o valor.")

    view = NSView.alloc().initWithFrame_(((0, 0), (360, 140)))

    price_radio = NSButton.alloc().initWithFrame_(((0, 110), (200, 20)))
    price_radio.setButtonType_(NSButtonTypeRadio)
    price_radio.setTitle_("Alerta de preço")
    if current["type"] == "variation":
        price_radio.setState_(0)
    else:
        price_radio.setState_(1)

    variation_radio = NSButton.alloc().initWithFrame_(((200, 110), (200, 20)))
    variation_radio.setButtonType_(NSButtonTypeRadio)
    variation_radio.setTitle_("Alerta de variação")
    if current["type"] == "variation":
        variation_radio.setState_(1)
    else:
        variation_radio.setState_(0)

    price_label = NSTextField.alloc().initWithFrame_(((0, 80), (120, 20)))
    price_label.setStringValue_("Preço alvo:")
    price_label.setBezeled_(False)
    price_label.setDrawsBackground_(False)
    price_label.setEditable_(False)
    price_label.setSelectable_(False)

    price_field = NSTextField.alloc().initWithFrame_(((120, 78), (120, 24)))
    if current["price_target"] > 0:
        price_field.setStringValue_(f'{current["price_target"]}')
    else:
        price_field.setStringValue_("")

    direction_label = NSTextField.alloc().initWithFrame_(((0, 52), (120, 20)))
    direction_label.setStringValue_("Direção:")
    direction_label.setBezeled_(False)
    direction_label.setDrawsBackground_(False)
    direction_label.setEditable_(False)
    direction_label.setSelectable_(False)

    direction_popup = NSPopUpButton.alloc().initWithFrame_(((120, 50), (120, 24)))
    direction_popup.addItemsWithTitles_(["Acima", "Abaixo"])
    if current["price_direction"] == "below":
        direction_popup.selectItemAtIndex_(1)

    repeat_checkbox = NSButton.alloc().initWithFrame_(((250, 50), (110, 20)))
    repeat_checkbox.setButtonType_(NSButtonTypeSwitch)
    repeat_checkbox.setTitle_("Repetir")
    repeat_checkbox.setState_(1 if current["price_repeat"] else 0)

    variation_label = NSTextField.alloc().initWithFrame_(((0, 45), (160, 20)))
    variation_label.setStringValue_("Variação (0,1% a 10%):")
    variation_label.setBezeled_(False)
    variation_label.setDrawsBackground_(False)
    variation_label.setEditable_(False)
    variation_label.setSelectable_(False)

    variation_slider = NSSlider.alloc().initWithFrame_(((0, 20), (240, 20)))
    variation_slider.setMinValue_(0.1)
    variation_slider.setMaxValue_(10.0)
    variation_slider.setDoubleValue_(current["variation_threshold"])
    variation_slider.setNumberOfTickMarks_(100)
    variation_slider.setAllowsTickMarkValuesOnly_(False)

    variation_value = NSTextField.alloc().initWithFrame_(((250, 18), (80, 24)))
    variation_value.setStringValue_(f'{current["variation_threshold"]:.1f}%')
    variation_value.setBezeled_(False)
    variation_value.setDrawsBackground_(False)
    variation_value.setEditable_(False)
    variation_value.setSelectable_(False)

    window_popup = NSPopUpButton.alloc().initWithFrame_(((250, 80), (80, 24)))
    window_popup.addItemsWithTitles_(["1h", "3h", "24h"])
    try:
        window_popup.selectItemWithTitle_(current["variation_window"])
    except Exception:
        window_popup.selectItemAtIndex_(2)

    controller.price_radio = price_radio
    controller.variation_radio = variation_radio
    controller.price_field = price_field
    controller.price_label = price_label
    controller.variation_slider = variation_slider
    controller.variation_label = variation_label
    controller.variation_value = variation_value
    controller.direction_label = direction_label
    controller.direction_popup = direction_popup
    controller.repeat_checkbox = repeat_checkbox
    controller.window_popup = window_popup

    price_radio.setTarget_(controller)
    price_radio.setAction_("updateMode:")
    variation_radio.setTarget_(controller)
    variation_radio.setAction_("updateMode:")
    variation_slider.setTarget_(controller)
    variation_slider.setAction_("sliderChanged:")

    controller.updateMode_(None)

    view.addSubview_(price_radio)
    view.addSubview_(variation_radio)
    view.addSubview_(price_label)
    view.addSubview_(price_field)
    view.addSubview_(direction_label)
    view.addSubview_(direction_popup)
    view.addSubview_(repeat_checkbox)
    view.addSubview_(variation_label)
    view.addSubview_(variation_slider)
    view.addSubview_(variation_value)
    view.addSubview_(window_popup)

    alert.setAccessoryView_(view)
    alert.addButtonWithTitle_("Salvar")
    alert.addButtonWithTitle_("Testar")
    alert.addButtonWithTitle_("Cancelar")

    while True:
        response = alert.runModal()
        if response == 1000:  # Salvar
            is_price = price_radio.state() == 1
            if is_price:
                value = price_field.stringValue().strip()
                direction = (
                    "above" if direction_popup.indexOfSelectedItem() == 0 else "below"
                )
                repeat = repeat_checkbox.state() == 1
                save_alert_config(
                    "price",
                    direction,
                    value or "0",
                    repeat,
                    current["variation_window"],
                    current["variation_threshold"],
                )
                log("CONFIG", f"Alerta de preço definido: {value}")
            else:
                value = variation_slider.doubleValue()
                window = window_popup.titleOfSelectedItem()
                save_alert_config(
                    "variation",
                    current["price_direction"],
                    current["price_target"],
                    current["price_repeat"],
                    window,
                    value,
                )
                log("CONFIG", f"Alerta de variação definido: {value:.1f}%")
            break
        if response == 1001:  # Testar
            beep()
            notify("BTCMenu", "Teste de alerta executado")
            log("ALERTA", "Teste de alerta executado")
            continue
        break
