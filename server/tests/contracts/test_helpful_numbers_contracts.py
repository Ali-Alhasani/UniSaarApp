"""Contract tests — assert serialized keys match iOS Codable field names."""

from src.models.helpful_numbers import HelpfulNumber, HelpfulNumbersResponse


class TestHelpfulNumberContract:
    def test_ios_keys(self) -> None:
        data = HelpfulNumber(
            name="AStA",
            number="+49 681 302 2900",
            link="https://asta.uni-saarland.de/",
            mail="asta@uni-saarland.de",
        ).model_dump(by_alias=True)
        assert "name" in data
        assert "number" in data
        assert "link" in data
        assert "mail" in data

    def test_no_extra_keys(self) -> None:
        data = HelpfulNumber(name="AStA", number="123").model_dump(by_alias=True)
        assert set(data.keys()) == {"name", "number", "link", "mail"}


class TestHelpfulNumbersResponseContract:
    def test_ios_keys(self) -> None:
        resp = HelpfulNumbersResponse(
            numbers_last_changed="2024-01-15 10:00:00",
            numbers=[HelpfulNumber(name="AStA", number="123")],
        )
        data = resp.model_dump(by_alias=True)
        assert "numbersLastChanged" in data
        assert "numbers" in data
        assert "numbers_last_changed" not in data

    def test_numbers_is_list(self) -> None:
        resp = HelpfulNumbersResponse(numbers=[HelpfulNumber(name="A", number="1")])
        data = resp.model_dump(by_alias=True)
        assert isinstance(data["numbers"], list)
        assert data["numbers"][0]["name"] == "A"
