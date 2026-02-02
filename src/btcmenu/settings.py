from Foundation import NSUserDefaults


_DEFAULTS = NSUserDefaults.standardUserDefaults()


def load_currency():
    return _DEFAULTS.stringForKey_("currency")


def save_currency(currency):
    _DEFAULTS.setObject_forKey_(currency, "currency")
    _DEFAULTS.synchronize()


def load_api_key():
    return _DEFAULTS.stringForKey_("api_key")


def save_api_key(api_key):
    _DEFAULTS.setObject_forKey_(api_key, "api_key")
    _DEFAULTS.synchronize()


def _get_string(key, default=None):
    value = _DEFAULTS.stringForKey_(key)
    return value if value is not None else default


def _get_float(key, default=0.0):
    value = _DEFAULTS.objectForKey_(key)
    try:
        return float(value)
    except (TypeError, ValueError):
        return float(default)


def _get_bool(key, default=False):
    if _DEFAULTS.objectForKey_(key) is None:
        return bool(default)
    return bool(_DEFAULTS.boolForKey_(key))


def save_alert_config(
    alert_type,
    price_direction,
    price_target,
    price_repeat,
    variation_window,
    variation_threshold,
):
    _DEFAULTS.setObject_forKey_(alert_type, "alert_type")
    _DEFAULTS.setObject_forKey_(price_direction, "alert_price_direction")
    _DEFAULTS.setObject_forKey_(str(price_target), "alert_price_target")
    _DEFAULTS.setBool_forKey_(bool(price_repeat), "alert_price_repeat")
    _DEFAULTS.setObject_forKey_(variation_window, "alert_variation_window")
    _DEFAULTS.setObject_forKey_(str(variation_threshold), "alert_variation_threshold")
    _DEFAULTS.setBool_forKey_(True, "alert_enabled")
    _DEFAULTS.synchronize()


def load_alert_config():
    return {
        "enabled": _get_bool("alert_enabled", False),
        "type": _get_string("alert_type", "price"),
        "price_direction": _get_string("alert_price_direction", "above"),
        "price_target": _get_float("alert_price_target", 0.0),
        "price_repeat": _get_bool("alert_price_repeat", True),
        "variation_window": _get_string("alert_variation_window", "24h"),
        "variation_threshold": _get_float("alert_variation_threshold", 1.0),
    }


def disable_alert():
    _DEFAULTS.setBool_forKey_(False, "alert_enabled")
    _DEFAULTS.synchronize()
