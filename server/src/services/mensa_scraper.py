from __future__ import annotations

import json
from datetime import UTC, datetime

from src.core.config import settings
from src.core.constants import MENSA_BASE_URL, MENSA_MENU_URL
from src.models.mensa import MensaColor, MensaDay, MensaMeal, MensaMenu, MensaPrice
from src.services.base_scraper import BaseScraper
from src.services.date_service import format_mensa_date


class MensaScraper(BaseScraper):
    def __init__(self) -> None:
        super().__init__()
        self._price_tiers: dict[str, str] = {}  # tierID → displayName

    async def _fetch_base_data(self, lang: str) -> None:
        api_key = settings.mensa_api_key.get_secret_value()
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
        opening_hours: str,
        color: MensaColor,
        meal_id: int,
    ) -> MensaMeal:
        raw_notices = meal_data.get("notices", [])
        all_notices: set[str] = set(
            raw_notices if isinstance(raw_notices, list) else []
        )

        components: list[str] = []
        raw_components = meal_data.get("components", [])
        if isinstance(raw_components, list):
            for comp in raw_components:
                if not isinstance(comp, dict):
                    continue
                comp_name = str(comp.get("name", "")).replace("\xa0", " ").strip()
                if comp_name:
                    components.append(comp_name)
                comp_notices = comp.get("notices", [])
                if isinstance(comp_notices, list):
                    all_notices.update(str(n) for n in comp_notices)

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

    async def fetch_menu(self, location: str, lang: str = "de") -> MensaMenu:
        await self._fetch_base_data(lang)

        api_key = settings.mensa_api_key.get_secret_value()
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
                            meal_data, counter_name, opening_hours, color, meal_id
                        )
                    )
                    meal_id += 1

            days.append(MensaDay(date=formatted_date, meals=meals))

        filters_ts = datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
        return MensaMenu(days=days, filters_last_changed=filters_ts)
