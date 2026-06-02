"""Contract tests — assert serialized keys match iOS Codable field names."""

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


def make_meal() -> MensaMeal:
    return MensaMeal(
        id=42,
        meal_name="Spaghetti",
        counter_name="Komplettmenü",
        opening_hours="11:30 - 14:00",
        color=MensaColor(r=255, g=200, b=0),
        components=["Spaghetti", "Sauce"],
        notices=["G"],
        prices=[MensaPrice(price_tag="Studierende", price="2.50")],
    )


class TestMensaColorContract:
    def test_keys(self) -> None:
        data = MensaColor(r=255, g=128, b=0).model_dump(by_alias=True)
        assert set(data.keys()) == {"r", "g", "b"}


class TestMensaPriceContract:
    def test_ios_keys(self) -> None:
        data = MensaPrice(price_tag="Gast", price="4.80").model_dump(by_alias=True)
        assert "priceTag" in data
        assert "price" in data
        assert "price_tag" not in data

    def test_price_is_string(self) -> None:
        data = MensaPrice(price_tag="Stud.", price="2.50").model_dump(by_alias=True)
        assert isinstance(data["price"], str)


class TestMensaNoticeContract:
    def test_ios_keys(self) -> None:
        data = MensaNotice(notice="G", display_name="Gluten").model_dump(by_alias=True)
        assert "notice" in data
        assert "displayName" in data
        assert "display_name" not in data


class TestMensaComponentContract:
    def test_ios_keys(self) -> None:
        comp = MensaComponent(
            component_name="Sauce",
            notices=[MensaNotice(notice="L", display_name="Laktose")],
        )
        data = comp.model_dump(by_alias=True)
        assert "componentName" in data
        assert "notices" in data
        assert "component_name" not in data


class TestMensaMealContract:
    def test_ios_field_names(self) -> None:
        data = make_meal().model_dump(by_alias=True)
        assert "id" in data
        assert "mealName" in data
        assert "counterName" in data
        assert "openingHours" in data
        assert "color" in data
        assert "components" in data
        assert "notices" in data
        assert "prices" in data

    def test_no_snake_case_keys(self) -> None:
        data = make_meal().model_dump(by_alias=True)
        assert "meal_name" not in data
        assert "counter_name" not in data
        assert "opening_hours" not in data
        assert "pricing_notice" not in data

    def test_pricing_notice_key_name(self) -> None:
        meal = MensaMeal(
            id=1,
            meal_name="Pizza",
            counter_name="Free Flow",
            opening_hours="",
            color=MensaColor(),
            components=[],
            notices=[],
            prices=None,
            pricing_notice="Preis auf Anfrage",
        )
        data = meal.model_dump(by_alias=True)
        assert "pricingNotice" in data
        assert "pricing_notice" not in data


class TestMensaMenuContract:
    def test_ios_keys(self) -> None:
        day = MensaDay(date="Montag 01.06.", meals=[make_meal()])
        menu = MensaMenu(days=[day], filters_last_changed="2024-01-01")
        data = menu.model_dump(by_alias=True)
        assert "days" in data
        assert "filtersLastChanged" in data
        assert "filters_last_changed" not in data


class TestMensaMealDetailContract:
    def test_ios_keys(self) -> None:
        detail = MensaMealDetail(
            id=42,
            meal_name="Spaghetti",
            description="Pasta counter",
            color=MensaColor(r=0, g=0, b=0),
            general_notices=[MensaNotice(notice="G", display_name="Gluten")],
            prices=[MensaPrice(price_tag="Stud.", price="2.50")],
            meal_components=[],
        )
        data = detail.model_dump(by_alias=True)
        assert "id" in data
        assert "mealName" in data
        assert "description" in data
        assert "color" in data
        assert "generalNotices" in data
        assert "prices" in data
        assert "mealComponents" in data
        assert "meal_name" not in data
        assert "general_notices" not in data
        assert "meal_components" not in data


class TestMensaInfoContract:
    def test_ios_keys(self) -> None:
        data = MensaInfo(
            name="Mensa SB",
            description="Hauptmensa",
            image_link="https://example.com/img.jpg",
        ).model_dump(by_alias=True)
        assert "name" in data
        assert "description" in data
        assert "imageLink" in data
        assert "image_link" not in data
