def log(tag, message):
    colors = {
        "API": "\033[94m",
        "UPDATE": "\033[92m",
        "COOLDOWN": "\033[93m",
        "MOEDA": "\033[96m",
        "ALERTA": "\033[95m",
        "CONFIG": "\033[90m",
        "ERRO": "\033[91m",
    }
    reset = "\033[0m"
    color = colors.get(tag, "")
    print(f"{color}[{tag}]{reset} {message}")
