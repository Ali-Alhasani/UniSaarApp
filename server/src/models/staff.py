from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field


class StaffItem(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    name: str
    title: str
    pid: int


class StaffList(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    item_count: int = Field(alias="itemCount")
    has_next_page: bool = Field(alias="hasNextPage")
    results: list[StaffItem]


class StaffFunction(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    f_department: str | None = Field(default=None, alias="fDepartment")
    f_function: str | None = Field(default=None, alias="fFunction")
    f_start: str | None = Field(default=None, alias="fStart")
    f_end: str | None = Field(default=None, alias="fEnd")
    f_office: str | None = Field(default=None, alias="fOffice")
    f_building: str | None = Field(default=None, alias="fBuilding")
    f_street: str | None = Field(default=None, alias="fStreet")
    f_postal_code: str | None = Field(default=None, alias="fPostalCode")
    f_city: str | None = Field(default=None, alias="fCity")
    f_phone: str | None = Field(default=None, alias="fPhone")
    f_fax: str | None = Field(default=None, alias="fFax")
    f_mail: str | None = Field(default=None, alias="fMail")
    f_webpage: str | None = Field(default=None, alias="fWebpage")


class StaffDetails(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    first_name: str = Field(alias="firstname")
    last_name: str = Field(alias="lastname")
    title: str
    gender: str
    office_hour: str = Field(alias="officeHour")
    remark: str
    office: str
    building: str
    street: str
    postal_code: str = Field(alias="postalCode")
    city: str
    phone: str
    fax: str
    mail: str
    webpage: str
    image_link: str | None = Field(default=None, alias="imageLink")
    functions: list[StaffFunction] = Field(default_factory=list)
