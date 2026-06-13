from __future__ import annotations

import json
from datetime import UTC, date, datetime

from loguru import logger

from src.core.config import settings
from src.core.constants import (
    CAMPUS_CITY_NAMES,
    MENSA_BASE_URL,
    MENSA_CAMPUS_LOCATIONS,
    MENSA_MENU_URL,
)
from src.core.enums import Language, MensaLocation
from src.core.meal_id import generate_meal_id
from src.models.mensa import (
    MensaColor,
    MensaComponent,
    MensaDay,
    MensaFilterLocation,
    MensaFilterNotice,
    MensaFilters,
    MensaMeal,
    MensaMealDetail,
    MensaMenu,
    MensaNotice,
    MensaPrice,
)
from src.services.base_scraper import BaseScraper, ScraperError
from src.services.date_service import format_mensa_date


class MensaScraper(BaseScraper):
    def __init__(self) -> None:
        super().__init__()
        self._price_tiers: dict[str, str] = {}
        self._notices: dict[str, object] = {}
        self._filter_locations: list[MensaFilterLocation] = []
        self._meal_details: dict[int, MensaMealDetail] = {}

    async def _fetch_base_data(self, lang: Language) -> None:
        api_key = settings.mensa_api_key.get_secret_value()
        if not api_key:
            raise ScraperError("MENSA_API_KEY is not set in .secrets")
        url = MENSA_BASE_URL.format(api_key=api_key, lang=lang)
        raw = await self.fetch(url)
        data: dict[str, object] = json.loads(raw)

        tiers = data.get("priceTiers", {})
        if isinstance(tiers, dict):
            self._price_tiers = {
                tier_id: (
                    str(info.get("displayName") or tier_id)
                    if isinstance(info, dict)
                    else str(tier_id)
                )
                for tier_id, info in tiers.items()
            }

        raw_notices = data.get("notices", {})
        self._notices = raw_notices if isinstance(raw_notices, dict) else {}

        raw_locs = data.get("locations", {})
        if isinstance(raw_locs, dict):
            self._filter_locations = [
                MensaFilterLocation(
                    location_id=loc_id,
                    name=(
                        str(info.get("displayName") or loc_id)
                        if isinstance(info, dict)
                        else str(loc_id)
                    ),
                )
                for loc_id, info in raw_locs.items()
            ]

    def _notice_obj(self, notice_id: str) -> MensaNotice:
        info = self._notices.get(str(notice_id))
        display_name = (
            str(info.get("displayName") or notice_id)
            if isinstance(info, dict)
            else str(notice_id)
        )
        return MensaNotice(notice=str(notice_id), display_name=display_name)

    def _parse_notices(self, notice_ids: object | None) -> list[MensaNotice]:
        if not isinstance(notice_ids, list):
            return []
        return [self._notice_obj(str(n)) for n in notice_ids]

    @staticmethod
    def _clean(raw: str) -> str:
        """Normalize a string field from the mensa API.

        Reverses UTF-8-as-Latin-1 double-encoding present in some API strings.
        E.g. "Ã©" (two Latin-1 code points) re-decodes as UTF-8 to "é".
        Correctly stored German umlauts are preserved: their single Latin-1
        bytes (0xfc for u with umlaut, etc.) are not valid standalone UTF-8,
        so the except branch returns them unchanged.
        """
        text = raw.replace("\xa0", " ").strip()
        try:
            return text.encode("latin-1").decode("utf-8")
        except (UnicodeEncodeError, UnicodeDecodeError):
            return text

    @staticmethod
    def _has_control_chars(text: str) -> bool:
        return any(ord(c) < 0x20 for c in text)

    @staticmethod
    def _parse_opening_hours(hours: object) -> str:
        if not isinstance(hours, dict):
            return ""
        try:
            start_str = str(hours.get("start", ""))
            end_str = str(hours.get("end", ""))
            start = datetime.fromisoformat(start_str).astimezone(UTC)
            end = datetime.fromisoformat(end_str).astimezone(UTC)
            return f"{start.hour:02}:{start.minute:02} - {end.hour:02}:{end.minute:02}"
        except (ValueError, KeyError):
            return ""

    def _parse_meal(
        self,
        meal_data: dict[str, object],
        counter_name: str,
        counter_desc: str,
        opening_hours: str,
        color: MensaColor,
        location: MensaLocation,
        day: date,
        counter_idx: int,
        meal_idx: int,
    ) -> MensaMeal | None:
        try:
            meal_id = generate_meal_id(location, day, counter_idx, meal_idx)
        except ValueError:
            logger.warning(
                "mensa:{} — skipping meal at counter={} meal={} (ID out of range)",
                location,
                counter_idx,
                meal_idx,
            )
            return None

        meal_notices = self._parse_notices(meal_data.get("notices"))
        # Union of meal-level + component notices, used only for MensaMeal.notices
        # so the main-screen allergen filter sees all notices across the whole meal.
        all_notices: set[str] = {n.notice for n in meal_notices}

        components: list[str] = []
        rich_components: list[MensaComponent] = []
        raw_components = meal_data.get("components", [])
        if isinstance(raw_components, list):
            for comp in raw_components:
                if not isinstance(comp, dict):
                    continue
                comp_name = self._clean(str(comp.get("name", "")))
                comp_notices = self._parse_notices(comp.get("notices"))
                all_notices.update(n.notice for n in comp_notices)
                if comp_name:
                    rich_components.append(
                        MensaComponent(
                            component_name=comp_name,
                            notices=comp_notices,
                        )
                    )
                    if not self._has_control_chars(comp_name) and len(components) < 5:
                        components.append(comp_name)

        name = self._clean(str(meal_data.get("name", "")))
        if len(name) > 80:
            name = name[:80].rsplit(" ", 1)[0] + "…"
        pricing_notice_raw = meal_data.get("pricingNotice")
        pricing_notice: str | None = (
            str(pricing_notice_raw) if pricing_notice_raw is not None else None
        )

        prices: list[MensaPrice] | None = None
        if pricing_notice is None:
            raw_prices = meal_data.get("prices")
            if isinstance(raw_prices, dict) and raw_prices:
                prices = [
                    MensaPrice(
                        price_tag=self._price_tiers.get(str(tier_id), str(tier_id)),
                        price=str(price_str).replace(",", "."),
                    )
                    for tier_id, price_str in raw_prices.items()
                ]

        # Only meal-level notices go here — component notices stay on their components.
        general_notices = sorted(meal_notices, key=lambda n: n.notice)
        self._meal_details[meal_id] = MensaMealDetail(
            id=meal_id,
            meal_name=name,
            description=counter_desc,
            color=color,
            general_notices=general_notices,
            prices=prices,
            pricing_notice=pricing_notice,
            meal_components=rich_components,
        )

        return MensaMeal(
            id=meal_id,
            meal_name=name,
            counter_name=counter_name,
            opening_hours=opening_hours,
            color=color,
            components=components,
            notices=sorted(all_notices),
            prices=prices,
            pricing_notice=pricing_notice,
        )

    def get_meal_details(self) -> dict[int, MensaMealDetail]:
        return dict(self._meal_details)

    def build_filters(self) -> MensaFilters:
        notices = [
            MensaFilterNotice(
                notice_id=n_id,
                name=(
                    str(info.get("displayName") or n_id)
                    if isinstance(info, dict)
                    else str(n_id)
                ),
                is_allergen=(
                    bool(info.get("isAllergen", False))
                    if isinstance(info, dict)
                    else False
                ),
                is_negated=(
                    bool(info.get("isNegated", False))
                    if isinstance(info, dict)
                    else False
                ),
            )
            for n_id, info in self._notices.items()
        ]
        locations = [
            MensaFilterLocation(
                location_id=campus.value,
                name=CAMPUS_CITY_NAMES[campus],
            )
            for campus in MENSA_CAMPUS_LOCATIONS
        ]
        return MensaFilters(locations=locations, notices=notices)

    async def fetch_menu(
        self,
        location: MensaLocation,
        lang: Language = Language.DE,
    ) -> MensaMenu:
        await self._fetch_base_data(lang)
        self._meal_details = {}

        api_key = settings.mensa_api_key.get_secret_value()
        if not api_key:
            raise ScraperError("MENSA_API_KEY is not set in .secrets")
        url = MENSA_MENU_URL.format(api_key=api_key, lang=lang, location=location)
        raw = await self.fetch(url)
        data: dict[str, object] = json.loads(raw)

        days: list[MensaDay] = []

        raw_days = data.get("days", [])
        if not isinstance(raw_days, list):
            raw_days = []

        for day_data in raw_days:
            if not isinstance(day_data, dict):
                continue
            date_str = str(day_data.get("date", ""))
            try:
                day_dt = datetime.fromisoformat(date_str).astimezone(UTC)
                day_date = day_dt.date()
                formatted_date = format_mensa_date(day_date, lang)
            except ValueError:
                logger.warning(
                    "mensa:{}:{} — unparseable date {!r}, falling back to today",
                    location,
                    lang,
                    date_str,
                )
                day_date = date.today()
                formatted_date = format_mensa_date(day_date, lang)

            meals: list[MensaMeal] = []
            counters = day_data.get("counters", [])
            if not isinstance(counters, list):
                counters = []

            for counter_idx, counter in enumerate(counters):
                if not isinstance(counter, dict):
                    continue
                counter_name = self._clean(str(counter.get("displayName", "")))
                counter_desc = self._clean(str(counter.get("description", "")))
                opening_hours = self._parse_opening_hours(counter.get("openingHours"))
                color_raw = counter.get("color")
                if isinstance(color_raw, dict):
                    color = MensaColor(
                        r=int(color_raw.get("r", 0)),
                        g=int(color_raw.get("g", 0)),
                        b=int(color_raw.get("b", 0)),
                    )
                else:
                    color = MensaColor()

                raw_meals = counter.get("meals", [])
                if not isinstance(raw_meals, list):
                    raw_meals = []
                for meal_idx, meal_data in enumerate(raw_meals):
                    if not isinstance(meal_data, dict):
                        continue
                    meal = self._parse_meal(
                        meal_data,
                        counter_name,
                        counter_desc,
                        opening_hours,
                        color,
                        location,
                        day_date,
                        counter_idx,
                        meal_idx,
                    )
                    if meal is not None:
                        meals.append(meal)

            days.append(MensaDay(date=formatted_date, meals=meals))

        filters_ts = datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
        return MensaMenu(days=days, filters_last_changed=filters_ts)
