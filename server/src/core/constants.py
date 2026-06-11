from __future__ import annotations

from src.core.enums import CampusLocation, Language, MensaLocation

SUPPORTED_LANGUAGES: list[Language] = [Language.DE, Language.EN, Language.FR]

# All individual mensaar API sources — used by the scraper.
MENSA_LOCATIONS: list[MensaLocation] = list(MensaLocation)

# Campus-level locations exposed to iOS clients.
MENSA_CAMPUS_LOCATIONS: list[CampusLocation] = list(CampusLocation)

# Maps campus to display city name.
CAMPUS_CITY_NAMES: dict[CampusLocation, str] = {
    CampusLocation.SB: "Saarbrücken",
    CampusLocation.HOM: "Homburg",
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
