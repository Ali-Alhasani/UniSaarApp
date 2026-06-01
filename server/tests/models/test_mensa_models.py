import pytest
from pydantic import ValidationError

from src.models.mensa import (
    MensaColor,
    MensaComponent,
    MensaDay,
    MensaInfo,
    MensaMeal,
    MensaMealDetail,
    MensaMenu,
    MensaNotice,
    MensaPrice,
)


def make_meal(**overrides: object) -> MensaMeal:
    defaults: dict[str, object] = {
        "id": 42,
        "meal_name": "Spaghetti Bolognese",
        "counter_name": "Komplettmenü",
        "opening_hours": "11:30 - 14:00",
        "color": MensaColor(r=255, g=200, b=0),
        "components": ["Spaghetti", "Bolognese-Sauce"],
        "notices": ["G", "L"],
        "prices": [MensaPrice(price_tag="Studierende", price="2.50")],
    }
    defaults.update(overrides)
    return MensaMeal(**defaults)


class TestMensaColor:
    def test_default_zero(self) -> None:
        color = MensaColor()
        assert color.r == 0 and color.g == 0 and color.b == 0

    def test_from_empty_dict(self) -> None:
        color = MensaColor(**{})
        assert color.r == 0


class TestMensaPrice:
    def test_price_is_string(self) -> None:
        price = MensaPrice(price_tag="Gast", price="4.80")
        assert isinstance(price.price, str)
        assert price.price == "4.80"

    def test_missing_price_raises(self) -> None:
        with pytest.raises(ValidationError):
            MensaPrice(price_tag="Gast")  # type: ignore[call-arg]


class TestMensaMeal:
    def test_valid_meal(self) -> None:
        meal = make_meal()
        assert meal.id == 42
        assert meal.pricing_notice is None

    def test_pricing_notice_mutually_exclusive(self) -> None:
        meal = make_meal(prices=None, pricing_notice="Preis auf Anfrage")
        assert meal.prices is None
        assert meal.pricing_notice == "Preis auf Anfrage"

    def test_default_color_on_empty(self) -> None:
        meal = make_meal(color=MensaColor())
        assert meal.color.r == 0

    def test_notices_list(self) -> None:
        meal = make_meal(notices=["G", "L", "V"])
        assert "V" in meal.notices


class TestMensaMenu:
    def test_valid_menu(self) -> None:
        day = MensaDay(date="Montag 01.06.", meals=[make_meal()])
        menu = MensaMenu(days=[day], filters_last_changed="2024-01-01")
        assert len(menu.days) == 1
        assert menu.days[0].meals[0].meal_name == "Spaghetti Bolognese"


class TestMensaMealDetail:
    def test_valid_detail(self) -> None:
        notice = MensaNotice(notice="G", display_name="Gluten")
        component = MensaComponent(
            component_name="Sauce",
            notices=[MensaNotice(notice="L", display_name="Laktose")],
        )
        detail = MensaMealDetail(
            meal_name="Spaghetti",
            description="Pasta counter",
            color=MensaColor(r=255, g=0, b=0),
            general_notices=[notice],
            prices=[MensaPrice(price_tag="Stud.", price="2.50")],
            meal_components=[component],
        )
        assert detail.meal_name == "Spaghetti"
        assert detail.general_notices[0].notice == "G"


class TestMensaInfo:
    def test_valid_info(self) -> None:
        info = MensaInfo(
            name="Mensa Saarbrücken",
            description="Hauptmensa",
            image_link="https://example.com/mensa.jpg",
        )
        assert info.name == "Mensa Saarbrücken"
