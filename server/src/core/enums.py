from __future__ import annotations

from enum import StrEnum


class Language(StrEnum):
    DE = "de"
    EN = "en"
    FR = "fr"


class MensaLocation(StrEnum):
    SB = "sb"
    HOM = "hom"
    MENSAGARTEN = "mensagarten"
