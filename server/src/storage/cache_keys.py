from __future__ import annotations


def news(lang: str) -> str:
    return f"news:{lang}"


def events(lang: str) -> str:
    return f"events:{lang}"


def mensa_menu(location: str, lang: str) -> str:
    return f"mensa:{location}:{lang}"


def mensa_meal(location: str, lang: str) -> str:
    return f"mensa:meal:{location}:{lang}"


def mensa_filters(lang: str) -> str:
    return f"mensa:filters:{lang}"


def mensa_info(location: str, lang: str) -> str:
    return f"mensa:info:{location}:{lang}"


def helpful_numbers(lang: str) -> str:
    return f"helpful_numbers:{lang}"


def more(lang: str) -> str:
    return f"more:{lang}"


def article_body(item_id: int, lang: str) -> str:
    return f"article_body:{item_id}:{lang}"


def campus_map() -> str:
    return "map"


def scheduler_status() -> str:
    return "scheduler:status"


def scheduler_last_run(job: str) -> str:
    return f"scheduler:last_run:{job}"
