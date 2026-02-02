import os

from .logger import log
import rumps


def beep():
    try:
        os.system("afplay /System/Library/Sounds/Ping.aiff &")
    except Exception as exc:
        log("ERRO", f"Falha ao tocar som: {exc}")


def notify(title, message):
    try:
        rumps.notification(title=title, message=message)
    except Exception as exc:
        log("ERRO", f"Falha ao enviar notificação: {exc}")
