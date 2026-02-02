def format_price(value):
    formatted = f"{value:,.2f}"
    return formatted.replace(",", "X").replace(".", ",").replace("X", ".")


def format_volume(value):
    formatted = f"{value:,.0f}"
    return formatted.replace(",", "X").replace(".", ",").replace("X", ".")
