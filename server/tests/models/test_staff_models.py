import pytest
from pydantic import ValidationError

from src.models.staff import StaffDetails, StaffFunction, StaffItem, StaffList


def make_staff_item(**overrides: object) -> StaffItem:
    defaults: dict[str, object] = {
        "name": "Müller, Hans",
        "title": "Prof. Dr.",
        "pid": 12345,
    }
    defaults.update(overrides)
    return StaffItem(**defaults)


def make_staff_details(**overrides: object) -> StaffDetails:
    defaults: dict[str, object] = {
        "first_name": "Hans",
        "last_name": "Müller",
        "title": "Prof. Dr.",
        "gender": "männlich",
        "office_hour": "Mo 10-12",
        "remark": "",
        "office": "E1.1 123",
        "building": "E1.1",
        "street": "Campus",
        "postal_code": "66123",
        "city": "Saarbrücken",
        "phone": "+49 681 302-0000",
        "fax": "",
        "mail": "mueller@uni-saarland.de",
        "webpage": "https://example.com",
        "image_link": None,
        "functions": [],
    }
    defaults.update(overrides)
    return StaffDetails(**defaults)


class TestStaffItem:
    def test_valid(self) -> None:
        item = make_staff_item()
        assert item.pid == 12345
        assert item.title == "Prof. Dr."

    def test_missing_pid_raises(self) -> None:
        with pytest.raises(ValidationError):
            StaffItem(name="Müller, Hans", title="Prof. Dr.")  # type: ignore[call-arg]


class TestStaffList:
    def test_valid_list(self) -> None:
        staff_list = StaffList(
            item_count=2,
            has_next_page=False,
            results=[
                make_staff_item(),
                make_staff_item(pid=99999, name="Schmidt, Anna"),
            ],
        )
        assert len(staff_list.results) == 2
        assert staff_list.has_next_page is False

    def test_empty_results(self) -> None:
        staff_list = StaffList(item_count=0, has_next_page=False, results=[])
        assert staff_list.results == []


class TestStaffDetails:
    def test_valid_details(self) -> None:
        details = make_staff_details()
        assert details.first_name == "Hans"
        assert details.image_link is None

    def test_image_link_optional(self) -> None:
        details = make_staff_details(image_link="https://example.com/photo.jpg")
        assert details.image_link == "https://example.com/photo.jpg"

    def test_functions_default_empty(self) -> None:
        details = make_staff_details(functions=[])
        assert details.functions == []

    def test_with_functions(self) -> None:
        func = StaffFunction(
            f_department="Informatik",
            f_function="Professur",
            f_office="E1.1 1.23",
        )
        details = make_staff_details(functions=[func])
        assert details.functions[0].f_department == "Informatik"

    def test_missing_required_field_raises(self) -> None:
        with pytest.raises(ValidationError):
            StaffDetails(  # type: ignore[call-arg]
                first_name="Hans",
                last_name="Müller",
            )
