from __future__ import annotations

import json
from datetime import UTC, datetime

from src.core.config import settings
from src.core.constants import MENSA_BASE_URL, MENSA_MENU_URL
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

    async def _fetch_base_data(self, lang: str) -> None:
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
        meal_id: int,
    ) -> MensaMeal:
        raw_notices = meal_data.get("notices", [])
        all_notices: set[str] = set(
            raw_notices if isinstance(raw_notices, list) else []
        )

        components: list[str] = []
        rich_components: list[MensaComponent] = []
        raw_components = meal_data.get("components", [])
        if isinstance(raw_components, list):
            for comp in raw_components:
                if not isinstance(comp, dict):
                    continue
                comp_name = str(comp.get("name", "")).replace("\xa0", " ").strip()
                comp_notice_ids = comp.get("notices", [])
                if isinstance(comp_notice_ids, list):
                    all_notices.update(str(n) for n in comp_notice_ids)
                    comp_notices = [self._notice_obj(str(n)) for n in comp_notice_ids]
                else:
                    comp_notices = []
                if comp_name:
                    components.append(comp_name)
                    rich_components.append(
                        MensaComponent(
                            component_name=comp_name,
                            notices=comp_notices,
                        )
                    )

        name = str(meal_data.get("name", "")).replace("\xa0", " ").strip()
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

        general_notices = [self._notice_obj(n_id) for n_id in sorted(all_notices)]
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
        return MensaFilters(locations=self._filter_locations, notices=notices)

    async def fetch_menu(self, location: str, lang: str = "de") -> MensaMenu:
        await self._fetch_base_data(lang)
        self._meal_details = {}

        api_key = settings.mensa_api_key.get_secret_value()
        if not api_key:
            raise ScraperError("MENSA_API_KEY is not set in .secrets")
        url = MENSA_MENU_URL.format(api_key=api_key, lang=lang, location=location)
        raw = await self.fetch(url)
        data: dict[str, object] = json.loads(raw)

        meal_id = 0
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
                formatted_date = format_mensa_date(day_dt.date(), lang)
            except ValueError:
                formatted_date = date_str

            meals: list[MensaMeal] = []
            counters = day_data.get("counters", [])
            if not isinstance(counters, list):
                counters = []

            for counter in counters:
                if not isinstance(counter, dict):
                    continue
                counter_name = (
                    str(counter.get("displayName", "")).replace("\xa0", " ").strip()
                )
                counter_desc = (
                    str(counter.get("description", "")).replace("\xa0", " ").strip()
                )
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
                for meal_data in raw_meals:
                    if not isinstance(meal_data, dict):
                        continue
                    meals.append(
                        self._parse_meal(
                            meal_data,
                            counter_name,
                            counter_desc,
                            opening_hours,
                            color,
                            meal_id,
                        )
                    )
                    meal_id += 1

            days.append(MensaDay(date=formatted_date, meals=meals))

        filters_ts = datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
        return MensaMenu(days=days, filters_last_changed=filters_ts)
