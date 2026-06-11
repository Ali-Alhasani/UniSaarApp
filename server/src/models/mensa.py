from __future__ import annotations

from typing import Annotated

from pydantic import BaseModel, ConfigDict, Field, PlainSerializer

# int stored internally; serialized as string in JSON for iOS SwiftyJSON compatibility.
IntAsStr = Annotated[int, PlainSerializer(str, return_type=str, when_used="json")]


class MensaColor(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    r: int = 0
    g: int = 0
    b: int = 0


class MensaPrice(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    price_tag: str = Field(alias="priceTag")
    price: str


class MensaNotice(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    notice: str
    display_name: str = Field(alias="displayName")


class MensaComponent(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    component_name: str = Field(alias="componentName")
    notices: list[MensaNotice]


class MensaMeal(BaseModel):
    """Meal summary as returned on the main screen."""

    model_config = ConfigDict(populate_by_name=True)

    id: IntAsStr
    meal_name: str = Field(alias="mealName")
    counter_name: str = Field(alias="counterName")
    opening_hours: str = Field(alias="openingHours")
    color: MensaColor = Field(default_factory=MensaColor)
    components: list[str]
    notices: list[str]
    prices: list[MensaPrice] | None = None
    pricing_notice: str | None = Field(default=None, alias="pricingNotice")


class MensaDay(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    date: str
    meals: list[MensaMeal]


class MensaMenu(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    days: list[MensaDay]
    filters_last_changed: str = Field(alias="filtersLastChanged")


class MensaMealDetail(BaseModel):
    """Full meal detail as returned by the meal detail endpoint."""

    model_config = ConfigDict(populate_by_name=True)

    id: IntAsStr
    meal_name: str = Field(alias="mealName")
    description: str
    color: MensaColor = Field(default_factory=MensaColor)
    general_notices: list[MensaNotice] = Field(alias="generalNotices")
    prices: list[MensaPrice] | None = None
    pricing_notice: str | None = Field(default=None, alias="pricingNotice")
    meal_components: list[MensaComponent] = Field(alias="mealComponents")


class MensaInfo(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    name: str
    description: str
    image_link: str = Field(alias="imageLink")


class MensaFilterLocation(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    location_id: str = Field(alias="locationID")
    name: str


class MensaFilterNotice(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    notice_id: str = Field(alias="noticeID")
    name: str
    is_allergen: bool = Field(alias="isAllergen")
    is_negated: bool = Field(alias="isNegated")


class MensaFilters(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    locations: list[MensaFilterLocation]
    notices: list[MensaFilterNotice]
