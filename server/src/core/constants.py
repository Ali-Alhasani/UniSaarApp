from __future__ import annotations

from src.core.enums import Language, MensaLocation

NEWSFEED_LANGUAGES: list[Language] = [Language.DE, Language.EN, Language.FR]
MENSA_LANGUAGES: list[Language] = [Language.DE, Language.EN, Language.FR]
MENSA_LOCATIONS: list[MensaLocation] = [
    MensaLocation.SB,
    MensaLocation.HOM,
    MensaLocation.MENSAGARTEN,
]
# Campus locations exposed to iOS clients via /mensa/filters.
# MENSAGARTEN is scraped internally but not surfaced as a separate picker entry.
MENSA_CAMPUS_LOCATIONS: list[MensaLocation] = [MensaLocation.SB, MensaLocation.HOM]
# Maps location shortcodes to display city names.
CAMPUS_CITY_NAMES: dict[MensaLocation, str] = {
    MensaLocation.SB: "Saarbrücken",
    MensaLocation.HOM: "Homburg",
}

NEWS_URLS: dict[Language, str] = {
    Language.DE: "https://www.uni-saarland.de/universitaet/aktuell/news/feed.rss",
    Language.EN: "https://www.uni-saarland.de/en/university/news/news/feed.rss",
    Language.FR: "https://www.uni-saarland.de/fr/universite/actualite/actualites/feed.rss",
}
EVENTS_URLS: dict[Language, str] = {
    Language.DE: "https://www.uni-saarland.de/universitaet/aktuell/veranstaltungen/feed.rss",
    Language.EN: "https://www.uni-saarland.de/en/university/news/events/feed.rss",
    Language.FR: "https://www.uni-saarland.de/fr/universite/actualite/manifestations/feed.rss",
}

MENSA_BASE_URL = "https://mensaar.de/api/1/{api_key}/1/{lang}/getBaseData"
MENSA_MENU_URL = "https://mensaar.de/api/1/{api_key}/1/{lang}/getMenu/{location}"

STAFF_SEARCH_URL = (
    "https://www.lsf.uni-saarland.de/qisserver/rds"
    "?state=wsearchv&search=7&P.vx=alles"
    "&personal.nachname={query}&P_start=0&P_anzahl=10"
)
STAFF_DETAIL_URL = (
    "https://www.lsf.uni-saarland.de/qisserver/rds"
    "?state=verpublish&status=init&vmfile=no"
    "&moduleCall=webInfo&publishConfFile=webInfoPerson"
    "&publishSubDir=personal&keep=y&purge=y&personal.pid={pid}"
)
