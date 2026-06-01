import pytest
from pydantic import ValidationError

from src.models.helpful_numbers import HelpfulNumber, HelpfulNumbersResponse


class TestHelpfulNumber:
    def test_all_fields(self) -> None:
        hn = HelpfulNumber(
            name="AStA",
            number="+49 681 302 2900",
            link="https://asta.uni-saarland.de/",
            mail="asta@uni-saarland.de",
        )
        assert hn.name == "AStA"
        assert hn.link is not None

    def test_link_and_mail_optional(self) -> None:
        hn = HelpfulNumber(name="Bibliothek", number="+49 681 302 3076")
        assert hn.link is None
        assert hn.mail is None

    def test_missing_name_raises(self) -> None:
        with pytest.raises(ValidationError):
            HelpfulNumber(number="123")  # type: ignore[call-arg]


class TestHelpfulNumbersResponse:
    def test_valid_response(self) -> None:
        resp = HelpfulNumbersResponse(
            numbers_last_changed="2024-01-15 10:00:00",
            numbers=[
                HelpfulNumber(name="AStA", number="+49 681 302 2900"),
                HelpfulNumber(
                    name="Sekretariat",
                    number="0681 302-5491",
                    link="https://www.uni-saarland.de",
                ),
            ],
        )
        assert len(resp.numbers) == 2

    def test_numbers_last_changed_optional(self) -> None:
        resp = HelpfulNumbersResponse(numbers=[])
        assert resp.numbers_last_changed is None

    def test_empty_numbers(self) -> None:
        resp = HelpfulNumbersResponse(numbers=[])
        assert resp.numbers == []
