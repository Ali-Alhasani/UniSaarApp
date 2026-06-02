import pytest
from pydantic import ValidationError

from src.models.more import MoreLink, MoreLinksResponse


class TestMoreLink:
    def test_valid(self) -> None:
        link = MoreLink(name="AStA", link="https://asta.uni-saarland.de/en/")
        assert link.name == "AStA"
        assert link.link == "https://asta.uni-saarland.de/en/"

    def test_missing_link_raises(self) -> None:
        with pytest.raises(ValidationError):
            MoreLink(name="AStA")  # type: ignore[call-arg]


class TestMoreLinksResponse:
    def test_valid_response(self) -> None:
        resp = MoreLinksResponse(
            links_last_changed="2020-01-20 17:42:14",
            language="de",
            links=[
                MoreLink(
                    name="Welcome Centre",
                    link="https://www.uni-saarland.de/en/global/welcome-center.html",
                ),
                MoreLink(name="AStA", link="https://asta.uni-saarland.de/en/"),
            ],
        )
        assert resp.language == "de"
        assert len(resp.links) == 2

    def test_empty_links(self) -> None:
        resp = MoreLinksResponse(
            links_last_changed="2020-01-20 17:42:14",
            language="en",
            links=[],
        )
        assert resp.links == []

    def test_missing_language_raises(self) -> None:
        with pytest.raises(ValidationError):
            MoreLinksResponse(links_last_changed="2020-01-20", links=[])  # type: ignore[call-arg]
