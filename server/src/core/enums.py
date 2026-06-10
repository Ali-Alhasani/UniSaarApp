from __future__ import annotations

from enum import StrEnum


class Language(StrEnum):
    DE = "de"
    EN = "en"
    FR = "fr"


class CampusLocation(StrEnum):
    SB = "sb"
    HOM = "hom"

    @property
    def code(self) -> int:
        return 1 if self == CampusLocation.SB else 2


class MensaLocation(StrEnum):
    MENSB = "sb"
    MENSAGARTEN = "mensagarten"
    B4R1STA = "b4r1sta"
    MENSHOM = "hom"

    @property
    def campus(self) -> CampusLocation:
        return (
            CampusLocation.HOM if self == MensaLocation.MENSHOM else CampusLocation.SB
        )

    @property
    def source_idx(self) -> int:
        return _MENSA_SOURCE_IDX[self]


_MENSA_SOURCE_IDX: dict[MensaLocation, int] = {
    MensaLocation.MENSB: 0,
    MensaLocation.MENSAGARTEN: 1,
    MensaLocation.B4R1STA: 2,
    MensaLocation.MENSHOM: 0,
}
