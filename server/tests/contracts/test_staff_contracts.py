"""Contract tests — assert serialized keys match iOS Codable field names."""

from src.models.staff import StaffDetails, StaffFunction, StaffItem, StaffList


def make_staff_details() -> StaffDetails:
    return StaffDetails(
        first_name="Hans",
        last_name="Müller",
        title="Prof. Dr.",
        gender="männlich",
        office_hour="Mo 10-12",
        remark="",
        office="E1.1 123",
        building="E1.1",
        street="Campus",
        postal_code="66123",
        city="Saarbrücken",
        phone="+49 681 302-0000",
        fax="",
        mail="mueller@uni-saarland.de",
        webpage="https://example.com",
        image_link=None,
        functions=[],
    )


class TestStaffItemContract:
    def test_ios_keys(self) -> None:
        item = StaffItem(name="Müller, Hans", title="Prof. Dr.", pid=12345)
        data = item.model_dump(by_alias=True)
        assert "name" in data
        assert "title" in data
        assert "pid" in data

    def test_no_extra_keys(self) -> None:
        item = StaffItem(name="Müller, Hans", title="Prof. Dr.", pid=12345)
        data = item.model_dump(by_alias=True)
        assert set(data.keys()) == {"name", "title", "pid"}


class TestStaffListContract:
    def test_ios_keys(self) -> None:
        data = StaffList(
            item_count=1,
            has_next_page=False,
            results=[StaffItem(name="A", title="Dr.", pid=1)],
        ).model_dump(by_alias=True)
        assert "itemCount" in data
        assert "hasNextPage" in data
        assert "results" in data
        assert "item_count" not in data
        assert "has_next_page" not in data


class TestStaffDetailsContract:
    def test_ios_field_names_present(self) -> None:
        data = make_staff_details().model_dump(by_alias=True)
        assert "firstname" in data
        assert "lastname" in data
        assert "title" in data
        assert "gender" in data
        assert "officeHour" in data
        assert "remark" in data
        assert "office" in data
        assert "building" in data
        assert "street" in data
        assert "postalCode" in data
        assert "city" in data
        assert "phone" in data
        assert "fax" in data
        assert "mail" in data
        assert "webpage" in data
        assert "imageLink" in data
        assert "functions" in data

    def test_no_snake_case_keys(self) -> None:
        data = make_staff_details().model_dump(by_alias=True)
        assert "first_name" not in data
        assert "last_name" not in data
        assert "office_hour" not in data
        assert "postal_code" not in data
        assert "image_link" not in data

    def test_image_link_none(self) -> None:
        data = make_staff_details().model_dump(by_alias=True)
        assert data["imageLink"] is None


class TestStaffFunctionContract:
    def test_ios_keys(self) -> None:
        func = StaffFunction(
            f_department="Informatik",
            f_function="Professur",
            f_office="E1.1 1.23",
        )
        data = func.model_dump(by_alias=True)
        assert "fDepartment" in data
        assert "fFunction" in data
        assert "fOffice" in data
        assert "f_department" not in data
        assert "f_function" not in data
        assert "f_office" not in data
