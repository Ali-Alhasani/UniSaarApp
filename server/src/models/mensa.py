from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field


class MensaColor(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    r: int = 0
    g: int = 0
    b: int = 0


class MensaPrice(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    price_tag: str = Field(serialization_alias="priceTag")
    price: str


class MensaNotice(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    notice: str
    display_name: str = Field(serialization_alias="displayName")


class MensaComponent(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    component_name: str = Field(serialization_alias="componentName")
    notices: list[MensaNotice]


class MensaMeal(BaseModel):
    """Meal summary as returned on the main screen."""

    model_config = ConfigDict(populate_by_name=True)

    id: int
    meal_name: str = Field(serialization_alias="mealName")
    counter_name: str = Field(serialization_alias="counterName")
    opening_hours: str = Field(serialization_alias="openingHours")
    color: MensaColor = Field(default_factory=MensaColor)
    components: list[str]
    notices: list[str]
    prices: list[MensaPrice] | None = None
    pricing_notice: str | None = Field(
        default=None, serialization_alias="pricingNotice"
    )


class MensaDay(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    date: str
    meals: list[MensaMeal]


class MensaMenu(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    days: list[MensaDay]
    filters_last_changed: str = Field(serialization_alias="filtersLastChanged")


class MensaMealDetail(BaseModel):
    """Full meal detail as returned by the meal detail endpoint."""

    model_config = ConfigDict(populate_by_name=True)

    meal_name: str = Field(serialization_alias="mealName")
    description: str
    color: MensaColor = Field(default_factory=MensaColor)
    general_notices: list[MensaNotice] = Field(serialization_alias="generalNotices")
    prices: list[MensaPrice] | None = None
    pricing_notice: str | None = Field(
        default=None, serialization_alias="pricingNotice"
    )
    meal_components: list[MensaComponent] = Field(serialization_alias="mealComponents")


class MensaInfo(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    name: str
    description: str
    image_link: str = Field(serialization_alias="imageLink")
