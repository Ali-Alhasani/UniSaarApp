from __future__ import annotations

from unittest.mock import AsyncMock, patch

from src.services.base_scraper import BaseScraper
from src.services.mensa_scraper import MensaScraper

_BASE_DATA = (
    '{"priceTiers":{"s":{"displayName":"Studenten"},'
    '"m":{"displayName":"Bedienstete"},'
    '"g":{"displayName":"Gäste"}}}'
)

_MENU_SB = (
    '{"days":[{"date":"2019-12-16T00:00:00.000Z","isPast":false,"counters":[{'
    '"id":"komplett","displayName":"Komplettmenü","description":"",'
    '"openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:15:00.000Z"},'
    '"color":{"r":217,"g":38,"b":26},'
    '"meals":[{"name":"Ungarisches Gulasch","notices":[],'
    '"components":[{"name":"Makkaroni","notices":["we"]}],'
    '"prices":{"s":"3,10","m":"5,25","g":"7,30"}}]}]}]}'
)

_MENU_WITH_PRICING_NOTICE = (
    '{"days":[{"date":"2019-12-16T00:00:00.000Z","counters":[{'
    '"id":"info","displayName":"Info","color":{"r":0,"g":0,"b":0},'
    '"meals":[{"name":"Salatbuffet","notices":[],"components":[],'
    '"pricingNotice":"Preis je nach Gewicht"}]}]}]}'
)


async def _fetch_menu(menu_json: str = _MENU_SB) -> object:
    # _fetch_base_data is called first, then fetch_menu – both use self.fetch
    fetch_mock = AsyncMock(side_effect=[_BASE_DATA, menu_json])
    with (
        patch.object(BaseScraper, "fetch", fetch_mock),
        patch(
            "src.services.mensa_scraper.settings.mensa_api_key.get_secret_value",
            return_value="test-key",
        ),
    ):
        scraper = MensaScraper()
        return await scraper.fetch_menu("sb", "de")


async def test_fetch_menu_first_day_date() -> None:
    menu = await _fetch_menu()
    assert len(menu.days) == 1
    assert menu.days[0].date == "Montag 16.12."


async def test_fetch_menu_opening_hours() -> None:
    menu = await _fetch_menu()
    assert menu.days[0].meals[0].opening_hours == "11:30 - 14:15"


async def test_fetch_menu_meal_name() -> None:
    menu = await _fetch_menu()
    assert menu.days[0].meals[0].meal_name == "Ungarisches Gulasch"


async def test_fetch_menu_prices_comma_to_period() -> None:
    menu = await _fetch_menu()
    prices = menu.days[0].meals[0].prices
    assert prices is not None
    price_map = {p.price_tag: p.price for p in prices}
    assert price_map["Studenten"] == "3.10"
    assert price_map["Bedienstete"] == "5.25"
    assert price_map["Gäste"] == "7.30"


async def test_fetch_menu_price_tiers_from_base_data() -> None:
    menu = await _fetch_menu()
    prices = menu.days[0].meals[0].prices
    assert prices is not None
    tags = {p.price_tag for p in prices}
    assert "Studenten" in tags
    assert "Bedienstete" in tags
    assert "Gäste" in tags


async def test_fetch_menu_notices_from_components() -> None:
    menu = await _fetch_menu()
    assert "we" in menu.days[0].meals[0].notices


async def test_fetch_menu_color_parsed() -> None:
    menu = await _fetch_menu()
    color = menu.days[0].meals[0].color
    assert color.r == 217
    assert color.g == 38
    assert color.b == 26


async def test_fetch_menu_pricing_notice_sets_prices_to_none() -> None:
    menu = await _fetch_menu(_MENU_WITH_PRICING_NOTICE)
    meal = menu.days[0].meals[0]
    assert meal.prices is None
    assert meal.pricing_notice == "Preis je nach Gewicht"


async def test_fetch_menu_components_extracted() -> None:
    menu = await _fetch_menu()
    assert "Makkaroni" in menu.days[0].meals[0].components


async def test_fetch_menu_missing_opening_hours_returns_empty_string() -> None:
    menu_json = (
        '{"days":[{"date":"2019-12-16T00:00:00.000Z","counters":[{'
        '"id":"k","displayName":"Kiosk","color":{"r":0,"g":0,"b":0},'
        '"meals":[{"name":"Suppe","notices":[],"components":[],'
        '"prices":{"s":"1,50"}}]}]}]}'
    )
    menu = await _fetch_menu(menu_json)
    assert menu.days[0].meals[0].opening_hours == ""


async def test_fetch_menu_unknown_tier_uses_tier_id_as_label() -> None:
    menu_json = (
        '{"days":[{"date":"2019-12-16T00:00:00.000Z","counters":[{'
        '"id":"k","displayName":"Kiosk","color":{"r":0,"g":0,"b":0},'
        '"meals":[{"name":"Pizza","notices":[],"components":[],'
        '"prices":{"x":"2,00"}}]}]}]}'
    )
    menu = await _fetch_menu(menu_json)
    prices = menu.days[0].meals[0].prices
    assert prices is not None
    assert prices[0].price_tag == "x"


async def test_fetch_menu_mojibake_meal_name_fixed() -> None:
    # "FlambÃ©e" is UTF-8 bytes for "é" decoded as Latin-1 → "Ã©"
    menu_json = (
        '{"days":[{"date":"2019-12-16T00:00:00.000Z","counters":[{'
        '"id":"k","displayName":"Kiosk","color":{"r":0,"g":0,"b":0},'
        '"meals":[{"name":"Tarte FlambÃ©e","notices":[],"components":[],'
        '"prices":{"s":"3,50"}}]}]}]}'
    )
    menu = await _fetch_menu(menu_json)
    assert menu.days[0].meals[0].meal_name == "Tarte Flambée"


async def test_fetch_menu_correct_umlaut_preserved() -> None:
    # Correctly stored "ü" must not be corrupted by the encoding fix
    menu_json = (
        '{"days":[{"date":"2019-12-16T00:00:00.000Z","counters":[{'
        '"id":"k","displayName":"Kiosk","color":{"r":0,"g":0,"b":0},'
        '"meals":[{"name":"Saarbrücker Spezialität","notices":[],"components":[],'
        '"prices":{"s":"3,50"}}]}]}]}'
    )
    menu = await _fetch_menu(menu_json)
    assert menu.days[0].meals[0].meal_name == "Saarbrücker Spezialität"


async def test_fetch_menu_nbsp_in_name_normalised() -> None:
    menu_json = (
        '{"days":[{"date":"2019-12-16T00:00:00.000Z","counters":[{'
        '"id":"k","displayName":"Kiosk","color":{"r":0,"g":0,"b":0},'
        '"meals":[{"name":"Schnitzel\xa0mit\xa0Pommes","notices":[],"components":[],'
        '"prices":{"s":"3,50"}}]}]}]}'
    )
    menu = await _fetch_menu(menu_json)
    assert menu.days[0].meals[0].meal_name == "Schnitzel mit Pommes"


async def test_fetch_menu_multiple_days() -> None:
    menu_json = (
        '{"days":['
        '{"date":"2019-12-16T00:00:00.000Z","counters":[{'
        '"id":"k","displayName":"Kiosk","color":{"r":0,"g":0,"b":0},'
        '"meals":[{"name":"Montag","notices":[],"components":[],"prices":{"s":"1,00"}}]}]},'
        '{"date":"2019-12-17T00:00:00.000Z","counters":[{'
        '"id":"k","displayName":"Kiosk","color":{"r":0,"g":0,"b":0},'
        '"meals":[{"name":"Dienstag","notices":[],"components":[],"prices":{"s":"1,00"}}]}]}'
        "]}"
    )
    menu = await _fetch_menu(menu_json)
    assert len(menu.days) == 2
    assert menu.days[0].date == "Montag 16.12."
    assert menu.days[1].date == "Dienstag 17.12."


async def test_main_screen_components_capped_at_five() -> None:
    comps = ",".join(f'{{"name":"C{i}","notices":[]}}' for i in range(8))
    menu_json = (
        '{"days":[{"date":"2019-12-16T00:00:00.000Z","counters":[{'
        '"id":"k","displayName":"Kiosk","color":{"r":0,"g":0,"b":0},'
        '"meals":[{"name":"Big Meal","notices":[],"components":['
        + comps
        + '],"prices":{"s":"1,00"}}]}]}]}'
    )
    fetch_mock = AsyncMock(side_effect=[_BASE_DATA, menu_json])
    with (
        patch.object(BaseScraper, "fetch", fetch_mock),
        patch(
            "src.services.mensa_scraper.settings.mensa_api_key.get_secret_value",
            return_value="test-key",
        ),
    ):
        scraper = MensaScraper()
        menu = await scraper.fetch_menu("sb", "de")

    assert len(menu.days[0].meals[0].components) == 5
    assert len(scraper.get_meal_details()[0].meal_components) == 8


async def test_component_with_tab_filtered_from_main_not_detail() -> None:
    menu_json = (
        '{"days":[{"date":"2019-12-16T00:00:00.000Z","counters":[{'
        '"id":"k","displayName":"Kiosk","color":{"r":0,"g":0,"b":0},'
        '"meals":[{"name":"Salatbuffet","notices":[],"components":['
        '{"name":"Tomatensalat","notices":[]},'
        '{"name":"Dummy\\tRez.Nr.\\tSort.","notices":[]}'
        '],"prices":{"s":"1,00"}}]}]}]}'
    )
    fetch_mock = AsyncMock(side_effect=[_BASE_DATA, menu_json])
    with (
        patch.object(BaseScraper, "fetch", fetch_mock),
        patch(
            "src.services.mensa_scraper.settings.mensa_api_key.get_secret_value",
            return_value="test-key",
        ),
    ):
        scraper = MensaScraper()
        menu = await scraper.fetch_menu("sb", "de")

    main_components = menu.days[0].meals[0].components
    assert "Tomatensalat" in main_components
    assert not any("\t" in c for c in main_components)

    detail_names = [
        mc.component_name for mc in scraper.get_meal_details()[0].meal_components
    ]
    assert any("\t" in n for n in detail_names)


async def test_component_with_newline_filtered_from_main_not_detail() -> None:
    menu_json = (
        '{"days":[{"date":"2019-12-16T00:00:00.000Z","counters":[{'
        '"id":"k","displayName":"Kiosk","color":{"r":0,"g":0,"b":0},'
        '"meals":[{"name":"Gulasch","notices":[],"components":['
        '{"name":"Kartoffeln","notices":[]},'
        '{"name":"line1\\nline2","notices":[]}'
        '],"prices":{"s":"2,50"}}]}]}]}'
    )
    fetch_mock = AsyncMock(side_effect=[_BASE_DATA, menu_json])
    with (
        patch.object(BaseScraper, "fetch", fetch_mock),
        patch(
            "src.services.mensa_scraper.settings.mensa_api_key.get_secret_value",
            return_value="test-key",
        ),
    ):
        scraper = MensaScraper()
        menu = await scraper.fetch_menu("sb", "de")

    main_components = menu.days[0].meals[0].components
    assert "Kartoffeln" in main_components
    assert not any("\n" in c for c in main_components)

    detail_names = [
        mc.component_name for mc in scraper.get_meal_details()[0].meal_components
    ]
    assert any("\n" in n for n in detail_names)


async def test_fetch_menu_missing_price_tiers_falls_back_to_tier_id() -> None:
    base_no_tiers = "{}"
    fetch_mock = AsyncMock(side_effect=[base_no_tiers, _MENU_SB])
    with (
        patch.object(BaseScraper, "fetch", fetch_mock),
        patch(
            "src.services.mensa_scraper.settings.mensa_api_key.get_secret_value",
            return_value="test-key",
        ),
    ):
        scraper = MensaScraper()
        menu = await scraper.fetch_menu("sb", "de")
    prices = menu.days[0].meals[0].prices
    assert prices is not None
    tags = {p.price_tag for p in prices}
    assert "s" in tags
    assert "m" in tags
    assert "g" in tags
