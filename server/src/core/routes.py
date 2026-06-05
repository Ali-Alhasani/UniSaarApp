from __future__ import annotations

from enum import StrEnum


class Route(StrEnum):
    # Directory
    DIRECTORY_SEARCH = "/directory/search"
    DIRECTORY_PERSON_DETAILS = "/directory/personDetails"
    DIRECTORY_HELPFUL_NUMBERS = "/directory/helpfulNumbers"

    # Mensa
    MENSA_MAIN_SCREEN = "/mensa/mainScreen"
    MENSA_MEAL_DETAIL = "/mensa/mealDetail"
    MENSA_INFO = "/mensa/info"
    MENSA_FILTERS = "/mensa/filters"

    # News
    NEWS_MAIN_SCREEN = "/news/mainScreen"
    NEWS_CATEGORIES = "/news/categories"
    NEWS_DETAILS = "/news/details"

    # Events
    EVENTS_MAIN_SCREEN = "/events/mainScreen"
    EVENTS_CATEGORIES = "/events/categories"
    EVENTS_DETAILS = "/events/details"

    # Other
    CAMPUS_MAP = "/map/"
    MORE = "/more"
    HEALTH = "/health"
