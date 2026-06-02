from __future__ import annotations

NEWSFEED_LANGUAGES: list[str] = ["de", "en", "fr"]
MENSA_LANGUAGES: list[str] = ["de", "en", "fr"]
MENSA_LOCATIONS: list[str] = ["sb", "hom", "forum", "mensagarten"]

NEWS_URLS: dict[str, str] = {
    "de": "https://www.uni-saarland.de/universitaet/aktuell/news/feed.rss",
    "en": "https://www.uni-saarland.de/en/university/news/news/feed.rss",
    "fr": "https://www.uni-saarland.de/fr/universite/actualite/actualites/feed.rss",
}
EVENTS_URLS: dict[str, str] = {
    "de": "https://www.uni-saarland.de/universitaet/aktuell/veranstaltungen/feed.rss",
    "en": "https://www.uni-saarland.de/en/university/news/events/feed.rss",
    "fr": "https://www.uni-saarland.de/fr/universite/actualite/manifestations/feed.rss",
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
